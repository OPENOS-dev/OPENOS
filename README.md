# OPENOS

> **OPENOS, run anywhere.**

OPENOS 是一个基于 Arch Linux 构建的开源操作系统，由 OPENOS-dev 维护。它从内核到桌面完全自主设计，致力于提供安全、轻量、跨平台的运行环境，且不限制硬件、不限制软件、完全免费。

---

## 核心特性

- **OAK 安全基座**：内核级非对称加密与进程保护，不依赖 TPM，支持 OAK-Seal 硬盘加密绑定，确保系统完整性。
- **OPENUI 桌面**：基于 Wayland + wlroots 与 Qt/QML 的自研桌面环境，遵循 NUI 设计规范，默认无广告、键盘优先。
- **OPT 包管理**：统一前端，同时支持 pacman 与 apt 双后端，首次启动自动配置，支持软件命名空间隔离。
- **软件命名空间隔离 (SNI)**：内核级轻量虚拟化，为应用提供独立文件系统视图，调用耗时 < 1 秒，资源占用极低。
- **跨平台支持**：x86-32, x86-64, ARM32, ARM64, LoongArch64 全覆盖，从老旧设备到现代硬件均可运行。
- **OPL 许可证**：OPENOS-PROJECT-LICENSE，保障代码自由、设备自由、体验自由与操作自由。

---

## 快速开始

### 从源码构建（Linux / Arch 环境）

```bash
git clone https://github.com/OPENOS-dev/OPENOS.git
cd OPENOS
./scripts/build.sh --target=x86_64
```

更多构建选项（arm64、loongarch 等）请参阅 [README](https://github.com/OPENOS-dev/OPENOS/blob/main/README.md) 中的详细指南。

### 获取预编译镜像

预编译 ISO 镜像可从 [Releases](https://github.com/OPENOS-dev/OPENOS/releases) 页面下载，支持直接烧录至 U 盘或用于虚拟机安装。

---

## 核心项目

OPENOS 由 `OPENOS-dev/OPENOS` 主仓库与若干子模块仓库组成，每个子模块独立构建并产出 binpkg。

### 主仓库

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS](https://github.com/OPENOS-dev/OPENOS) | 操作系统主仓库（构建系统 + 子模块聚合） | active |

### 内核

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS-kernel](https://github.com/OPENOS-dev/OPENOS-kernel) | 内核（含 OAK 安全 LSM 补丁，多版本分层） | active |
| [OPENOS-linux](https://github.com/OPENOS-dev/OPENOS-linux) | 上游 Linux 源码引用 | active |

### 安全基座（OAK）

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS-OAK](https://github.com/OPENOS-dev/OPENOS-OAK) | OAK 安全基座（加密/密钥管理 app） | active |
| [OPENOS-liboak](https://github.com/OPENOS-dev/OPENOS-liboak) | OAK 核心库 | active |
| [OPENOS-libopenrsa](https://github.com/OPENOS-dev/OPENOS-libopenrsa) | OPEN RSA 握手库 | active |
| [OPENOS-libvmapp](https://github.com/OPENOS-dev/OPENOS-libvmapp) | 轻量隔离 (vmapp) 库 | active |
| [OPENOS-oakctl](https://github.com/OPENOS-dev/OPENOS-oakctl) | OAK 密钥管理 CLI | active |
| [OPENOS-oak-seal](https://github.com/OPENOS-dev/OPENOS-oak-seal) | OAK-Seal 硬盘加密绑定 | active |
| [OPENOS-securityd](https://github.com/OPENOS-dev/OPENOS-securityd) | 安全守护进程 | active |
| [OPENOS-uname](https://github.com/OPENOS-dev/OPENOS-uname) | 系统信息工具（含 OAK 标识） | active |

### 桌面环境（OPENUI）

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS-OPENUI-desktop](https://github.com/OPENOS-dev/OPENOS-OPENUI-desktop) | Wayland + wlroots + Qt/QML 桌面 | active |
| [OPENOS-settings](https://github.com/OPENOS-dev/OPENOS-settings) | 系统设置 GUI | active |
| [OPENOS-settingsd](https://github.com/OPENOS-dev/OPENOS-settingsd) | 设置守护进程 | active |
| [OPENOS-calendar](https://github.com/OPENOS-dev/OPENOS-calendar) | 日历应用 | active |
| [OPENOS-welcome](https://github.com/OPENOS-dev/OPENOS-welcome) | 欢迎/引导程序 | active |
| [OPENOS-run](https://github.com/OPENOS-dev/OPENOS-run) | 应用启动器 | active |
| [OPENOS-vmapp](https://github.com/OPENOS-dev/OPENOS-vmapp) | 隔离运行前端 | active |

### 包管理（OPT）

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS-opt](https://github.com/OPENOS-dev/OPENOS-opt) | 统一包管理前端（pacman + apt 双后端） | planning |
| [OPENOS-pacman](https://github.com/OPENOS-dev/OPENOS-pacman) | pacman 包管理器 | active |
| [OPENOS-apt](https://github.com/OPENOS-dev/OPENOS-apt) | apt 包管理器 | active |

### 工具链与基础系统

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS-gcc](https://github.com/OPENOS-dev/OPENOS-gcc) | GNU 编译器集合 | active |
| [OPENOS-glibc](https://github.com/OPENOS-dev/OPENOS-glibc) | GNU C 库 | active |
| [OPENOS-bash](https://github.com/OPENOS-dev/OPENOS-bash) | Bourne-Again Shell | active |
| [OPENOS-coreutils](https://github.com/OPENOS-dev/OPENOS-coreutils) | 基础用户态工具 | active |
| [OPENOS-util-linux](https://github.com/OPENOS-dev/OPENOS-util-linux) | 磁盘/分区/登录等工具 | active |
| [OPENOS-systemd](https://github.com/OPENOS-dev/OPENOS-systemd) | init 系统与系统守护 | active |

---

## 许可证

OPENOS 采用 **OPL（OPENOS-PROJECT-LICENSE）** 发布。该许可证基于 GPLv3 修改。

完整许可证文本请参阅项目根目录的 [`COPYING`](COPYING) 文件。

---

## 社区与贡献

OPENOS 目前由仓颉开发，辅以 AI 辅助，同时欢迎所有感兴趣的开发者参与。

- [GitHub 组织](https://github.com/OPENOS-dev) – 所有源码与议题
- [Discord 社区](https://discord.gg/xj6VCg7Na) – 实时交流与讨论
- [NUI 设计仓库](https://github.com/OPENOS-dev/NUI2) – 设计规范参考

贡献指南请参阅 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

---

**OPENOS, run anywhere.**  
*从你的设备，到你的选择。*
