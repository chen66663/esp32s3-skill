# esp32s3-skill

一个面向 `ESP32-S3 + ESP-IDF 5.5.4 + Windows PowerShell` 的 Codex skill。

它的目标不是只会执行一条 `idf.py flash`，而是让 Codex 能比较稳地完成整条链路：

- 检查 ESP-IDF 环境
- 识别串口和 USB Serial/JTAG
- 执行 `idf.py build`
- 执行 `idf.py flash`
- 打开 `monitor`
- 生成 `merged binary`
- 在 `xiaozhi-esp32` 这类多板卡仓库中切换板型和变体

## 目录结构

```text
.
├─ SKILL.md
├─ agents/
│  └─ openai.yaml
├─ scripts/
│  ├─ espidf_do.ps1
│  ├─ espidf_probe.ps1
│  ├─ list_serial_ports.ps1
│  └─ xiaozhi_variant.ps1
└─ references/
   ├─ espidf-workflow.md
   └─ xiaozhi-repo-notes.md
```

## 这个 skill 能做什么

### 通用 ESP-IDF 动作

- 探测当前工程是不是 ESP-IDF 项目
- 识别当前 `IDF_TARGET`
- 识别当前已编译的 `BOARD_TYPE`
- 执行构建、烧录、日志监视、清理、导出单文件镜像

### ESP32-S3 专项支持

- 优先面向 ESP32-S3 工作流设计
- 识别 USB Serial/JTAG 场景
- 避免在 target、端口、构建状态不明时盲目烧录

### xiaozhi 仓库专项支持

- 调用仓库自带的 `scripts/release.py`
- 列出板型和变体
- 按板型和变体重新构建

## Codex 如何使用这个 skill

### 1. 放到 Codex 可发现的位置

如果你是把这个仓库当成 skill 源码仓库维护，实际使用时需要把它放到 Codex 能发现的位置，例如：

- `C:\Users\你的用户名\.codex\skills\esp32s3-skill`

或者把这个仓库 clone 到本地后，再复制整个目录进去。

### 2. 在对话里显式调用

最稳妥的方式是在提示词里直接写出 skill 名：

```text
使用 $esp32s3-skill 帮我探测当前 ESP-IDF 工程环境。
```

```text
使用 $esp32s3-skill 帮我查一下这个 ESP32-S3 现在该走哪个串口烧录。
```

```text
使用 $esp32s3-skill 在当前工程里 build、flash，并打开 monitor。
```

```text
使用 $esp32s3-skill 列出 xiaozhi 仓库支持的板型和变体。
```

```text
使用 $esp32s3-skill 帮我把 bread-compact-wifi 这个变体重新构建出来。
```

### 3. Codex 触发后的典型动作

Codex 触发这个 skill 后，通常会按下面顺序工作：

1. 先运行 `scripts/espidf_probe.ps1`
2. 判断当前 shell 是否有 `idf.py`
3. 判断当前工程是不是 ESP-IDF 项目
4. 判断当前 `IDF_TARGET`、端口、板型状态
5. 再决定是直接 `idf.py build/flash/monitor`，还是先走 `scripts/release.py`

### 4. 推荐你给 Codex 的说法

下面这些提示词最容易让 skill 发挥正常：

- “使用 $esp32s3-skill 检查我当前 ESP-IDF 环境有没有配好。”
- “使用 $esp32s3-skill 探测当前工程和串口，然后帮我烧录。”
- “使用 $esp32s3-skill 看看这个工程当前编译的是哪个板型。”
- “使用 $esp32s3-skill 调用 xiaozhi 的 release.py，把某个变体构建出来。”

## 脚本说明

### `scripts/espidf_probe.ps1`

用于探测：

- 当前目录是否为 ESP-IDF 项目
- `IDF_PATH`、`idf.py`、`python`、`openocd`
- `sdkconfig` 中的 `IDF_TARGET`
- `build/compile_commands.json` 中的 `BOARD_TYPE`
- 当前系统串口

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

### `scripts/xiaozhi_variant.ps1`

用于调用 `xiaozhi-esp32` 仓库里的 `scripts/release.py`：

- 列出板型和变体
- 按板型和变体构建

### `scripts/list_serial_ports.ps1`

用于列出 Windows 下当前串口设备。

## 示例命令

探测工程：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_probe.ps1
```

构建：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_do.ps1 -Action build
```

烧录：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_do.ps1 -Action flash -Port COM12
```

烧录并打开日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\espidf_do.ps1 -Action flash-monitor -Port COM12
```

列出 xiaozhi 变体：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\xiaozhi_variant.ps1 -Action list
```

构建指定变体：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\xiaozhi_variant.ps1 -Action build -Board bread-compact-wifi -Name bread-compact-wifi
```

## 当前定位

这是一个可用的初版，重点先把“探测、构建、烧录、日志、板型切换”这一条链路打通。

后续还可以继续增强：

- 自动选择最可能的串口
- 一键 `build + flash + monitor`
- 更完整的 OpenOCD / GDB 调试支持
- 针对特定 ESP32-S3 开发板的默认参数模板
