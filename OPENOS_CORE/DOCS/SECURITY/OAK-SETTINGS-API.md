# OPENOS Settings API — 应用通过 OAK 加密与 Security 模块通信

## 架构

```
应用 App ── liboak ──OAK 加密──> openos-settingsd (自动创建)
                                   │ 首次请求: 询问用户授权
                                   │   → 通知 → 用户允许/拒绝 → 持久化
                                   ▼
                              /proc/oak/* → 内核 OPENOS Security
```

## API (src/liboak/liboak.h)

| 函数 | 说明 |
|---|---|
| `oak_settings_request(req, app_id, pubkey)` | 应用发起设置变更（OAK 加密包裹） |
| `oak_authorized(app_id)` | 查询应用是否已获授权 |
| `oak_set_sk_path(path)` | 设置 OAK-SK 来源 |

### 状态码
`OAK_OK` / `OAK_DENIED` / `OAK_PENDING`(等待用户确认) / `OAK_ERR_*`

### 设置类别
`OAK_SET_WATCHDOG` / `OAK_SET_BUILTIN` / `OAK_SET_WHITELIST` /
`OAK_SET_SUBJECT` / `OAK_SET_UNLOCK`

## 流程

1. 应用调 `oak_settings_request()` → liboak 用 OAK-SK 算 `H2 = SHA256(H1 + SK)`
2. liboak 检测 `openos-settingsd` 未运行 → **自动 fork/exec 创建**
3. settingsd 校验 OAK 加密 → 该应用未授权时 **弹通知询问用户**
4. 用户允许 → 持久化到 `/var/lib/openos/authorized.conf` → 转发 `/proc/oak/*`
5. 返回 `OAK_OK`（已应用）或 `OAK_PENDING`（等待确认）

## 构建 / 使用

```bash
./build-oak-settings.sh
# 应用:
cc app.c liboak.a -lsodium
# 守护 (root):
./openos-settingsd
```

## 文件

| 文件 | 职责 |
|---|---|
| `src/liboak/liboak.h` | API 头 |
| `src/liboak/liboak.c` | 应用侧实现 (加密+自动拉起守护) |
| `src/openos-settingsd/openos-settingsd.c` | 设置守护 (授权确认+持久化+转发内核) |
| `src/build-oak-settings.sh` | 构建脚本 |
