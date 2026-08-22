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
# OPENOS 构建体系 — 公共函数库 (日志/错误/幂等标记/阶段包装)
# 借鉴 Chromium OS cros_sdk/Portage: 每组件按 ebuild 阶段执行并打标记, 幂等可重入。

set -euo pipefail

# 色彩 (仅 TTY)
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'; C_BLU=$'\033[34m'; C_RST=$'\033[0m'
else
  C_RED=''; C_GRN=''; C_YLW=''; C_BLU=''; C_RST=''
fi

log()  { printf '%s[%s]%s %s\n' "$C_BLU" "$(date +%H:%M:%S)" "$C_RST" "$*"; }
info() { printf '%s[INFO]%s %s\n'  "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[WARN]%s %s\n'  "$C_YLW" "$C_RST" "$*" >&2; }
die()  { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RST" "$*" >&2; exit 1; }

# ---------- 幂等标记 (类似 Portage 的 instdone / ChromiumOS build stages) ----------
# 标记目录: <out>/stamps/<arch>/<name>
STAMP_DIR="$OUT_DIR/stamps/$OPENOS_ARCH"
mkdir -p "$STAMP_DIR"

stamp_exists() { [ -f "$STAMP_DIR/$1.ok" ]; }
stamp_set()    { : > "$STAMP_DIR/$1.ok"; }
stamp_clear()  { rm -f "$STAMP_DIR/$1.ok"; }

# 阶段包装器: 已打标记则跳过; 失败清除标记 (下次重跑)
# 用法: stage <name> <描述> <命令...>
stage() {
  local name="$1" desc="$2"; shift 2
  if stamp_exists "$name"; then
    info "跳过 [${OPENOS_ARCH}] ${desc} (已构建)"
    return 0
  fi
  log "构建 [${OPENOS_ARCH}] ${desc} ..."
  if ! "$@"; then
    stamp_clear "$name"
    die "[${OPENOS_ARCH}] ${desc} 失败"
  fi
  stamp_set "$name"
  info "[${OPENOS_ARCH}] ${desc} 完成"
}

# 交叉编译环境 (借鉴 Portage 的 sysroot 设置)
setup_toolchain_env() {
  export TARGET="${OPENOS_TRIPLET[$OPENOS_ARCH]}"
  export SYSROOT="$OUT_DIR/sysroots/$OPENOS_ARCH"
  mkdir -p "$SYSROOT"

  if is_native "$OPENOS_ARCH"; then
    export CC="${CC:-gcc}"
    export CXX="${CXX:-g++}"
    export CROSS_COMPILE=""
  else
    local cross="${OPENOS_CROSS[$OPENOS_ARCH]}"
    export CC="${cross}gcc"
    export CXX="${cross}g++"
    export CROSS_COMPILE="$cross"
  fi

  # ccache 接入 (CI 必须; 二次构建分钟级)
  if [ "${OPENOS_CCACHE:-0}" = "1" ] && command -v ccache >/dev/null 2>&1; then
    export CCACHE_DIR="$BUILD_ROOT/.cache/ccache"
    mkdir -p "$CCACHE_DIR"
    if command -v "${CC#*ccache }" >/dev/null 2>&1 || [ -z "${CC:-}" ]; then
      export CC="ccache $CC"
      export CXX="ccache $CXX"
    fi
  fi

  export CFLAGS="${CFLAGS:--O2 -g0 -pipe}"
  export CXXFLAGS="$CFLAGS"
  # 交叉时强制使用 sysroot
  if [ -n "${CROSS_COMPILE:-}" ]; then
    export CFLAGS="$CFLAGS --sysroot=$SYSROOT"
    export CXXFLAGS="$CXXFLAGS --sysroot=$SYSROOT"
    export LDFLAGS="${LDFLAGS:---sysroot=$SYSROOT}"
  else
    export LDFLAGS="${LDFLAGS:-}"
  fi
  export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/pkgconfig"
  export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
  export JOBS="${JOBS:-$OPENOS_JOBS}"
}
