# OPENOS 文档中心

OPENOS 全部文档归档于此。按主题分类。

## 快速入口

| 主题 | 文档 |
|---|---|
| **源码库使用指南** | [SOURCE-GUIDE.md](SOURCE-GUIDE.md) |
| **构建体系** | [BUILD/BUILD-SYSTEM.md](BUILD/BUILD-SYSTEM.md) |
| **发行版定位/宪法** | 见 SOURCE-GUIDE 章节 |

## 内核

| 文档 | 说明 |
|---|---|
| [KERNEL/OPENOS-SECURITY.rst](KERNEL/OPENOS-SECURITY.rst) | OPENOS Security 内核模块（LSM/OAK-Seal/子安全主体/授权/握手）— 四内核通用（5.15/6.12/7.1/7.2） |

## 安全体系 (OAK)

| 文档 | 说明 |
|---|---|
| [SECURITY/SECURITY-OAK.md](SECURITY/SECURITY-OAK.md) | OPENOS Security 完整体系（命名/架构/握手/密钥存储） |
| [SECURITY/OAK-SETTINGS-API.md](SECURITY/OAK-SETTINGS-API.md) | 应用经 OAK 加密与 Security 通信的 Settings API |

## 包管理

| 文档 | 说明 |
|---|---|
| [PACKAGING/OPT.md](PACKAGING/OPT.md) | opt 统一包管理前端（首次初始化/后端源/内置 apt） |

## 隔离机制

| 文档 | 说明 |
|---|---|
| [VMAPP.md](VMAPP.md) | vmapp 轻量软件隔离（内核 + 用户态 API） |

## 组件

| 文档 | 说明 |
|---|---|
| [COMPONENTS/APT-OPENOS-ADAPT.md](COMPONENTS/APT-OPENOS-ADAPT.md) | apt 的 OPENOS 适配（内置 opt 后端） |
| [COMPONENTS/OPENUI.md](COMPONENTS/OPENUI.md) | OPENUI 设计语言（完整规范） |
| [COMPONENTS/OPENUI-DESKTOP.md](COMPONENTS/OPENUI-DESKTOP.md) | OPENUI 桌面环境（合成器 + Qt 外壳 + 独立 app） |

> 各组件源码内的原始文档（如 apt/doc/、glibc/README 等）保留在源码树中；
> 本目录只归档 OPENOS 自研/适配文档与索引。
