# OPENOS Security — 系统安全模块 (内部加密方法 OAK)

版本：DEV2026.1 · 内核实现：`src/kernel/*/security/openos/oak_lsm.c`

> 命名：系统中的安全**模块**叫 **OPENOS Security**（`CONFIG_SECURITY_OPENOS`，
> LSM 名 `openos_security`）；**OAK** 是其内部的**加密方法/密钥体系**
> （`.oak` 密钥文件、`oakctl` 工具、握手协议）。

## 1. 架构：OAK 子安全主体

```
OPENOS Security (根安全主体, LSM, 强制启用不可禁用)
├── System 子主体       (内置/固定, 看门狗)
├── OPT 子主体          (内置/固定, 包管理)
├── Application 子主体  (内置/固定, 应用生命周期)
└── 第三方子主体        (动态注册, 带公钥+权利)
```

每个**子安全主体** = `name + kind(builtin|third) + pid + capmask(内核权利) + pubkey(公钥) + 指纹`。
应用收到请求后，经握手验证身份，可**加入（挂靠）**某个子安全主体，获得该主体的信任与内核权利。

## 1.5 密钥存储与设备专属密钥

### 设备专属密钥 (内核自动生成)

**每台设备的内核在首次启动时自动生成设备专属 RSA 密钥对**（`oak_devicekey.c`），
不预置静态密钥、每设备唯一：

- **公钥**: 内核保存, 经 `/proc/oak/device-key` 导出（设备身份标识, 公开）。
- **私钥**: 内核生成后经受保护通道交用户态, 存 `/etc/openos/security/device.key`。
- 用于 OAK-Seal 封印 / OPEN RSA 握手的设备级身份锚。

```
首次启动 ──> 内核生成 RSA 设备密钥对
              ├── 公钥 → /proc/oak/device-key (公开)
              └── 私钥 → /etc/openos/security/device.key (受保护)
```

### 其他密钥 (.oak 文件)

非设备级密钥（子主体公钥、应用公钥、OAK-SK）仍用 `.oak` 文件存储：

- **应用密钥**: 应用在自己的安全目录存 `<app-id>.oak`(公钥) +
  `.private/<app-id>.key.oak`(私钥), 注册时提交给 `/proc/oak/subjects`。
- **OAK-SK**: `/etc/openos/security/oak-sk.key` (共享密钥)。
- **工具**: `src/oakctl/oakctl.sh` 生成/解析 `.oak` (openssl), 计算公钥指纹。

## 2. 用户态接口

| 接口 | 操作 |
|---|---|
| `echo "register <name> third <pid> <capmask_hex> [pubkey_hex]" > /proc/oak/subjects` | 注册第三方子主体 |
| `echo "pubkey <name> <pubkey_hex>" > /proc/oak/subjects` | 登记/更新子主体公钥 |
| `echo "unregister <name>" > /proc/oak/subjects` | 注销 |
| `cat /proc/oak/subjects` | 列出全部子主体（含公钥指纹） |
| `echo "challenge <name>" > /proc/oak/handshake` | 内核生成挑战（随机数） |
| `echo "verify <name> <peer_pub_hex> <sig_hex>" > /proc/oak/handshake` | 验签 + 建立会话 |
| `echo "<subject-name>" > /proc/oak/authorize` | 进程自证身份，获子主体权利 |
| `echo "add <pid> [capmask]" > /proc/oak/whitelist` | 白名单（legacy，subjects 是其增强版） |

内置守护登记（`/proc/oak/builtin`）时**自动**成为内置子主体（`OAK_SUBJECT_BUILTIN`）。

## 3. 握手协议（类非对称加密，双向签名）

> 术语映射：你的"哈希序列串" = 密钥对；"公钥" = 公钥（公开）；"私钥" = 私钥（保密）；
> "私钥+对方公钥算出序列串" = 签名/密钥协商；"双向发送验证" = 双向签名握手。

```
应用 A  (keypair: privA, pubA)           OAK 子主体 B (keypair: privB, pubB)
  |  (pub 均公开: pubA 经 subjects 注册, pubB 系统内可查)          |
  |--1. 生成随机 challenge_a -------------------------------->|
  |    (A, pubA, challenge_a)                                  |
  |<--2. 生成 challenge_b; 用 privB 签名                       |
  |    sig_b = sign(privB, challenge_a || pubA)                |
  |    (pubB, challenge_b, sig_b) ---- 用 pubB 验签(步骤1->2)  |
  |--3. 用 privA 签名 challenge_b || pubB -> sig_a ----------->|
  |    (sig_a)                           用 pubA 验签(sig_a)   |
  |<-------------------------------------------------- 身份双向成立 |
  |  4. K = 会话密钥(由双方 pub 派生) 之后安全连接用 K 保护    |
```

内核侧已实现：公钥存储 + 挑战生成 + 签名验证框架 + 会话密钥派生
（`oak_handshake()`）。签名原语（非对称验签）生产环境须启用
`CONFIG_CRYPTO_RSA`（akcipher `pkcs1pad(rsa,sha256)`）替换当前占位实现；
占位实现使模块在未配置 crypto 时仍可编译（fallback 校验）。

## 4. 固定逻辑 vs 动态接口

