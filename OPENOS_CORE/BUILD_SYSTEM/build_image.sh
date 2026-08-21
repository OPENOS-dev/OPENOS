#!/usr/bin/env bash
# OPENOS 构建体系 — 镜像组装 (借鉴 Chromium OS build_image)
# 将 sysroot 组件产物组装为可启动的 rootfs 镜像 (tar 格式), 可按架构/内核分层出多套。
#
# 用法: build_image.sh --arch=<...> [--kernel=<base>] [--out=<name>]
#   rootfs 布局:  /usr /bin /lib /etc /boot
#   产出: $OUT_DIR/images/<arch>-<kname>-<name>.tar.zst

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# common.sh 的 STAMP_DIR 需要 OPENOS_ARCH 有值
OPENOS_ARCH="${OPENOS_ARCH:-}"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

main() {
  local arch="" kname="${OPENOS_KERNEL_DEFAULT}" imgname="rootfs"
  for a in "$@"; do
    case "$a" in
      --arch=*) arch="${a#*=}" ; OPENOS_ARCH="$arch" ;;
      --kernel=*) kname="${a#*=}" ;;
      --out=*) imgname="${a#*=}" ;;
      *) die "未知参数: $a" ;;
    esac
  done
  [ -n "$arch" ] || die "用法: build_image.sh --arch=<...>"

  local sysroot="$OUT_DIR/sysroots/$arch"
  local kout="$OUT_DIR/kernels/$arch/$kname"
  local img_dir="$OUT_DIR/images"
  local stage_dir="$OUT_DIR/image-stage/$arch"
  mkdir -p "$img_dir" "$stage_dir"

  stage "image-rootfs" "组装 rootfs ($arch)" bash -c "
    set -euo pipefail
    rm -rf '$stage_dir' && mkdir -p '$stage_dir'
    cp -a '$sysroot/.' '$stage_dir/'
    mkdir -p '$stage_dir'/boot '$stage_dir'/etc '$stage_dir'/dev '$stage_dir'/proc '$stage_dir'/sys
    # 内核 (优先 binpkg 解压布局 boot/, 兼容本地构建布局 arch/*/boot/ 与 bzImage)
    cp -f '$kout'/boot/* '$stage_dir'/boot/ 2>/dev/null || \
    cp -f '$kout'/arch/*/boot/* '$stage_dir'/boot/ 2>/dev/null || \
    cp -f '$kout'/bzImage '$stage_dir'/boot/ 2>/dev/null || true
    # 最小 /etc
    printf 'root::0:0:root:/root:/bin/bash\n' > '$stage_dir'/etc/passwd
    printf 'root:x:0:\n' > '$stage_dir'/etc/group
    printf 'none /proc proc defaults 0 0\nnone /sys sysfs defaults 0 0\n' > '$stage_dir'/etc/fstab
  "

  stage "image-tar" "打包镜像 ($arch-$kname)" bash -c "
    set -euo pipefail
    (cd '$stage_dir' && tar --zstd -cf '$img_dir/$arch-$kname-$imgname.tar.zst' .)
  "
  info "镜像: $img_dir/$arch-$kname-$imgname.tar.zst"
}

main "$@"
