# OPENOS PROJECT 长期记忆

## 项目定位（2026-08-15）
- 以 Arch 核心组件打包树为"重建"基础，产出一套**非 Arch 兼容、全新定义的 OS** OPENOS。不 `pacman -S` 官方仓库，用 PKGBUILD/makepkg 配方重建并自定义 ABI/发行版标识/init。
- 目录结构：`OPENOS_CORE/{src,BUILD_SYSTEM,DOCS,LICENSES}`。组件在 `src/<pkg>/`，内核在 `src/kernel/`。
- 所有上游 `.git` 已移出项目（防误推官方仓库）。

## 内核版本分层（2026-08-16）
| 分层 | 版本 | 定位 |
|---|---|---|
| 基础版 | `6.12.103`（LTS）+ `7.1.8` | 默认构建/主力 |
| 预发布 | `7.2-rc7` | 当年新特性 |
| 经典版 | `5.15.215` | 老设备 |

- 内核 `EXTRAVERSION` 改为 `-openos2026.1.0+DEV`（7.2-rc7 为 `-rc7-openos2026.1.0+DEV`）→ uname -r 如 `6.12.103-openos2026.1.0+DEV`。
- 版本号 `DEV2026.1`；OS 名 OPENOS。

## 系统级决策
- **架构**：多架构 arm32/arm64/x86/x86-64 + **LoongArch64**（统一 triplet，如 `aarch64-openos-linux-gnu`）。
- **init**：systemd（沿用）；**包管理**：改 pacman（apt 3.1.12 内置进 opt，本地 cmake 构建不下载）；**ABI**：glibc 2.43 开发线（commit 16be151849）。

## 桌面（wlroots 合成器 + Qt 外壳）
- 合成器 `openos-compositor`（wlroots 0.17）保留；外壳 Qt 6/Qt Quick(QML)，旧 cairo 客户端为死代码保留。仅 Linux 可编译（macOS 无法验证）。
- 已实现：多工作区（4 树 + Ctrl+1..4/Ctrl+Tab）、动态模糊（`blur.{c,h}` 两阶段管线）、通知层（`notifyd.c` + FIFO）。
- 任务栏：`wlr-foreign-toplevel-management`（标准协议）；工作区切换：**自研** `openos-workspace-unstable-v1.xml`（wlroots 无 workspace 协议）。
- **OPENUI**：GUI 框架（MD3 扩展 NUI2），令牌在 `desktop/src/openui.h` + `OpenUI.qml`（圆角 8/12/16/24px、玻璃 0.72-0.78、语义色 primary #00BCD4）。**交互功能都是独立 app**，每个 `src/openos-*` 可单独 meson 构建（settings/oak/opt/vmapp/calendar/run/welcome + securityd/settingsd + liboak/libvmapp/libopenrsa + oakctl/oak-seal/uname）。
- 注意：wlroots 仓库在 GitLab；`wlr_scene_render_output` 不存在、`scene_buffer.texture` 私有。

## 安全（OPENOS Security 内核模块，四内核 md5 一致）
- 命名：模块叫 **OPENOS Security**（`CONFIG_SECURITY_OPENOS`，LSM `openos_security`）；**OAK 是加密方法**（`oak_` 前缀/`/proc/oak/`/`.oak` 密钥文件）。
- 源码 `security/openos/`：`oak_lsm.c`（LSM/子安全主体/授权提权/防kill）、`oak_early.c`（OAK-Seal 启动校验，偏移 0x1000）、`oak_rsa.c`（OPEN RSA 握手）、`vmapp.c`（轻量隔离 /dev/vmapp ioctl）、`oak_devicekey.c`（每设备首启自生成 RSA-2048，公钥 /proc/oak/device-key）。
- 强制启用三层：Kconfig `def_bool y` + LSM order（5.15=FIRST/6.12+=LAST）+ 构建脚本校验 System.map。
- 跨版本坑：`security_add_hooks` 第三参（5.15=char*/6.12+=lsm_id）、`cap_last_cap()` 不存在用 `CAP_LAST_CAP`、`bdev_file_open_by_path`（6.x）、kern_path_create 四参一致但 vfs_mkdir 签名差异（nop_mnt_idmap 条件编译）。
- 用户态配套：`src/openos-securityd`、`src/liboak`、`src/oakctl`（.oak 密钥管理）、`src/openos-oak-seal`。

## 构建体系（借鉴 Chromium OS / Soong 风格，OPENOS 自命名）
- `BUILD_SYSTEM/`：`config.sh`（4+1 架构矩阵/内核分层/组件集）、`common.sh`（stage 幂等 stamps）、`setup_board.sh`、`build_component.sh`、`build_image.sh`、`cache.sh`、`OPENOS.bp`（Blueprint 27 模块）、`openos-build`（Python 驱动）。
- 模型：board→sysroot→ebuild 阶段→binpkg→build_image；CI `.github/workflows/build.yml` 5 架构矩阵、ccache/binpkg 缓存、JOBS=3、timeout 330。
- 脚本未经本机验证（用户拒跑 chmod/bash -n），需 Linux/CI 验证。

## 项目约定
- 路径：全部放项目内；脚本用 `BASH_SOURCE` 取目录；PKGBUILD source 用 `./PKGBUILD`。
- **SCRIPT/ 已废除**：要么是 app（`src/`）要么是内核功能（内核里）。
- 用户拒绝删除遗留文件（死代码保留不编译）。
- 文档在 `DOCS/`；自研代码 GPL-2.0-only，LICENSES 归档上游许可。

## 大项目子模块化（2026-08-16）
- 大组件逐个 `git init` + 子模块 + 对应远程，**必须提交**。
- 规则：**只提交解压目录，不提交 tarball**（kernel 子模块 `.gitignore` 排除 `*.tar*`）。解压树需无 >100M 单文件（GitHub 限制）才可直接提交。
- 状态：kernel 已提交（`src/kernel` → `OPENOS-kernel.git`，commit 2219c1e，343469 文件，主仓库 gitlink `160000` + `.gitmodules`）；gcc/glibc/apt 等其余大组件待同样处理。
- 主仓库远程：`https://github.com/OPENOS-dev/OPENOS.git`（README 用 B 方案，本地实现）。
