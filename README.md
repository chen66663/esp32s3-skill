# esp32s3-skill

一个面向 `ESP32-S3 + ESP-IDF 5.5.4 + Windows PowerShell` 的 Codex skill。

这不是一个只会执行 `idf.py flash` 的 skill，而是一个偏“闭环调试”的 skill。它希望帮助 Codex 完成这样的流程：

```text
用户提出要求
-> Codex 修改代码
-> build
-> flash
-> 抓启动日志
-> 向串口发送调试命令
-> 接收设备返回内容
-> Codex 继续分析并再次修改
```

## 能力范围

- 探测 ESP-IDF 环境
- 识别串口和 USB Serial/JTAG
- 执行 `idf.py build`
- 执行 `idf.py flash`
- 打开 `monitor`
- 生成 `merged binary`
- 串口发送调试命令
- 串口接收设备回包
- 输出结构化调试结果给 Codex 继续分析
- 支持 `xiaozhi-esp32` 这类多板卡仓库的板型/变体构建

## 目录结构

```text
.
├─ SKILL.md
├─ agents/
│  └─ openai.yaml
├─ scripts/
│  ├─ esp32s3_loop.ps1
│  ├─ espidf_do.ps1
│  ├─ espidf_probe.ps1
│  ├─ list_serial_ports.ps1
│  ├─ serial_roundtrip.ps1
│  └─ xiaozhi_variant.ps1
└─ references/
   ├─ closed-loop-debug.md
   ├─ espidf-workflow.md
   └─ xiaozhi-repo-notes.md
```

## Codex 如何使用这个 skill

### 1. 放到 Codex 可发现的位置

通常放到：

- `C:\Users\你的用户名\.codex\skills\esp32s3-skill`

### 2. 在对话中显式调用

建议你直接在提示词里写 `$esp32s3-skill`。

例如：

```text
使用 $esp32s3-skill 帮我检查这个 ESP-IDF 工程能不能正常烧录。
```

```text
使用 $esp32s3-skill 修改这个功能，然后烧录到 ESP32-S3，抓启动日志给我。
```

```text
使用 $esp32s3-skill 烧录后，往串口发送 help、status，把设备返回内容收回来继续分析。
```

```text
使用 $esp32s3-skill 帮我做一个闭环调试：改代码、烧录、抓日志、串口发命令、继续修。
```

### 3. Codex 使用这个 skill 时应该怎么做

Codex 触发后，推荐按这个顺序工作：

1. 先改代码
2. 再运行 `scripts/espidf_probe.ps1`
3. 再决定用普通动作还是闭环动作
4. 如果只是编译/烧录，用 `scripts/espidf_do.ps1`
5. 如果要发串口命令和收回包，用 `scripts/serial_roundtrip.ps1`
6. 如果要完整闭环，用 `scripts/esp32s3_loop.ps1`
7. 根据脚本输出的日志和 JSON 结果继续分析

## 核心脚本

### `scripts/espidf_probe.ps1`

用于探测：

- 当前目录是否为 ESP-IDF 项目
- `IDF_PATH`、`idf.py`、`python`、`openocd`
- 当前 `IDF_TARGET`
- 当前 `BOARD_TYPE`
- 系统串口列表

### `scripts/espidf_do.ps1`

用于执行普通 ESP-IDF 动作：

- `build`
- `flash`
- `monitor`
- `flash-monitor`
- `fullclean`
- `erase-flash`
- `merge-bin`
- `set-target`

### `scripts/serial_roundtrip.ps1`

用于串口收发闭环：

- `capture`：只抓串口日志
- `request`：发送一组串口命令并接收响应

输出是结构化 JSON，方便 Codex 继续分析。

### `scripts/esp32s3_loop.ps1`

用于完整闭环：

- `build-flash-capture`
- `flash-capture`
- `capture`
- `request`
- `loop`

`loop` 是最接近你要的“闭环调试”动作。

### `scripts/xiaozhi_variant.ps1`

用于调用 `xiaozhi-esp32` 的 `scripts/release.py`：

- 列出板型和变体
- 构建指定板型和变体

## 示例命令

探测工程：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_probe.ps1
```

只抓启动日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\serial_roundtrip.ps1 -Action capture -Port COM12
```

向串口发送命令并收响应：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\serial_roundtrip.ps1 -Action request -Port COM12 -Lines "help","status"
```

烧录并抓启动日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action flash-capture -ProjectRoot . -FlashPort COM12 -SerialPort COM12
```

闭环调试：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\esp32s3_loop.ps1 -Action loop -ProjectRoot . -FlashPort COM12 -SerialPort COM12 -Commands "help","status","version"
```

## 当前定位

这是一个围绕“自动调试闭环”设计的初版。

下一步还可以继续增强：

- 自动挑选最可能的串口
- 自动识别启动波特率
- 自动保存本轮日志到文件
- 自动比较前后两次日志差异
- 针对常见调试命令生成模板
