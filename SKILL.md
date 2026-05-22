---
name: esp32s3-skill
description: 在 Windows 上为 ESP32-S3 和 ESP-IDF 5.5.4 项目执行闭环开发调试：按用户要求修改代码、探测环境、构建、烧录、串口监视、主动发送串口调试指令，并接收设备返回日志继续分析。用于 Codex 需要围绕 ESP32-S3 形成“改代码 -> 烧录 -> 抓日志 -> 发指令 -> 收回包 -> 继续修”的自动调试流程时。
---

# ESP32-S3 Skill

这个 skill 的目标不是单次执行 `idf.py flash`，而是帮助 Codex 在 ESP32-S3 项目里完成一个可迭代的调试闭环：

1. 按用户要求修改代码
2. 检查 ESP-IDF 环境和目标端口
3. 构建并烧录
4. 捕获启动日志
5. 向串口发送调试命令或测试输入
6. 接收设备回包和后续日志
7. 根据回包继续分析和修改

优先使用 skill 自带脚本，不要每次临时拼命令。

## 闭环工作流

### 1. 先理解用户要什么

先判断用户要的是哪一类闭环：

- 只想改代码再烧录观察
- 想抓启动日志定位问题
- 想烧录后主动往串口发命令
- 想让 Codex 根据串口返回内容继续修改代码

如果用户明确要求“自动闭环调试”，优先走 `scripts/esp32s3_loop.ps1`。

### 2. 先探测，再决定动作

先运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_probe.ps1
```

确认：

- 当前目录是不是 ESP-IDF 项目
- `idf.py` 是否可用
- 当前 `IDF_TARGET`
- 当前已编译的 `BOARD_TYPE`
- 系统有哪些串口

如果 `idf.py` 不存在，就明确说明当前 shell 还没激活 ESP-IDF。

### 3. 代码修改由 Codex 本身完成

这个 skill 不负责替 Codex 生成补丁逻辑；代码修改仍由 Codex 按用户要求直接改项目文件。

skill 负责的是修改之后的执行与反馈闭环：

- build
- flash
- capture
- send
- receive
- summarize

### 4. 普通 ESP-IDF 动作

如果用户只需要单步动作，使用：

- `scripts/espidf_do.ps1`
- `scripts/serial_roundtrip.ps1`

### 5. 闭环动作

如果用户需要一整套闭环，优先使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action loop
```

它会根据参数组合完成：

- build
- flash
- 等待设备启动
- 抓启动日志
- 向串口发送一组调试命令
- 捕获响应日志
- 输出结构化结果给 Codex 继续分析

### 6. xiaozhi-esp32 多板卡仓库

如果目标工程是 `xiaozhi-esp32` 这种多板卡仓库，并且用户要求切换板型或变体，优先使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\xiaozhi_variant.ps1
```

不要静默猜测原始 `idf.py` 参数。

## 推荐脚本

### `scripts/espidf_probe.ps1`

用于探测环境、目标和端口。

### `scripts/espidf_do.ps1`

用于单步执行：

- `build`
- `flash`
- `monitor`
- `flash-monitor`
- `fullclean`
- `erase-flash`
- `merge-bin`
- `set-target`

### `scripts/serial_roundtrip.ps1`

用于串口日志闭环：

- 只抓日志
- 发送一组串口命令
- 接收设备回包
- 输出结构化 JSON

### `scripts/esp32s3_loop.ps1`

用于完整闭环：

- build + flash + capture
- flash + capture
- capture
- request
- loop

### `scripts/xiaozhi_variant.ps1`

用于调用 `xiaozhi-esp32` 仓库自带的 `scripts/release.py`。

## 典型用法

只抓启动日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action capture -SerialPort COM12
```

烧录后抓日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action flash-capture -ProjectRoot . -FlashPort COM12 -SerialPort COM12
```

烧录后发串口指令并收回包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action loop -ProjectRoot . -FlashPort COM12 -SerialPort COM12 -Commands "help","status","reboot"
```

只做串口请求往返：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\serial_roundtrip.ps1 -Action request -Port COM12 -Lines "help","status"
```

## Codex 使用原则

当用户说：

- “帮我改完后烧录看看”
- “烧进去后把启动日志抓给我”
- “给设备发几条串口指令看看返回”
- “根据串口日志继续修”

就应该触发这个 skill，并优先走闭环工作流，而不是只停在 build 或 flash。

## 失败处理

如果闭环失败，按这个顺序排查：

1. ESP-IDF 环境没激活
2. 项目根目录不对
3. target 与硬件不匹配
4. 烧录端口不对
5. 串口监听端口不对
6. 设备启动太慢，抓日志时间不够
7. 串口波特率不匹配
8. 代码已改但没有重新 build/flash

如果系统里有多个可疑串口，不要悄悄猜。先总结候选项，再说明最可能的是哪个。
