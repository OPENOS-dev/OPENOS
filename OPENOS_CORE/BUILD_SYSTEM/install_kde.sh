#!/usr/bin/env bash
# Copyright (C) 2026 OPENOS-dev
# OPENOS 构建体系 — 从宿主机 apt 安装 KDE Plasma 到 sysroot
#
# 用法: install_kde.sh --arch=<...> [--sysroot=<path>]
#   OPENUI-desktop 暂时关停, 桌面改用 KDE Plasma。
#   从宿主机 apt 下载 .deb 包并解压到 sysroot,
#   避免依赖 OPENUI-desktop 子模块构建。
#
#   注意: 仅在 x86-64 原生构建时可用 (KDE 包来自宿主机架构)。
#         交叉编译架构 (arm64/arm32/loong64) 需另行处理。

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

# KDE Plasma 最小包集合
KDE_PACKAGES="plasma-workspace plasma-desktop sddm kwin-wayland kwin-x11 \
  konsole dolphin kate plasma-nm plasma-pa powerdevil \
  systemsettings kde-config-sddm xdg-desktop-portal-kde \
  breeze kde-style-breeze"

# 额外依赖 (确保完整桌面体验)
KDE_EXTRA="libqt6svg6 qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-org-kde-kirigami2 qml6-module-org-kde-plasma-core \
  qml6-module-org-kde-plasma-components qml6-module-org-kde-plasma-extras"

KDE_DEB_DIR=""

main() {
  local arch="" sysroot=""
  for a in "$@"; do
    case "$a" in
      --arch=*) arch="${a#*=}" ;;
      --sysroot=*) sysroot="${a#*=}" ;;
      *) die "未知参数: $a" ;;
    esac
  done
  [ -n "$arch" ] || die "用法: install_kde.sh --arch=<...>"
  [ -n "$sysroot" ] || sysroot="$OUT_DIR/sysroots/$arch"

  # 仅 x86-64 原生构建支持从 apt 安装 KDE
  if [ "$arch" != "x86-64" ]; then
    warn "[kde] 跳过 KDE 安装: $arch 不是原生 x86-64 (KDE 包来自宿主机 apt)"
    warn "[kde] 该架构将不包含桌面环境, 仅含命令行系统"
    return 0
  fi

  log "[kde] 安装 KDE Plasma 桌面到 sysroot ..."
  KDE_DEB_DIR="$OUT_DIR/kde-debs"
  rm -rf "$KDE_DEB_DIR"
  mkdir -p "$KDE_DEB_DIR" "$sysroot"

  # 1. 下载所有 KDE 包及其依赖
  log "[kde] 下载 KDE Plasma 包 ..."
  cd "$KDE_DEB_DIR"
  for pkg in $KDE_PACKAGES $KDE_EXTRA; do
    apt-get download "$pkg" 2>/dev/null || warn "[kde] 跳过缺失包: $pkg"
  done

  local count
  count=$(ls -1 *.deb 2>/dev/null | wc -l)
  if [ "$count" -eq 0 ]; then
    die "[kde] 未下载到任何 KDE 包"
  fi
  info "[kde] 已下载 $count 个 .deb 包"

  # 2. 解压所有 .deb 到 sysroot
  log "[kde] 解压 KDE 包到 sysroot ..."
  for deb in *.deb; do
    dpkg-deb -x "$deb" "$sysroot" 2>/dev/null || true
  done

  # 3. 配置 SDDM 自动启动
  log "[kde] 配置 SDDM 显示管理器 ..."
  mkdir -p "$sysroot/etc/systemd/system/multi-user.target.wants"
  mkdir -p "$sysroot/etc/systemd/system/display-manager.service.d"

  # 如果 SDDM service 存在则启用
  if [ -f "$sysroot/usr/lib/systemd/system/sddm.service" ]; then
    ln -sf /usr/lib/systemd/system/sddm.service \
      "$sysroot/etc/systemd/system/display-manager.service" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/sddm.service \
      "$sysroot/etc/systemd/system/multi-user.target.wants/sddm.service" 2>/dev/null || true
  fi

  # 4. 创建默认用户 openos
  log "[kde] 创建默认用户 ..."
  if ! grep -q '^openos:' "$sysroot/etc/passwd" 2>/dev/null; then
    echo 'openos:x:1000:1000:OPENOS User:/home/openos:/bin/bash' >> "$sysroot/etc/passwd"
  fi
  if ! grep -q '^openos:' "$sysroot/etc/shadow" 2>/dev/null; then
    echo 'openos::20000:0:99999:7:::' >> "$sysroot/etc/shadow"
  fi
  if ! grep -q '^openos:' "$sysroot/etc/group" 2>/dev/null; then
    echo 'openos:x:1000:' >> "$sysroot/etc/group"
  fi
  mkdir -p "$sysroot/home/openos"

  # 5. SDDM 配置: 自动登录 openos 用户
  mkdir -p "$sysroot/etc/sddm.conf.d"
  cat > "$sysroot/etc/sddm.conf.d/autologin.conf" << 'SDDMCFG'
[Autologin]
User=openos
Session=plasma.desktop

[Theme]
Current=breeze
SDDMCFG

  # 6. 确保 dbus 自启动
  if [ -f "$sysroot/usr/lib/systemd/system/dbus.service" ]; then
    ln -sf /usr/lib/systemd/system/dbus.service \
      "$sysroot/etc/systemd/system/multi-user.target.wants/dbus.service" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/dbus.socket \
      "$sysroot/etc/systemd/system/sockets.target.wants/dbus.socket" 2>/dev/null || true
  fi

  info "[kde] KDE Plasma 安装完成: $arch"
}

main "$@"