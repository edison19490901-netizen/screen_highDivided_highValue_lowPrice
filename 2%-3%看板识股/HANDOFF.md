---
name: dashboard-deployment-handoff
description: 看板识股 GitHub Pages 部署方案完整 handoff
metadata: 
  node_type: memory
  type: project
  originSessionId: 8ac2dd65-175f-4427-94bf-7779f5badcec
  modified: 2026-08-03T08:37:18.517Z
---

# 看板识股 — 部署 Handoff

## 项目位置
`D:\Claudeee\highDivided_highValue_lowPrice\网格高市值高股息率\2%-3%看板识股\`

## 选股策略
- 股息率 > 3%
- 市值 > 500亿
- 最新价距1年最低 < 15%
- 最新价距周线BB下轨 < 15%

## GitHub 仓库
`https://github.com/edison19490901-netizen/dashboard-of-high_divided_screen`

## 部署架构

```
GitHub Pages (免费静态托管)          本地 Windows (数据更新)
     │                                     │
index.html ─── 内嵌 JSON 数据 ←──── app.py 生成 dashboard.html
     │                                     │
手机/任何设备                          Tushare + Baostock
永久在线访问                           拉取最新数据
```

- **看板地址**: `https://edison19490901-netizen.github.io/dashboard-of-high_divided_screen`
- **零费用**: GitHub Pages 免费 + 无服务器
- **数据更新**: 本地跑 Python 生成新 HTML → 推送到 GitHub

## 首次启用 GitHub Pages

1. 打开 https://github.com/edison19490901-netizen/dashboard-of-high_divided_screen/settings/pages
2. Branch 选 `master`，文件夹选 `/ (root)`
3. 点 Save，等 1 分钟生效

## 每日自动推送（daily_report.py）

### 运行流程

```
daily_report.py
  ├─ 1. 从本地缓存加载 Tushare 股息率+市值数据
  ├─ 2. Baostock 补充最新股价 & 布林带技术指标
  ├─ 3. 价格过滤（股息率>3% · 市值>500亿 · 距1年低点<15% · 距BB下轨<15%）
  ├─ 4. 更新 dashboard.html（内嵌 EMBED JSON 数据）
  ├─ 5. 生成静态 HTML 表格（TOP20，无需 JS，微信可直接查看）
  ├─ 6. git push dashboard.html 到 GitHub Pages 仓库根目录（SSH 方式）
  └─ 7. 通过 PushPlus 将静态 HTML 推送到微信
```

### 命令

```bash
cd D:\Claudeee\highDivided_highValue_lowPrice\网格高市值高股息率\2%-3%看板识股
python daily_report.py
```

### PushPlus 微信推送

