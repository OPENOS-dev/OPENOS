#!/usr/bin/env bash
# Copyright (C) 2026 OPENOS-dev
# This program is free software: you can redistribute it and/or modify
# it under the terms of the OPENOS-PROJECT-LICENSE (OPL) v1.2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# OPL for more details.
#
# You should have received a copy of the OPL along with this program.
# If not, see <https://github.com/OPENOS-dev/OPL>.
#
# OPENOS 构建体系 — 组件构建器 (核心)
# 借鉴 Chromium OS Portage/ebuild 的阶段模型:
#   unpack -> prepare(打补丁) -> configure -> compile -> install
# 每个阶段幂等 (stamp 标记), 失败清标记可重跑。
#
# 用法:
#   build_component.sh --arch=<...> --pkg=<kernel|glibc|bash|coreutils|util-linux|pacman|systemd|gcc> [--kernel=<base>]
#   build_component.sh --all --set=minimal   # CI 默认: kernel+glibc+bash+coreutils
#
# 产物:
#   内核 -> $OUT_DIR/kernels/<arch>/<kname>/
#   其余 -> 安装进 $OUT_DIR/sysroots/<arch>/   (rootfs 素材)
#   binpkg -> $OUT_DIR/binpkgs/<arch>/*.pkg.tar.zst  (Portage binhost 式缓存)

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

MINIMAL_SET="kernel glibc bash coreutils"
FULL_SET="kernel glibc bash coreutils util-linux pacman systemd gcc"

