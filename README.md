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

| 项目 | 描述 | 状态 |
| :--- | :--- | :--- |
| [OPENOS](https://github.com/OPENOS-dev/OPENOS) | 操作系统核心（内核补丁 + 用户态工具） | active |
| [OAK](https://github.com/OPENOS-dev/OAK) | 安全基座（LSM 模块 + 密钥管理） | active |
| [OPENUI](https://github.com/OPENOS-dev/OPENUI) | Wayland 桌面环境 | active |
| [OPT](https://github.com/OPENOS-dev/OPT) | 统一包管理前端 | planning |
| [NUI-SPEC](https://github.com/OPENOS-dev/NUI-SPEC) | NUI 设计规范（NUI1/NUI2 已开源） | active |
| [OPL](https://github.com/OPENOS-dev/OPL) | OPENOS-PROJECT-LICENSE | active |
| [SNI](https://github.com/OPENOS-dev/SNI) | 软件命名空间隔离（内核模块） | planning |

---

## 许可证

OPENOS 采用 **OPL（OPENOS-PROJECT-LICENSE）** 发布。该许可证基于 GPLv3 修改。

完整许可证文本请参阅项目根目录的 [`COPYING`](COPYING) 文件。

---

## 社区与贡献

OPENOS 目前由项目发起人主导开发，辅以 AI 辅助，同时欢迎所有感兴趣的开发者参与。

- [GitHub 组织](https://github.com/OPENOS-dev) – 所有源码与议题
- [Discord 社区](https://discord.gg/xj6VCg7Na) – 实时交流与讨论
- [NUI 设计仓库](https://github.com/OPENOS-dev/NOTHING-UI-1) – 设计规范参考

贡献指南请参阅 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

---

**OPENOS, run anywhere.**  
*从你的设备，到你的选择。*
