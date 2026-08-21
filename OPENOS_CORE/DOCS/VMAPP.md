# vmapp — 轻量软件隔离机制

## 架构

```
应用 (opt/应用抽屉) ── vmappapi() ──> /dev/vmapp ioctl ──> 内核 OPENOS Security
                                                                │
                     /vmapp/<app>/{etc,var,usr,opt,home} (0700 root)
```

- **内核实现**：`src/kernel/*/security/openos/vmapp.c`（四内核一致，
  `obj-$(CONFIG_SECURITY_OPENOS) += vmapp.o`）
- **示例**：`src/vmapp_demo.c`（含测试用例）

## API

```c
int vmappapi(const char *app_name, bool enable,
             const char *sub_path, char *out, int out_cap, int *out_len);
```

| enable | sub_path | 行为 |
|---|---|---|
| true | NULL | 创建 `/vmapp/<app>` 骨架 + `unshare(CLONE_NEWNS)` + 切换到隔离根视图 |
| false | 路径 | 列出 `/vmapp/<app>/<sub_path>` 目录条目（应用抽屉用） |
| false | NULL | 无操作（进程退出即恢复宿主视图） |

**错误码**：`EINVAL`(非法名) / `ENOENT`(目录不存在) / `EPERM`(需 CAP_SYS_ADMIN) / `ENOMEM`。

## 安全

- `app_name` 仅允许 `[a-zA-Z0-9_-]`（防 `/` 与 `..` 路径遍历）
- `/vmapp` 目录 0700（root only），`/dev/vmapp` 0600 + ioctl 需 `CAP_SYS_ADMIN`
- 普通进程默认无法访问 `/vmapp` 下任何路径

## 测试

```bash
./vmapp_demo enter opt        # 应看到 /vmapp/opt 内内容 (ls /)
./vmapp_demo exit opt         # 进程退出恢复宿主视图
./vmapp_demo list opt usr/share/applications   # 返回 .desktop 列表
./vmapp_demo bad "../etc"     # 应 EINVAL
```
