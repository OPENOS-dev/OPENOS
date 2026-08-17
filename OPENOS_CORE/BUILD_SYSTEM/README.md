# OPENOS 构建体系 (BUILD_SYSTEM)

## 组件构建分散化（2026-08-17）

每个组件都是独立 git 子模块仓库，**各子模块自带 GitHub Actions** 构建自身
组件并产出 `.pkg.tar.zst`（binpkg），推送到共享仓库
[`OPENOS-BUILD-BINPKG`](https://github.com/OPENOS-dev/OPENOS-BUILD-BINPKG)。

主系统构建镜像时**不再本地构建组件**，而是通过 `fetch_binpkgs.sh` 从共享仓库
拉取各组件最新 binpkg 组装（见下）。

```bash
# 子模块 CI (各 src/<组件>/.github/workflows/build.yml):
#   push -> 5 架构矩阵构建 -> bins/<组件>/<架构>/<组件>-<架构>-DEV2026.1.pkg.tar.zst
#   （推送到 OPENOS-BUILD-BINPKG 需仓库 secret: OPENOS_BINPKG_TOKEN, PAT 具 repo 权限）

# 主系统 CI (.github/workflows/build.yml):
#   ./fetch_binpkgs.sh --arch=x86-64 --kernel=base   # 拉取所有组件 binpkg
#   ./build_image.sh   --arch=x86-64 --kernel=base   # 组装 rootfs 镜像
```

底层构建模型仍借鉴 **Chromium OS (Portage/ebuild)**：
board（架构）→ sysroot → 阶段化组件构建 → binpkg → 镜像组装。

构建体系本身采用 **Soong/Blueprint 风格**（OPENOS 自命名）：
- `OPENOS.bp` — 全部组件声明为模块（kernel/cc/app/service/tool/lib）
- `openos-build` — Python 构建驱动（解析模块 → 依赖排序 → 分派构建 → 增量 stamp）

## 快速开始 (Soong 统一入口)

```bash
cd OPENOS_CORE/BUILD_SYSTEM
./soong --list                  # 列出全部模块 (27 个)
./soong --module=openos-settings   # 构建单个 app
./soong --build-all --arch=x86-64 --kernel=base   # 全量构建
```

## 概念对照

| Google Soong | Chromium OS | OPENOS 实现 |
|---|---|---|
| `Android.bp` 模块 | ebuild | `Android.bp`（27 模块）|
| `soong_ui` | cros_sdk | `soong`（Python 驱动）|
| cc_library/kernel_build | board/阶段 | `kernel_module`/`cc_component`/`app_module` 等 |
| blueprint 依赖图 | ebuild DEPEND | `deps` 拓扑排序 |
| ninja 增量 | binpkg | stamp 增量 + ccache |

## 底层脚本 (Chromium OS 模型)

```bash
./setup_board.sh --arch=x86-64 --kernel=base       # 初始化 board
./build_component.sh --arch=x86-64 --pkg=bash      # 构建单组件
./build_component.sh --all --set=minimal           # 全部架构 minimal 集合
./build_image.sh --arch=x86-64 --kernel=base       # 组装镜像
```

## 概念对照 (Chromium OS → OPENOS)

| Chromium OS | OPENOS 实现 |
|---|---|
| `setup_board --board=` | `setup_board.sh --arch=` |
| ebuild 阶段 (unpack/prepare/configure/compile/install) | `build_component.sh` 内 `stage()` 幂等阶段 |
| sysroot `/build/<board>` | `out/sysroots/<arch>/` |
| binhost / binpkg (`.tbz2`) | `out/binpkgs/<arch>/*.pkg.tar.zst` |
| `build_image` | `build_image.sh` (rootfs 镜像) |
| cros_sdk chroot | GitHub Actions 容器 (ubuntu) |
| USE flags / Profile | `minimal`/`full` 组件集合 + 内核分层 |

## 快速开始 (本地)

```bash
cd OPENOS_CORE/BUILD_SYSTEM
./setup_board.sh --arch=x86-64 --kernel=base       # 初始化 board
./build_component.sh --arch=x86-64 --pkg=bash      # 构建单组件
./build_component.sh --all --set=minimal           # 全部架构 minimal 集合
./build_image.sh --arch=x86-64 --kernel=base       # 组装镜像
```

产物: `out/images/*.tar.zst` (rootfs 镜像) / `out/kernels/` / `out/binpkgs/`。

## 架构矩阵

| arch | GNU triplet | 内核 Kbuild ARCH | 交叉编译器 |
|---|---|---|---|
| x86-64 | x86_64-openos-linux-gnu | x86_64 | 原生 |
| x86 | i686-openos-linux-gnu | i386 | gcc-multilib |
| arm64 | aarch64-openos-linux-gnu | arm64 | gcc-aarch64-linux-gnu |
| arm32 | armv7h-openos-linux-gnueabihf | arm | gcc-arm-linux-gnueabihf |
| loong64 | loongarch64-openos-linux-gnu | loongarch | gcc-loongarch64-linux-gnu |

## 内核分层

`config.sh` 的 `OPENOS_KERNEL` 定义（`--kernel=` 选择）：
- `classic` → linux-5.15.215 (经典版/老设备)
- `base`    → linux-6.12.103 (基础版/LTS, 默认)
- `base7`   → linux-7.1.8 (基础版 7.1)
- `preview` → linux-7.2-rc7 (当年预发布)

## GitHub Actions 不超时策略

1. **矩阵并行**：4 架构独立 job（`strategy.matrix.arch`），总时长 = 最慢 job。
2. **ccache**：编译缓存跨 run 复用，内核二次构建分钟级。
3. **binpkg + sysroot + stamps 缓存**：`cache.sh save/restore` + `actions/cache`
   （单 tar 文件, key 含 sha, 前缀回退）。
4. **默认 minimal**：`kernel+glibc+bash+coreutils`；`full`（含 gcc/systemd/pacman/
   util-linux）由 `workflow_dispatch` 手动触发。
5. **JOBS=3**：4vCPU runner 防 OOM 防 timeout；`timeout-minutes: 330`（< GH 6h 上限）。
6. **阶段幂等**：每阶段 stamp 标记，缓存命中即跳过。

## 手动触发完整构建

GitHub 页面 → Actions → OPENOS Build → Run workflow → 选 `kernel` 分层与 `set=full`。

## 已知限制 / 迭代方向

- `systemd` (meson) 与 `gcc` (阶段2) 目前为**框架预留**（`stage 恒真`），
  接入 meson cross file / 自建工具链即启用。
- 桌面外壳为 **Qt 6 (Qt Quick)**：CI 用 apt 装 `qt6-base-dev qt6-declarative-dev
  qt6-wayland-dev`；源码构建 qtbase 可归入 full 集合另行编排。
- glibc 交叉构建假定内核 UAPI 头已由 `setup_board.sh` 装入 sysroot。
- 内核配置用 `defconfig` 基线（后续可接入各 arch 的 OPENOS 定制 config）。
- macOS 无法直接运行（无交叉编译器/内核头/Qt wayland），请在 Linux 或 CI 上使用。
