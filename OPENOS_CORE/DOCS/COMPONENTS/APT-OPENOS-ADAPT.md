# apt OPENOS 适配说明

apt `3.1.12` 已适配 OPENOS 并作为 opt 的**内置后端**（本地源码构建，不下载）。
源码位于本目录 `src/apt/`（.git 已移除，防误推官方仓库）。

## 适配点（已修改）

| 文件 | 修改 |
|---|---|
| `CMakeLists.txt` | `PACKAGE_VERSION` → `3.1.12-openos1`（OPENOS 版本标识） |
| `vendor/openos/apt-vendor.ent` | **新增** OPENOS vendor（keyring=openos-archive-keyring，源=repo.openos.org/apt） |
| `vendor/openos/openos.sources.in` | **新增** OPENOS 默认源模板 |
| `vendor/getinfo` | 优先检测 `/etc/openos-release`/`/etc/openos_version` → vendor=openos |
| `apt-pkg/deb/debsystem.cc` | 检测到 `/etc/openos-release`/`/etc/openos_version` 时设 `APT::Vendor=openos` |

## 构建（opt 内置自动执行）

```bash
cmake /path/to/src/apt -DWITH_DOC=OFF -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

依赖（构建期需安装）：`cmake zlib lz4 zstd libcurl libdb bz2 libgcrypt gettext g++`。
OPENOS 上可用 pacman 安装。

## 运行期

- 需 `/etc/openos_version` 或 `/etc/openos-release`（opt 内置安装时自动写入 `/etc/openos_version`）。
- 默认源 `repo.openos.org/apt`（见 vendor/openos），可经 `/etc/apt/sources.list` 覆盖。

## opt 集成

- `opt.sh` 的 `install_builtin_apt()`：检测 apt 缺失 → 从本目录 cmake 构建 → `sudo make install` → 写 `/etc/openos_version`。
- **不下载、不联网**：源码已内置在 `src/apt/`。
