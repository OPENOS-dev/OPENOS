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
# OPENOS 构建体系 — setup_board (Board 初始化)
# 借鉴 Chromium OS `setup_board --board=...`: 为每个架构建立
#   1) sysroot 目录骨架  2) 内核 UAPI 头 (交叉编译 glibc 需要)  3) 工具链探测
#
# 用法: setup_board.sh --arch=<x86-64|x86|arm64|arm32> [--kernel=<base>]
#   或: setup_board.sh --all (4 架构全部初始化)

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

setup_one() {
  local arch="$1" kname="$2"
  OPENOS_ARCH="$arch"
  STAMP_DIR="$OUT_DIR/stamps/$OPENOS_ARCH"
  mkdir -p "$STAMP_DIR"

  local sysroot="$OUT_DIR/sysroots/$arch"
  local kdir="$KERNEL_DIR/${OPENOS_KERNEL[$kname]}"
  local karch="${OPENOS_KBUILD_ARCH[$arch]}"

  stage "sysroot" "初始化 sysroot ($arch)" bash -c "
    set -euo pipefail
    for d in usr/lib usr/include usr/bin usr/sbin etc bin sbin lib lib64; do
      mkdir -p '$sysroot'/\$d
    done
  "

  # 安装内核 UAPI 头到 sysroot (glibc 交叉构建前置)
  if [ ! -d "$sysroot/usr/include/linux" ] || [ ! -f "$sysroot/usr/include/linux/version.h" ]; then
    stage "uapi-headers" "内核 UAPI 头 ($kname/$arch)" bash -c "
      set -euo pipefail
      cd '$kdir'
      make ARCH='$karch' INSTALL_HDR_PATH='$sysroot/usr' headers_install >/dev/null
    "
  else
    info "[$arch] UAPI 头已存在, 跳过"
  fi

  # 工具链探测
  info "[$arch] TARGET=${OPENOS_TRIPLET[$arch]} CC=$CC"
}

main() {
  local arch="" kname="${OPENOS_KERNEL_DEFAULT}"
  for a in "$@"; do
    case "$a" in
      --arch=*) arch="${a#*=}" ;;
      --kernel=*) kname="${a#*=}" ;;
      --all) arch="all" ;;
      *) die "未知参数: $a" ;;
    esac
  done

  if [ "$arch" = "all" ]; then
    for a in x86-64 x86 arm64 arm32 loong64; do setup_one "$a" "$kname"; done
  elif [ -n "$arch" ]; then
    setup_one "$arch" "$kname"
  else
    die "用法: setup_board.sh --arch=<...> | --all"
  fi
  info "Board 初始化完成 (kernel=$kname)"
}

main "$@"
