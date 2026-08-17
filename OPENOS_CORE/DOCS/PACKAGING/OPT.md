# opt — OPENOS 统一包管理前端

## 架构

```
opt (Bash) ── vmappapi(opt,true) ──> /vmapp/opt 隔离视图
   │  ── 后端源 (backends.sources) ──> JSON 索引 ──> git 克隆/打补丁/构建/安装
   └─> 调用已注册后端: opt <后端> <子命令>
```

## 文件

| 文件 | 职责 |
|---|---|
| `src/opt/opt.sh` | opt 前端主脚本（初始化/后端源/安装/调用） |
| `src/opt/opt/backends.sources.example` | 后端源配置示例（`/etc/opt/backends.sources`） |
| `src/opt/opt/index.example.json` | 默认后端索引示例（官方托管于 opt-index 仓库） |
| `src/opt/opt/build.sh.template` | 后端构建脚本模板 |

## 首次初始化流程

1. 检测 apt → 缺失则安装（pacman 仓库 / apt 自举）
2. 从所有源合并后端列表 → 显示可选后端
3. 询问是否安装 → 选择编号/all
4. 对每个后端：git clone → patch → build → install → 注册
5. 写 `/etc/opt/.initialized` 标记

## 用法

```bash
sudo ./opt.sh                 # 首次自动初始化
./opt.sh --list-backends      # 列出可用后端
./opt.sh yum --version        # 调用已安装后端
./opt.sh --init               # 重新初始化
./opt.sh --force yum install  # 跳过依赖检查
./opt.sh adapt /path/to/src   # (实验性) AI 生成适配补丁
```

## 后端源格式

每行一个 URL（JSON）或本地目录；索引结构见 `index.example.json`：
`id / name / description / repo(git) / build_script / patch / dependencies / default`。
