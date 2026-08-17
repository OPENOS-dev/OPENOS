# OPENOS 许可证归档

本目录集中归档 OPENOS 项目全部代码的许可证。

## 结构

```
LICENSES/
├── README.md                 # 本索引
├── OPENOS-LICENSE.md         # 自研组件许可说明 (GPL-2.0-only)
└── components/<组件>/        # 各上游组件许可副本
    ├── apt/   (COPYING, COPYING.GPL)
    ├── bash/  (LICENSE)
    ├── coreutils/ (LICENSE)
    ├── gcc/   (LICENSE)
    ├── glibc/ (LICENSE, COPYING.LIB, COPYINGv2, COPYINGv3, COPYING.LESSERv2)
    ├── linux/ (LICENSE, COPYING.GPL-2.0)
    ├── pacman/ (LICENSE)
    ├── systemd/ (LICENSE)
    └── util-linux/ (LICENSE)
```

## 自研组件

OPENOS 自研代码（内核模块、OPENUI、app、服务、库、工具、构建体系、文档）
统一 GPL-2.0-only，各组件目录内含 `COPYING`，详见 `OPENOS-LICENSE.md`。

## 上游组件

各组件许可以各自源码树内的许可为准，本目录为副本（供分发/合规检查）。
Arch 打包元数据树许可（`Copyright Arch Linux Contributors`）见各 `LICENSE`。

## 合规提醒

- 分发二进制时保留各组件 `LICENSES/` 与 `COPYING`。
- 静态链接 LGPL 库（glibc 主库、systemd 部分）需提供 relink 能力或动态链接。