- 服务: [PushPlus](http://www.pushplus.plus) — 微信公众号消息推送
- 模板: `html` — 推送静态 HTML 表格，微信内直接渲染
- 内容: TOP20 股票表格（按距低点升序），颜色标记（绿≤8% / 黄≤12% / 红>12%）
- Token: 存储在 `.env` → `PUSHPLUS_TOKEN=xxx`

### GitHub Pages 推送（SSH）

- 目标仓库: `git@github.com:edison19490901-netizen/dashboard-of-high_divided_screen.git`
- 方式: 独立克隆 Pages 仓库 → 复制 dashboard.html 为根目录 index.html → commit + push
- 原理: 不污染本地 `screen_highDivided_highValue_lowPrice` 仓库，用临时目录操作 Pages 仓库
- SSH 密钥: `~/.ssh/id_ed25519` (daily-report-bot)，已添加到 GitHub
- 为什么用 SSH: 这台机器 Git HTTPS (schannel) 连接 GitHub 间歇性 SSL 协商超时，SSH 稳定

### Windows 定时任务

- 任务名称: `HighDividendDailyReport`
- 执行: 周一至周五（可在 `setup_task.ps1` 第 15 行改时间）
- 调用链: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` → `C:\Users\HD07\run_report.ps1` → `python daily_report.py`
- 日志: `auto_report.log`（项目目录下，由 `daily_report.py` 内置 `_Tee` 类双写屏幕+文件）
- **唤醒**: `WakeToRun` 已启用 — 电脑休眠/合盖也会自动唤醒执行
- **错过补跑**: `StartWhenAvailable` 已启用 — 错过时间点开机后会补跑
- **电池运行**: `AllowStartIfOnBatteries` — 拔电状态也执行

**重要：PowerShell 只用于一次性注册任务，关闭不影响自动更新。** 任务由 Windows 任务计划程序（系统服务）驱动，注册完后无需再管。

**安装/修改定时任务**（管理员 PowerShell）：
```
& "D:\Claudeee\highDivided_highValue_lowPrice\网格高市值高股息率\2%-3%看板识股\setup_task.ps1"
```

**手动测试**：
```
schtasks /run /tn HighDividendDailyReport
```

**查看/手动修改任务**：`Win+R` → `taskschd.msc` → 搜索 `HighDividendDailyReport`

**电源设置**（必须开启，否则唤醒不生效）：
`Win+R` → `powercfg.cpl` → 当前计划 → 更改高级电源设置 → 睡眠 → **允许唤醒计时器** → **启用**

#### 定时任务踩坑记录（2026-08-05）

Windows 任务计划程序在存储含**中文字符的路径**时会出现编码损坏（显示乱码），导致脚本无法找到。经过多次尝试，最终方案如下：

| 尝试 | 方案 | 结果 |
|---|---|---|
| 1 | 任务直接调用 `daily_report.bat`（中文路径） | ❌ 路径乱码，bat 找不到 |
| 2 | 任务直接调用 `python.exe` + `-WorkingDirectory`（中文） | ❌ WorkingDirectory 乱码 |
| 3 | 任务直接调用 `python.exe` + 绝对路径参数（中文） | ❌ 参数路径乱码 |
| 4 | 纯英文路径 `run_report.bat` 做跳板 | ❌ bat 文件 UTF-8 编码中文路径 cmd 不识别 |
| 5 | **纯英文路径 `run_report.ps1` + UTF-8 BOM 编码 + 绝对路径** | ✅ 成功 |

**最终架构**：
```
任务计划程序
  └─ C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe  ← 必须用完整路径
       └─ C:\Users\HD07\run_report.ps1                          ← 纯英文路径，UTF-8 BOM
            └─ python.exe daily_report.py                       ← 绝对路径写在 ps1 里
                 └─ _Tee 类双写日志到 auto_report.log           ← 不依赖 bat 重定向
```

**关键注意事项**：
- `powershell.exe` 必须用完整路径，定时器环境的 PATH 不包含 System32
- 跳板 `.ps1` 必须用 `Out-File -Encoding UTF8` 保存（生成 UTF-8 BOM），`Set-Content -Encoding UTF8` 同理
- `Write` 工具写入的文件是 UTF-8 无 BOM，中文 Windows 的 PowerShell/cmd 会读成乱码
- `setup_task.ps1` 的时间显示用 `ToLocalTime()` 转换为北京时间，而非直接显示 UTC

## 首次拉取缓存

如果 `cache/` 目录为空，需要先拉取 Tushare 数据：

```bash
cd D:\Claudeee\highDivided_highValue_lowPrice\网格高市值高股息率\看板识股
python -c "
from app import update_tushare_cache
ok, msg = update_tushare_cache()
print(msg)
"
```

## 文件说明

| 文件 | 作用 | 提交到 GitHub |
|---|---|---|
| `app.py` | Python API 服务 + 筛选管线 | ✓ |
| `daily_report.py` | 每日收盘自动筛选 + PushPlus推送 + Pages部署 | ✓ |
| `daily_report.bat` | Windows 定时任务入口脚本 | ✓ |
| `setup_task.ps1` | 安装/更新 Windows 定时任务（管理员运行） | ✓ |
| `auto_update.py` | 自动更新辅助脚本 | ✓ |
| `dashboard.html` | 看板模板（JS 渲染，含 EMBED 数据） | ✓ |
| `index.html` | dashboard.html 副本，供本地 file:// 访问 | ✗ gitignore |
| `render.yaml` | Render 部署配置（备用） | ✓ |
| `requirements.txt` | Python 依赖 | ✓ |
| `README.md` | 项目说明 | ✓ |
| `HANDOFF.md` | 本文件 — 项目交接文档 | ✓ |
| `.env.example` | Token 配置模板 | ✓ |
| `.env` | 实际 Token（PUSHPLUS_TOKEN + TUSHARE_TOKEN） | ✗ gitignore |
| `cache/*.parquet` | Tushare 股息率原始数据 | ✗ gitignore |
| `cache/price_cache.json` | Baostock 股价 + 布林带缓存 | ✗ gitignore |

## Tushare Token

当前有效 token 保存在 `.env`：
```
TUSHARE_TOKEN=2267b4d5cb028236d04f16796221c23716d110fbece03e43926c1a90
```

免费账户限制：`daily_basic` 1次/小时，5次/天。更换 token 时修改 `.env` 即可。

## 数据源

| 字段 | 来源 |
|---|---|
| 市值 | Tushare `daily_basic` |
| 每股分红 (DPS) | Tushare `daily_basic` dv_ttm → 反推 DPS（每周更新） |
| 股息率 | **每日重算**: DPS ÷ Baostock 最新价 × 100% |
| 最新价、近1年最低 | Baostock 日线 |
| BB 布林带（周线） | Baostock 日线 → 周线重采样 → MA20±2σ |
| 买入权重 | JS 公式: 0.4×距低 + 0.4×股息 + 0.2×BB下 |

## 股息率每日重算机制

Tushare `daily_basic` 返回的 `dv_ttm`（股息率 TTM）是基于当日收盘价的。如果只缓存这个值，一周后股价变动了但股息率不变，数据就会失真。

**解决方案**（`app.py` `supplement_baostock()`）：

```
Tushare → dv_ttm × 当日收盘价 / 100 = DPS（每股分红，稳定值，每周一更新）
Baostock 每日 → latest_price
股息率 = DPS / latest_price × 100  ← 每次股价更新后自动重算
```

- DPS 只在公司公告分红时变化，一周更新一次够用
- 股息率每天跟着股价自动刷新，保证看板和日报数据的准确性

## 注意事项 & 已知限制

- **PushPlus 实名认证**：未认证账号推送内容上限 2 万字符，当前方案只推 TOP20 精简表格确保不超限
- **GitHub 连接方式**：这台机器 Git HTTPS (schannel) 间歇性 SSL 协商超时，已改用 SSH（密钥 `~/.ssh/id_ed25519`）
- **数据源限制**：efiance (eastmoney) 在这台机器被屏蔽；Tushare 免费账户有频率限制（daily_basic 1次/小时，5次/天）
- **PowerShell 编码**：`setup_task.ps1` 用英文输出来避免控制台乱码，不影响功能
- **推送看板 vs Pages 看板**：微信推送的是精简 TOP20 静态表格（浅色主题，无 JS）；GitHub Pages 托管的是完整交互看板（深色主题，含 JS 筛选/排序）

[[project-handoff-summary]]
