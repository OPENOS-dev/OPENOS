#!/usr/bin/env bash
# OPENOS 构建体系 — 全局配置
# 用法: source 本文件获取路径/架构/版本定义。不直接执行。
# 设计目标: 多架构 x 多内核交叉构建, 可在 GitHub Actions 上运行且不超时
#   (通过矩阵并行 + ccache 缓存 + 阶段幂等 + 并行度控制实现)。

set -euo pipefail

# ---------- 路径 ----------
# 本文件所在目录 (BUILD_SYSTEM/)
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# OPENOS_CORE/ (构建输入: src/, LICENSES/)
OPENOS_CORE="$(cd "$BUILD_ROOT/.." && pwd)"
# 源码目录 (每个包: <pkg>/PKGBUILD + <pkg>/src/...)
SRC_DIR="$OPENOS_CORE/src"
# 内核源码目录
KERNEL_DIR="$SRC_DIR/kernel"
# 输出目录 (构建产物, CI 上传 artifact)
OUT_DIR="${OUT_DIR:-$BUILD_ROOT/out}"

# ---------- 架构矩阵 ----------
# arch 名 -> GNU triplet
declare -g -A OPENOS_TRIPLET=(
  [x86-64]="x86_64-openos-linux-gnu"
  [x86]="i686-openos-linux-gnu"
  [arm64]="aarch64-openos-linux-gnu"
  [arm32]="armv7h-openos-linux-gnueabihf"
  [loong64]="loongarch64-openos-linux-gnu"
)
# arch 名 -> 内核 Kbuild ARCH
declare -g -A OPENOS_KBUILD_ARCH=(
  [x86-64]="x86_64"
  [x86]="i386"
  [arm64]="arm64"
  [arm32]="arm"
  [loong64]="loongarch"
)
# arch 名 -> 内核 CROSS_COMPILE 前缀 (空=宿主编译)
declare -g -A OPENOS_CROSS=(
  [x86-64]=""
  [x86]=""
  [arm64]="aarch64-linux-gnu-"
  [arm32]="arm-linux-gnueabihf-"
  [loong64]="loongarch64-linux-gnu-"
)
# 构建期安装的交叉编译器 (CI 用)
declare -g -A OPENOS_CROSS_PKG=(
  [x86-64]=""
  [x86]="gcc-multilib"
  [arm64]="gcc-aarch64-linux-gnu"
  [arm32]="gcc-arm-linux-gnueabihf"
  [loong64]="gcc-loongarch64-linux-gnu"
)

# ---------- 内核分层 (2026-08-16 用户确立) ----------
# 分层名 -> 内核源码目录名 (版本可被 CI 输入覆盖)
declare -g -A OPENOS_KERNEL=(
  [classic]="linux-5.15.215"    # 经典版: 老设备
  [base]="linux-6.12.103"       # 基础版: LTS 稳定基线 (默认)
  [base7]="linux-7.1.8"         # 基础版: 7.1 线
  [preview]="linux-7.2-rc7"     # 当年预发布
)
# 默认分层
OPENOS_KERNEL_DEFAULT="${OPENOS_KERNEL_DEFAULT:-base}"

# ---------- 构建参数 ----------
# 并行度: runner 4 vCPU 时取 3, 避免 OOM; 可被 CI 覆盖
OPENOS_JOBS="${JOBS:-$(( $(nproc 2>/dev/null || echo 4) > 4 ? 3 : 2 ))}"
# 是否启用 ccache (CI 必须; 本地可选)
OPENOS_CCACHE="${CCACHE:-1}"
# 组件集合: minimal=kernel+glibc+bash+coreutils (CI 默认, 保证不超时)
#             full=全部组件 (可手动触发)
# 桌面 Qt 依赖: qtbase/qtwayland 建议 CI 用 apt 安装 (qt6-base-dev 等),
#             源码构建归入 full 时另行编排。
OPENOS_COMPONENTS="${COMPONENTS:-minimal}"
# 目标系统根 (rootfs 组装点)
ROOTFS="$OUT_DIR/rootfs"
# 日志目录
LOG_DIR="$OUT_DIR/logs"
mkdir -p "$OUT_DIR" "$LOG_DIR"

# ---------- 宿主机识别 ----------
HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
  x86_64|amd64) HOST_ARCH="x86-64" ;;
  aarch64|arm64) HOST_ARCH="arm64" ;;
  armv7l|armhf) HOST_ARCH="arm32" ;;
  i686|i386) HOST_ARCH="x86" ;;
esac

# 工具函数
is_native() { [ "$1" = "$HOST_ARCH" ]; }