| | 固定逻辑（不可改） | 动态接口（运维可管理） |
|---|---|---|
| 内置子主体 | system/opt/application 槽位、角色权利、强制启用 | PID 值、公钥登记（watchdog 操作） |
| 第三方子主体 | OAK 根信任、握手协议 | 注册/注销/公钥/权利（`/proc/oak/subjects`） |
| 白名单 | — | add/del（legacy） |

## 4.5 用户态守护进程 (openos-securityd)

`src/openos-securityd/openos-securityd.c` — OAK 协议用户态守护进程原型（先用户态，后续下沉内核）：

- 监听 Unix Socket `/run/openos/oak.sock`
- 接收 `(时间戳, 命令, 哈希H1)`
- 用本地 OAK-SK（`/etc/openos/security/oak-sk.key`）算 `H2 = SHA256(H1 + OAK-SK)`（libsodium）
- 比对返回 `OK` 或 `DENY`（含时间戳防重放 + 命令白名单）
- 完整 `main()` 循环（poll 多路复用）+ 信号处理（SIGTERM/SIGINT/SIGQUIT 优雅退出）

构建/运行/测试：
```bash
./build-securityd.sh                 # cc -O2 -lsodium
./openos-securityd                   # 启动 (默认 /run/openos/oak.sock)
./oak-test-client seal-verify        # 测试客户端
```

## 4.6 OPEN RSA 握手协议（内核功能）

**权威实现在内核**：`src/kernel/*/security/openos/oak_rsa.c`（四内核一致）。
这是 OPENOS Security 模块的组成部分（`obj-$(CONFIG_SECURITY_OPENOS) += oak_rsa.o`），
供 System/OPT/Application 子安全主体及 OAK 认证第三方在系统内部建立安全连接。

- `openrsa_handshake()`（内核导出）：客户端私钥签名→H1；内核用客户端**公钥**
  验签 H1（确认消息来自该客户端），再用服务端私钥对 `H1||ts` 叠加签名→H2
- 时间戳**毫秒级**：`ktime_get_real_ts64()` 纳秒→毫秒（防重放）
- 算法：RSA + SHA-256，内核 crypto API（`crypto_shash` 摘要 + `akcipher` 验签/签名，
  需 `CONFIG_CRYPTO_RSA`；当前验签/签名为框架占位，生产接入见文件头 `akcipher`
  模板说明）
- 返回：0 成功 / `-EINVAL` 参数错误 / `-ENOPROTOOPT` 无 RSA 支持

> 用户态 `src/` 下曾有的 openrsa 纯逻辑版已**并入内核实现**（内核版为权威），
> 用户态仅保留协议配套测试工具（见下）。

**用户态协议测试**（仅验证用，非内核功能）：
- `src/openrsa_test.c`：6 用例（正常/篡改数据/伪造 H1/篡改 H1/毫秒单调/参数校验）
- `src/build-openrsa.sh` → `./openrsa_test`

## 4.7 OAK-Seal 封印工具（用户态写硬盘头）

`src/openos-oak-seal/openos-oak-seal.c` — 与内核 `oak_early.c` 校验**对称**的封印工具：

- 读 `/boot/vmlinuz-$(uname -r)` 算 SHA-256（OpenSSL）
- 用 OAK-SK（环境变量 `OPENOS_OAK_SK`）经 HKDF 派生临时密钥，AES-256-CTR
  加密 LUKS 主密钥（`DM_TABLE_STATUS`/`dmsetup --showkeys` 从 dm-crypt keyring 获取）
- 写封印块到 `/dev/sdX` 偏移 `0x1000`（需确认设备名，防误写）
- 重读校验写入完整性
- 封印块布局与内核 `struct oak_seal_block` 一致（LE 显式打包）

构建/使用：
```bash
./build-oak-seal.sh                      # 优先静态 -static
export OPENOS_OAK_SK='<共享密钥>'
./openos-oak-seal /dev/sda <dm-crypt名> <用户名> <密码>
```

## 4.8 OAK 状态指示器（Qt6 + wlroots 胶水桥）

`OPENUI-desktop/src/shell/oakindicator/` — 在合成器中渲染 QML OAK 状态指示器：

- `oak_bridge.{h,cpp}`：`OakSocketClient`（连 `/run/openos/oak.sock` 轮询
  openos-securityd，`OK/DENY` 映射到 NUI2 状态色）+ `OakQmlRenderer`
  （`QQuickRenderControl` 离屏渲染 QML → `wlr_texture_from_pixels` 上传 wlr 纹理）
- `OAKState.qml`：状态胶囊（状态色圆点 + 文本），`objectName="oakState"` 供桥查找
- `oak_mainloop.{h,cpp}`：Qt 事件循环 + wlroots 主循环集成（单线程
  `processEvents` 轮询 / `QThread` 线程分离双模式）
- `main.cpp`：合成器集成框架（在 `wlr_output.frame` 调 `renderToTexture` +
  draw）
- `CMakeLists.txt`：`CMAKE_CXX_STANDARD 17` + Qt6 Quick/Qml + wlroots pkg-config

## 5. 后续（生产加固）

- [ ] 验签接入内核 crypto API（RSA/ECDSA, CONFIG_CRYPTO_*）
- [ ] 用户态 `oakctl` 工具：密钥生成(openssl)、注册、握手、会话管理
- [ ] 会话密钥升级 ECDH 协商 + 会话超时/吊销
- [ ] 子主体心跳/看门狗联动（System 子主体）
