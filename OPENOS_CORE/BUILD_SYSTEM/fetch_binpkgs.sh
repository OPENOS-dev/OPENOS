#!/usr/bin/env bash
# OPENOS 构建体系 — 从共享 binpkg 仓库拉取各组件最新构建产物
# 主系统不再本地构建组件, 而是获取各子模块 CI 已构建好的 .pkg.tar.zst
#
# 用法: fetch_binpkgs.sh --arch=<...> [--kernel=<base>]
#   - 组件 binpkg 解压进 $OUT_DIR/sysroots/<arch>/
#   - 内核 binpkg 解压进 $OUT_DIR/kernels/<arch>/<kname>/
#
# binpkg 仓库: https://github.com/OPENOS-dev/OPENOS-BUILD-BINPKG
#   目录: bins/<组件>/<架构>/<组件>-<架构>-DEV2026.1.pkg.tar.zst
# 每次执行都重新克隆拉取 (不做幂等缓存), 保证拿到子模块最新产物。

set -euo pipefail
# common.sh 的 STAMP_DIR 需要 OPENOS_ARCH 有值
OPENOS_ARCH="${OPENOS_ARCH:-local}"
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

BINPKG_URL="https://github.com/OPENOS-dev/OPENOS-BUILD-BINPKG.git"
BINPKG_DIR="$OUT_DIR/binpkg-fetch"

# 全部基础组件 (kernel 特殊处理; gcc/systemd 暂为预留空包仍拉取)
COMPONENTS="kernel glibc bash coreutils util-linux pacman systemd gcc apt \
  liboak libopenrsa libvmapp oakctl openos-oak-seal openos-uname \
  openos-securityd openos-settingsd openos-settings openos-calendar \
  openos-welcome openos-run openos-oak opt OPENUI-desktop linux"

main() {
  local arch="" kname="${OPENOS_KERNEL_DEFAULT}"
  for a in "$@"; do
    case "$a" in
      --arch=*) arch="${a#*=}" ;;
      --kernel=*) kname="${a#*=}" ;;
      *) die "未知参数: $a" ;;
    esac
  done
  [ -n "$arch" ] || die "用法: fetch_binpkgs.sh --arch=<...>"

  log "克隆 binpkg 仓库 ..."
  rm -rf "$BINPKG_DIR"
  git clone --depth 1 -q "$BINPKG_URL" "$BINPKG_DIR" || die "克隆 binpkg 仓库失败"

  local sysroot="$OUT_DIR/sysroots/$arch"
  mkdir -p "$sysroot"
  local missing="" c pkg kdir
  for c in $COMPONENTS; do
    pkg="$BINPKG_DIR/bins/$c/$arch/$c-$arch-DEV2026.1.pkg.tar.zst"
    if [ ! -f "$pkg" ]; then
      warn "[fetch] 跳过缺失: $c ($arch)"
      missing="$missing $c"
      continue
    fi
    if [ "$c" = "kernel" ]; then
      kdir="$OUT_DIR/kernels/$arch/$kname"
      mkdir -p "$kdir"
      tar --zstd -xf "$pkg" -C "$kdir"
    else
      tar --zstd -xf "$pkg" -C "$sysroot"
    fi
    info "[fetch] 已拉取: $c ($arch)"
  done

  if [ -n "$missing" ]; then
    warn "[fetch] 以下组件 binpkg 缺失 (子模块 CI 可能尚未产出):$missing"
  fi
  info "[fetch] 完成: $arch / kernel=$kname"
}

main "$@"