# ---------- 源码准备 (unpack + prepare) ----------
# 从包目录 src/ 取源码: 若为 tarball 则解压; 若为源码树则复制(或直接用, 勿污染上游)
unpack_src() {
  local pkg="$1" dest="$2"
  local src_base="$SRC_DIR/$pkg/src"
  [ -d "$src_base" ] || die "[$pkg] 缺少源码目录: $src_base"
  mkdir -p "$dest"
  local any=0
  local f
  for f in "$src_base"/*; do
    [ -e "$f" ] || continue
    case "$f" in
      *.tar.gz|*.tar.xz|*.tar.bz2|*.tgz)
        tar -xf "$f" -C "$dest" || die "[$pkg] 解压失败: $f"
        any=1 ;;
      *.patch)
        : ;;   # 补丁由 prepare 阶段单独应用
      *)
        # 目录源码树: 软链接 (避免复制数 GB 的 gcc/glibc)
        ln -sfn "$f" "$dest/$(basename "$f")"
        any=1 ;;
    esac
  done
  [ "$any" -eq 1 ] || die "[$pkg] src/ 无可用源码"
}

# ---------- 组件: 内核 ----------
build_kernel() {
  local arch="$1" kname="$2"
  local kdir="$KERNEL_DIR/${OPENOS_KERNEL[$kname]}"
  local karch="${OPENOS_KBUILD_ARCH[$arch]}"
  local cross="${OPENOS_CROSS[$arch]}"
  local out="$OUT_DIR/kernels/$arch/$kname"
  [ -d "$kdir" ] || die "内核源码缺失: $kdir"

  stage "kernel-src" "准备内核源码 ($kname)" bash -c "mkdir -p '$out'"

  stage "kernel-config" "内核配置 ($kname/$arch)" bash -c "
    set -euo pipefail
    cd '$kdir'
    make O='$out' ARCH='$karch' $([ -n "$cross" ] && echo CROSS_COMPILE='$cross') defconfig >/dev/null
    # 强制 OPENOS Security: def_bool y 已保证, 此处显式确认 + 确保 SECURITY 开启
    scripts/config --file '$out/.config' -e SECURITY -e SECURITY_OPENOS
    old=\$(grep '^CONFIG_SECURITY_OPENOS=' '$out/.config')
    [ \"\$old\" = 'CONFIG_SECURITY_OPENOS=y' ] || die 'OPENOS Security 强制启用失败: CONFIG_SECURITY_OPENOS != y'
  "

  stage "kernel-build" "内核编译 ($kname/$arch)" bash -c "
    set -euo pipefail
    cd '$kdir'
    make O='$out' ARCH='$karch' $([ -n "$cross" ] && echo CROSS_COMPILE='$cross') -j'$JOBS' \\
      ${KERNEL_EXTRA_ARGS:-} all >/dev/null
    # OPENOS Security 编译后校验: System.map 必须含模块与启动校验符号 (缺失即构建失败)
    if [ -f '$out/System.map' ] && ! grep -q 'oak_task_kill\|openos_oak_early_init\|__lsm_oak' '$out/System.map'; then
      die '[OPENOS Security] System.map 未找到 oak/启动校验符号 —— 模块未编入内核!'
    fi
  "

  stage "kernel-modules" "内核模块 ($kname/$arch)" bash -c "
    set -euo pipefail
    cd '$kdir'
    make O='$out' ARCH='$karch' $([ -n "$cross" ] && echo CROSS_COMPILE='$cross') \\
      INSTALL_MOD_PATH='$out/modules' modules_install >/dev/null
  "

  # binpkg 打包 (Portage binhost 式)
  stage "kernel-binpkg" "内核 binpkg" bash -c "
    set -euo pipefail
    mkdir -p '$OUT_DIR/binpkgs/$arch'
    (cd '$out' && tar --zstd -cf '$OUT_DIR/binpkgs/$arch/kernel-$kname-$arch.pkg.tar.zst' .)
  "
}

# ---------- 组件: glibc ----------
build_glibc() {
  local arch="$1"
  local work="$OUT_DIR/work/$arch/glibc"
  setup_toolchain_env

  stage "glibc-unpack" "glibc 源码" bash -c "
    set -euo pipefail
    rm -rf '$work'
    mkdir -p '$work'
    unpack() { :; }
    # 复用 unpack_src (通过子 shell 加载本脚本函数不可行, 此处直接复制源码树)
    cp -a '$SRC_DIR/glibc/src/.' '$work/src/'
  " 2>/dev/null || {
    # 上面内联失败时回退: 直接以源码树为构建目录
    info "glibc: 直接使用源码树 (不复制)"
  }
  local gsrc="$work/src"
  [ -d "$gsrc" ] || gsrc="$SRC_DIR/glibc/src"

  stage "glibc-configure" "glibc 配置 ($arch)" bash -c "
    set -euo pipefail
    mkdir -p '$work/build'
    cd '$work/build'
    '$gsrc/configure' \\
      --host='$TARGET' --build='\$(cc -dumpmachine 2>/dev/null || echo \$TARGET)' \\
      --prefix=/usr --with-headers='$SYSROOT/usr/include' \\
      --disable-werror --disable-profile --without-selinux \\
      --enable-kernel=4.15 >/dev/null
  "

  stage "glibc-build" "glibc 编译 ($arch)" bash -c "
    set -euo pipefail
    cd '$work/build'
    make -j'$JOBS' >/dev/null
  "

  stage "glibc-install" "glibc 安装 ($arch)" bash -c "
    set -euo pipefail
    cd '$work/build'
    make install_root='$SYSROOT' install >/dev/null
    mkdir -p '$OUT_DIR/binpkgs/$arch'
    (cd '$SYSROOT' && tar --zstd -cf '$OUT_DIR/binpkgs/$arch/glibc-$arch.pkg.tar.zst' usr/lib usr/include usr/bin)
  "
}

# ---------- 组件: 标准 autotools 项目 (bash/coreutils/util-linux/pacman) ----------
build_autotools() {
  local pkg="$1" arch="$2" extra_conf="$3"
  local work="$OUT_DIR/work/$arch/$pkg"
  setup_toolchain_env

  stage "$pkg-unpack" "$pkg 源码" bash -c "
    set -euo pipefail
    rm -rf '$work'
    mkdir -p '$work'
    # 解压 (此处直接内联 tar 处理; bash/coreutils 是 tarball, util-linux/pacman 是源码树)
    for f in '$SRC_DIR/$pkg/src/'*; do
      case \"\$f\" in
        *.tar.gz|*.tar.xz|*.tar.bz2|*.tgz)
          tar -xf \"\$f\" -C '$work' ;;
        *)
          [ -d \"\$f\" ] && cp -a \"\$f\" '$work'/ || true ;;
      esac
    done
  "

  stage "$pkg-patch" "$pkg 补丁" bash -c "
    set -euo pipefail
    # 应用 src/ 下 .patch (bash 15 个补丁等); 需先 cd 到解压后的根目录
    local d='$work'/bash-* '$work'/*/
    local root
    for root in $work/*/; do
      [ -d \"\$root\" ] || continue
      ( cd \"\$root\" || exit 0
        for p in '$SRC_DIR/$pkg/src/'*.patch; do
          [ -e \"\$p\" ] && patch -p1 < \"\$p\" || true
        done )
      break
    done
  " 2>/dev/null || true

  stage "$pkg-configure" "$pkg 配置 ($arch)" bash -c "
    set -euo pipefail
    local root
    root=\$(find '$work' -maxdepth 2 -name configure -printf '%h\n' | head -n1)
    [ -n \"\$root\" ] || die '[ $pkg ] 未找到 configure'
    mkdir -p '\$root/build'
    cd '\$root/build'
    ../configure --host='$TARGET' --prefix=/usr --build=\$(../config.guess 2>/dev/null || echo $TARGET) $extra_conf >/dev/null
  "

  stage "$pkg-build" "$pkg 编译 ($arch)" bash -c "
    set -euo pipefail
    local root; root=\$(find '$work' -maxdepth 2 -name configure -printf '%h\n' | head -n1)
    cd '\$root/build' && make -j'$JOBS' >/dev/null
  "

  stage "$pkg-install" "$pkg 安装 ($arch)" bash -c "
    set -euo pipefail
    local root; root=\$(find '$work' -maxdepth 2 -name configure -printf '%h\n' | head -n1)
    cd '\$root/build' && make DESTDIR='$SYSROOT' install >/dev/null
    mkdir -p '$OUT_DIR/binpkgs/$arch'
    (cd '$SYSROOT' && tar --zstd -cf '$OUT_DIR/binpkgs/$arch/$pkg-$arch.pkg.tar.zst' usr/bin usr/lib usr/share 2>/dev/null || true)
  "
}

# ---------- 组件: systemd (meson) / gcc (阶段2) ----------
build_meson() {  # systemd
  local pkg="$1" arch="$2"
  local work="$OUT_DIR/work/$arch/$pkg"
  setup_toolchain_env
  info "systemd 需 meson 交叉文件; 当前框架预留, 请接入 meson cross file"
  stage "$pkg" "$pkg (meson 预留)" true
}

build_gcc() {   # 阶段2 工具链重建 (CI 默认跳过, full 手动)
  local arch="$1"
  info "gcc: 阶段2 自建工具链 — 建议 CI 用 apt 交叉编译器; 需要时手动触发"
  stage "gcc" "gcc (阶段2 预留)" true
}

# ---------- 分发 ----------
build_one() {
  local pkg="$1" arch="$2" kname="$3"
  OPENOS_ARCH="$arch"
  STAMP_DIR="$OUT_DIR/stamps/$OPENOS_ARCH"
  mkdir -p "$STAMP_DIR"
  case "$pkg" in
    kernel)    build_kernel "$arch" "$kname" ;;
    glibc)     build_glibc "$arch" ;;
    bash|coreutils) build_autotools "$pkg" "$arch" "--disable-nls" ;;
    util-linux)      build_autotools "$pkg" "$arch" "--disable-nls --disable-pylibmount" ;;
    pacman)          build_autotools "$pkg" "$arch" "--disable-doc" ;;
    systemd)   build_meson "$pkg" "$arch" ;;
    gcc)       build_gcc "$arch" ;;
    *) die "未知组件: $pkg" ;;
  esac
}

main() {
  local arch="" pkg="" kname="${OPENOS_KERNEL_DEFAULT}" set=""
  for a in "$@"; do
    case "$a" in
      --arch=*) arch="${a#*=}" ;;
      --pkg=*)  pkg="${a#*=}" ;;
      --kernel=*) kname="${a#*=}" ;;
      --set=*)  set="${a#*=}" ;;
      --all)    arch="all" ;;
      *) die "未知参数: $a" ;;
    esac
  done

  if [ "$arch" = "all" ]; then
    [ -n "$set" ] || set="minimal"
    local pkgs="$MINIMAL_SET"
    [ "$set" = "full" ] && pkgs="$FULL_SET"
    for a in x86-64 x86 arm64 arm32 loong64; do
      for p in $pkgs; do build_one "$p" "$a" "$kname"; done
    done
    return 0
  fi

  [ -n "$arch" ] && [ -n "$pkg" ] || die "用法: build_component.sh --arch=<...> --pkg=<...> | --all --set=<minimal|full>"
  build_one "$pkg" "$arch" "$kname"
  info "[$arch/$pkg] 完成"
}

main "$@"
