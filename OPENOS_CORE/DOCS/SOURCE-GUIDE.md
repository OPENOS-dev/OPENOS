# OPENOS 源码库使用指南

本文档说明如何理解、构建和使用 OPENOS 源码库。

## 1. 项目定位

OPENOS 是**重建式发行版 + 全新 OS** 的混合项目：

- 复用 Arch Linux 的包构建体系（PKGBUILD/makepkg 范式）重建核心组件
- 目标产出一套**非 Arch 兼容、由 OPENOS 定义**的独立操作系统
- 系统组件基于 Arch 锁定的版本基线（glibc 2.43 线 / gcc / systemd / bash / coreutils / pacman / util-linux）

**发行版宪法（关键定义）**

| 项 | 值 |
|---|---|
| OS 名 | OPENOS |
| 版本号 | DEV2026.1 |
| 目标架构 | arm32 / arm64 / x86 / x86-64 |
| 内核 | 四线分层（见 §5） |
| 初始化系统 | systemd |
| 包管理 | opt（前端）+ 内置 apt |
| ABI 基线 | glibc 2.43 开发线 |
| 安全模块 | OPENOS Security（内核，强制启用，内部加密方法 OAK） |

## 2. 目录结构

```
OPENOS_CORE/
├── BUILD_SYSTEM/     # 构建体系 (Google Soong 风格, 声明式)
├── DOCS/             # 文档中心 (本目录)
├── LICENSES/         # 全部组件许可证归档
├── src/              # 全部源码组件 (22 个, 每个可独立构建)
│   ├── kernel/       #   四线内核 + OPENOS Security 模块
│   ├── apt/ bash/ gcc/ glibc/ ...     # 系统组件 (Arch 基线)
│   ├── openos-*/     #   独立 GUI app (settings/oak/opt/vmapp/calendar/run/welcome)
│   ├── openos-securityd/ openos-settingsd/  # 系统服务
│   ├── liboak/ libopenrsa/            # 库
│   └── opt/ oakctl/ openos-oak-seal/  # 工具
```

## 3. 构建

### 3.1 单组件构建（每个组件独立）

```bash
cd src/<组件>
meson setup build
ninja -C build
```

### 3.2 整体构建（BUILD_SYSTEM，Soong 风格）

```bash
cd BUILD_SYSTEM
./soong build --arch=x86-64 --kernel=base --set=minimal
```

详见 [BUILD/BUILD-SYSTEM.md](BUILD/BUILD-SYSTEM.md)。

## 4. 源码获取与更新

- 系统组件源码来自 Arch 打包元数据树（PKGBUILD 的 `source=` 指向的上游）与本项目 git 浅克隆/tarball。
- **注意**：所有 `.git` 已从组件中移除（防误推官方仓库）；源码为快照。
- apt 为内置后端：`src/apt/`（3.1.12-openos1，已适配）。

## 5. 内核四线

| 分层 | 内核 | 定位 |
|---|---|---|
| 经典版 | linux-5.15.215 | 老设备兼容 |
| 基础版 | linux-6.12.103 (LTS) | 默认稳定基线 |
| 基础版 | linux-7.1.8 | 7.1 线 |
| 当年预发布 | linux-7.2-rc7 | 新特性预览 |

每个内核都内置 **OPENOS Security**（强制启用）：
- `security/openos/oak_lsm.c`（LSM/子安全主体/授权/防kill）
- `security/openos/oak_early.c`（OAK-Seal 启动校验）
- `security/openos/oak_rsa.c`（OPEN RSA 握手）
- `security/openos/vmapp.c`（轻量软件隔离）

## 6. 安全模型

- **OPENOS Security**（内核 LSM）：强制启用，保护内置子安全主体 + OAK 认证第三方。
- **OAK**（加密方法）：`.oak` 密钥文件 / OPEN RSA 握手 / OAK-Seal 启动校验。
- **设备密钥**：每台设备的内核在首次启动时**自动生成设备专属 RSA 密钥对**
  （`oak_devicekey.c`，公钥经 `/proc/oak/device-key` 导出），不预置静态密钥、
  每设备唯一。私钥经安全通道交用户态存 `/etc/openos/security/device.key`。
- **vmapp**：软件隔离视图，普通进程默认不可见 `/vmapp/*`。

## 7. 工作流约定

1. 内核功能写进内核（`src/kernel/*/security/openos/`）。
2. 交互功能做成独立 app（`src/openos-*`，可单独构建）。
3. OPENUI 只是 GUI 框架，不含 app 功能。
4. 用户态服务/库/工具各有独立目录（`src/` 下），带 meson.build。
5. 文档统一放 `DOCS/`；许可证统一归档 `LICENSES/`。

## 8. 常见任务

| 任务 | 命令 |
|---|---|
| 构建一个 app | `cd src/openos-settings && meson setup build && ninja -C build` |
| 查看设备公钥 | `cat /proc/oak/device-key`（内核自动生成） |
| 封印硬盘 | `src/openos-oak-seal/openos-oak-seal /dev/sda ...` |
| 启动 opt 初始化 | `src/opt/opt.sh --init` |
| 查看 OAK 状态 | `cat /proc/oak/subjects`（需 OPENOS Security 内核） |
