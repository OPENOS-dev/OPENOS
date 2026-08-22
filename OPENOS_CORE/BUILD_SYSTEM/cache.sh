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
# OPENOS 构建体系 — 缓存管理 (借鉴 Portage binhost + ccache)
#   save_cache:   打包 ccache + binpkgs + sysroot 增量 为单个 tar (CI 上传 artifact)
#   restore_cache:解包 (CI 下载恢复)
# 用法: cache.sh save --arch=<...> | cache.sh restore --arch=<...>
# CI 中由 workflow 调用, 命中后二次构建分钟级。

set -euo pipefail
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
. "$BUILD_ROOT/config.sh"
# shellcheck source=common.sh
. "$BUILD_ROOT/common.sh"

CACHE_ROOT="${CCACHE_DIR:-$BUILD_ROOT/.cache}"

cache_tar() { printf '%s' "$OUT_DIR/cache-${OPENOS_ARCH:-none}.tar.zst"; }

save() {
  [ -n "${OPENOS_ARCH:-}" ] || OPENOS_ARCH="${1:-}"
  [ -n "$OPENOS_ARCH" ] || die "save: 需要 --arch="
  local t; t="$(cache_tar)"
  mkdir -p "$CACHE_ROOT" "$OUT_DIR"
  info "[$OPENOS_ARCH] 保存缓存: ccache + binpkgs + sysroot"
  tar --zstd -cf "$t" -C "$CACHE_ROOT" ccache 2>/dev/null || true
  tar --zstd -rf "$t" -C "$OUT_DIR" binpkgs sysroots 2>/dev/null || true
  info "[$OPENOS_ARCH] 缓存已保存: $t"
}

restore() {
  [ -n "${OPENOS_ARCH:-}" ] || OPENOS_ARCH="${1:-}"
  [ -n "$OPENOS_ARCH" ] || die "restore: 需要 --arch="
  local t; t="$(cache_tar)"
  if [ ! -f "$t" ]; then
    info "[$OPENOS_ARCH] 无缓存, 全新构建"
    return 0
  fi
  info "[$OPENOS_ARCH] 恢复缓存"
  mkdir -p "$CACHE_ROOT" "$OUT_DIR"
  tar --zstd -xf "$t" -C "$CACHE_ROOT" 2>/dev/null || true
  tar --zstd -xf "$t" -C "$OUT_DIR" 2>/dev/null || true
  info "[$OPENOS_ARCH] 缓存已恢复"
}

case "${1:-}" in
  save)    shift; save "$@" ;;
  restore) shift; restore "$@" ;;
  *) die "用法: cache.sh <save|restore> --arch=<...>" ;;
esac
