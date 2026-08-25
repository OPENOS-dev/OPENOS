#!/usr/bin/env bash
# Copyright (C) 2026 OPENOS-dev
# OPENOS 构建体系 -- 从宿主机 pacman 安装 KDE Plasma 到 sysroot
#
# 用法: install_kde.sh --arch=<...> [--sysroot=<path>]
#   OPENUI-desktop 暂时关停, 桌面改用 KDE Plasma。
#   在 GitHub Actions 上通过 pacman 从 Arch Linux 仓库
#   直接安装 KDE 到 sysroot, 自动解析依赖。
#
#   注意: 仅在 x86-64 原生构建时可用 (Arch 包仅 x86-64)。
#         交叉编译架构 (arm64/arm32/loong64) 暂不支持 KDE。

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 必须在 source common.sh 前设置 OPENOS_ARCH (common.sh 依赖该变量)
OPENOS_ARCH=""
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

# KDE Plasma 包 (plasma-meta 拉完整桌面, sddm 为显示管理器)
KDE_PKGS="plasma-meta sddm sddm-kcm konsole dolphin kate \
  plasma-nm plasma-pa powerdevil systemsettings \
  breeze breeze-gtk kde-gtk-config"

# OPENOS 自行构建的包，告诉 pacman 不要覆盖
OPENOS_BASE="glibc gcc-libs bash coreutils util-linux systemd systemd-libs \
  pacman gcc"

PACMAN_CACHE=""

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

  if [ "$arch" != "x86-64" ]; then
    warn "[kde] 跳过 KDE 安装: $arch 不是原生 x86-64 (Arch 包仅 x86-64)"
    warn "[kde] 该架构将不包含桌面环境, 仅含命令行系统"
    return 0
  fi

  log "[kde] 用 pacman 安装 KDE Plasma 桌面到 sysroot ..."

  PACMAN_CACHE="$OUT_DIR/pacman-cache"
  mkdir -p "$PACMAN_CACHE" "$sysroot"/var/lib/pacman "$sysroot"/etc

  # 1. 安装并初始化 pacman
  setup_pacman

  # 2. 安装 KDE Plasma 包
  install_kde_packages

  # 3. 配置系统
  configure_system

  info "[kde] KDE Plasma 安装完成: $arch"
}

setup_pacman() {
  log "[kde] 安装 pacman 到宿主机 ..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq pacman archlinux-keyring 2>/dev/null || true

  # 如果 apt 没有 pacman, 尝试从 pacman-static 安装
  if ! command -v pacman &>/dev/null; then
    log "[kde] apt 无 pacman, 下载 pacman-static ..."
    curl -fsSL -o /tmp/pacman-static \
      "https://github.com/andrewgregory/pacman-static/releases/latest/download/pacman-static-x86_64.tar.gz" 2>/dev/null || true
    if [ -f /tmp/pacman-static ]; then
      tar xzf /tmp/pacman-static -C /usr/local/bin/ pacman-static 2>/dev/null || true
    fi
  fi

  # 初始化 pacman keyring
  log "[kde] 初始化 pacman keyring ..."
  sudo mkdir -p /etc/pacman.d
  sudo pacman-key --init 2>/dev/null || true
  sudo pacman-key --populate archlinux 2>/dev/null || true

  # 配置镜像源
  cat << 'MIRRORS' | sudo tee /etc/pacman.d/mirrorlist
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
MIRRORS

  # 配置 pacman.conf (允许非 root 操作, 跳过签名检查加速 CI)
  cat << 'PACCONF' | sudo tee /etc/pacman.conf
[options]
HoldPkg     = pacman glibc
Architecture = auto
SigLevel    = Never
LocalFileSigLevel = Optional
ParallelDownloads = 5

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
PACCONF

  sudo mkdir -p /var/lib/pacman
  sudo pacman -Sy --noconfirm 2>/dev/null || true
  info "[kde] pacman 初始化完成"
}

install_kde_packages() {
  log "[kde] 安装 KDE Plasma 包到 sysroot ..."

  # 构建 --assume-installed 参数, 防止 pacman 覆盖 OPENOS 基包
  local assume=""
  for pkg in $OPENOS_BASE; do
    assume="$assume --assume-installed=$pkg"
  done

  # 用 pacman 安装到 sysroot (自动处理依赖树)
  sudo pacman --root="$sysroot" \
    --cachedir="$PACMAN_CACHE" \
    --dbpath="$sysroot/var/lib/pacman" \
    $assume \
    -Syu --noconfirm --needed $KDE_PKGS 2>&1 | tail -20 || {
    warn "[kde] pacman 安装部分包失败, 尝试逐个安装 ..."
    for pkg in $KDE_PKGS; do
      sudo pacman --root="$sysroot" \
        --cachedir="$PACMAN_CACHE" \
        --dbpath="$sysroot/var/lib/pacman" \
        $assume \
        -S --noconfirm --needed "$pkg" 2>/dev/null || warn "[kde] 跳过: $pkg"
    done
  }

  info "[kde] KDE 包安装完成"
}

configure_system() {
  log "[kde] 配置系统 ..."

  # SDDM 自启动
  mkdir -p "$sysroot/etc/systemd/system/multi-user.target.wants"
  if [ -f "$sysroot/usr/lib/systemd/system/sddm.service" ]; then
    ln -sf /usr/lib/systemd/system/sddm.service \
      "$sysroot/etc/systemd/system/display-manager.service" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/sddm.service \
      "$sysroot/etc/systemd/system/multi-user.target.wants/sddm.service" 2>/dev/null || true
  fi

  # 默认用户 openos
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

  # SDDM 自动登录
  mkdir -p "$sysroot/etc/sddm.conf.d"
  cat > "$sysroot/etc/sddm.conf.d/autologin.conf" << 'SDDMCFG'
[Autologin]
User=openos
Session=plasma.desktop

[Theme]
Current=breeze
SDDMCFG

  # dbus 自启动
  if [ -f "$sysroot/usr/lib/systemd/system/dbus.service" ]; then
    mkdir -p "$sysroot/etc/systemd/system/sockets.target.wants"
    ln -sf /usr/lib/systemd/system/dbus.service \
      "$sysroot/etc/systemd/system/multi-user.target.wants/dbus.service" 2>/dev/null || true
    ln -sf /usr/lib/systemd/system/dbus.socket \
      "$sysroot/etc/systemd/system/sockets.target.wants/dbus.socket" 2>/dev/null || true
  fi

  info "[kde] 系统配置完成"
}

main "$@"