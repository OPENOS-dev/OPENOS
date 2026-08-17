# OPENOS 自研组件许可说明

OPENOS 自研代码（非上游组件）统一采用 **GPL-2.0-only**（与 Linux 内核一致，
因为包含内核模块 `security/openos/`）。

## 覆盖范围

以下为 OPENOS 自研/适配代码，以 GPL-2.0-only 授权：

| 组件 | 目录 |
|---|---|
| OPENOS Security（内核模块） | `src/kernel/*/security/openos/` |
| OPENUI 桌面环境 | `src/OPENUI-desktop/` |
| GUI App | `src/openos-{settings,oak,opt,vmapp,calendar,run,welcome}/` |
| 系统服务 | `src/openos-{securityd,settingsd}/` |
| 库 | `src/lib{ oak,vmapp,openrsa }/` |
| 工具 | `src/{opt,oakctl,openos-oak-seal}/` |
| 构建体系 | `BUILD_SYSTEM/` |
| 文档 | `DOCS/` |

## 上游组件许可

各上游组件（glibc/gcc/bash/coreutils/systemd/util-linux/pacman/apt/linux）的
许可副本已归档到 `LICENSES/components/<组件>/`，以各自为准：

| 组件 | 许可 |
|---|---|
| glibc | LGPL-2.1（主库）+ GPL-2.0（部分）|
| gcc | GPL-3.0 + GCC Runtime Library Exception |
| bash | GPL-3.0 |
| coreutils | GPL-3.0 |
| systemd | LGPL-2.1 |
| util-linux | GPL-2.0（部分 BSD）|
| pacman | GPL-2.0 |
| apt | GPL-2.0 |
| linux | GPL-2.0 |

## 说明

- OPENOS 基于 Arch Linux 打包元数据树（各组件 `LICENSE` 文件为
  "Copyright Arch Linux Contributors"，BSD-2-Clause 风格，见副本）。
- 完整许可文本见 `LICENSES/components/*/`。
