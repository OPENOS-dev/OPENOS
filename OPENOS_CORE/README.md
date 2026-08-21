# OPENOS

**OPENOS, run anywhere.**

OPENOS 是基于 Arch Linux 构建的开源操作系统：从内核到桌面完全自主设计，
提供安全、轻量、跨平台、完全自由的运行环境。

## 核心特性

| 特性 | 说明 | 实现状态 |
|---|---|---|
| **OPENOS Security** | 内核级强制启用 LSM：保护内置子安全主体（System/OPT/Application）+ OAK 认证第三方 | ✅ 已实现 |
| **OAK 安全基座** | 内核级非对称加密（OPEN RSA 握手）+ 进程保护 + 设备专属密钥 + OAK-Seal 启动完整性校验（硬盘 0x1000 封印）| ✅ 已实现 |
| **OPENUI 桌面** | Wayland(wlroots) 合成器 + Qt/QML 外壳 + 自研 OPENUI 设计语言（NUI 规范衍生），键盘优先、默认无广告 | ✅ 已实现 |
| **OPT 包管理** | 统一前端：内置 apt 后端（本地源码构建，不下载）+ 动态后端源（git/HTTP JSON）| ✅ 已实现 |
| **软件命名空间隔离 (SNI)** | 内核级轻量虚拟化（vmapp）：为应用提供独立文件系统视图（`/vmapp/<app>`），调用 < 1s，普通进程默认不可见 | ✅ 已实现 |
| **跨平台架构** | x86 / x86-64 / ARM32 / ARM64 / **LoongArch64** 五架构 | ✅ 构建体系已支持 |

## 快速开始

从源码构建（Linux / Arch 环境）：

```bash
git clone https://github.com/OPENOS-dev/OPENOS.git
cd OPENOS
./BUILD_SYSTEM/openos-build --build-all --arch=x86-64 --kernel=base
```

或按 Google Soong/Blueprint 风格声明式构建（见 `BUILD_SYSTEM/OPENOS.bp`）。

### 源码结构

```
OPENOS_CORE/
├── BUILD_SYSTEM/     # 构建体系 (Soong 风格: OPENOS.bp + openos-build)
├── DOCS/             # 文档中心 (内核/安全/包管理/隔离/组件)
├── LICENSES/         # 全部组件许可证归档
└── src/              # 全部源码组件 (独立构建)
    ├── kernel/       # 五线内核 (5.15/6.12/7.1/7.2 + OPENOS Security)
    ├── apt/ bash/ gcc/ glibc/ ...   # Arch 基线系统组件
    ├── openos-*/     # 独立 GUI App (settings/oak/opt/vmapp/calendar/run/welcome)
    ├── openos-securityd/ openos-settingsd/   # 系统服务
    ├── liboak/ libopenrsa/                   # 库
    └── opt/ oakctl/ openos-oak-seal/         # 工具
```

## 组件一览

| 项目 | 描述 | 状态 |
|---|---|---|
| OPENOS | 操作系统核心（内核补丁 + 用户态工具）| active |
| OPENOS Security | 安全模块（LSM + OAK-Seal + 设备密钥 + 授权提权 + 子安全主体）| active |
| OAK | 加密/密钥体系（OPEN RSA 握手 + .oak 密钥 + 设备专属密钥）| active |
| OPENUI | Wayland 桌面环境（wlroots 合成器 + Qt/QML 外壳）| active |
| OPT | 统一包管理前端（内置 apt + 动态后端源）| active |
| SNI (vmapp) | 软件命名空间隔离（内核模块 + 用户态 API）| active |
| NUI-SPEC | 设计规范（OPENUI 设计语言来源）| active |
| OPL | OPENOS-PROJECT-LICENSE | active |

## 文档

完整文档见 [`OPENOS_CORE/DOCS/`](OPENOS_CORE/DOCS/README.md)：
- 内核：`KERNEL/OPENOS-SECURITY.rst`
- 安全体系：`SECURITY/SECURITY-OAK.md`、`SECURITY/OAK-SETTINGS-API.md`
- 包管理：`PACKAGING/OPT.md`
- 隔离：`VMAPP.md`
- 构建：`BUILD/BUILD-SYSTEM.md`
- 源码库指南：`SOURCE-GUIDE.md`

## 许可证

本项目采用 **OPL（OPENOS-PROJECT-LICENSE）**，基于 GPLv3 修改。
完整文本见 `LICENSES/`；自研代码统一 GPL-2.0-only，各组件许可归档于 `LICENSES/components/`。
