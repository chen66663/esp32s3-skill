---
name: esp32s3-skill
description: 在 Windows 上为 ESP32-S3 和 ESP-IDF 5.5.4 项目执行探测、构建、烧录、串口监视和基础调试。用于 Codex 需要识别 ESP-IDF 工程、查找 ESP32-S3 串口或 USB Serial/JTAG、执行 idf.py、生成 merged binary，或在 xiaozhi-esp32 这类多板卡仓库中切换板型与变体并安全烧录时。
---

# ESP32-S3 Skill

用这个 skill 处理 ESP32-S3 开发时最常见也最容易出错的环节：环境探测、端口识别、构建、烧录、日志观察，以及 `xiaozhi-esp32` 这种多板卡仓库里的板型变体切换。

优先使用随 skill 附带的脚本，不要每次临时拼接命令。整体原则是先确认环境和端口，再执行最小动作，最后再按需要进入 monitor 或更重的调试流程。

## 快速开始

1. 先确认当前目录是不是 ESP-IDF 项目根目录。
2. 运行 `scripts/espidf_probe.ps1` 探测：
   - `IDF_PATH`
   - `idf.py`
   - `python`
   - `openocd`
   - 当前 `sdkconfig` 对应的 `IDF_TARGET`
   - 当前 `build/compile_commands.json` 对应的 `BOARD_TYPE`
   - 系统中的串口和 USB Serial/JTAG 设备
3. 普通单工程操作用 `scripts/espidf_do.ps1`。
4. 如果是当前这个 `xiaozhi-esp32` 多板卡仓库，需要切板型或变体时，优先用 `scripts/xiaozhi_variant.ps1`。
5. 遇到仓库特有逻辑时，阅读 [references/xiaozhi-repo-notes.md](references/xiaozhi-repo-notes.md)。

## 工作流

### 1. 先探测，再执行

除非当前对话已经明确下面信息，否则先探测：

- 项目根目录
- 当前 `IDF_TARGET`
- 设备端口
- 当前已编译的板型
- shell 是否已激活 ESP-IDF

如果 `idf.py` 不存在，直接说明当前 shell 不是 ESP-IDF 已激活环境，不要继续烧录。

### 2. 选择最小可行动作

优先顺序如下：

- 用户要编译：`build`
- 用户要烧录：`flash`
- 用户要烧录并立刻看日志：`flash-monitor`
- 用户只看日志：`monitor`
- 用户要单文件镜像：`merge-bin`
- 用户要清空 flash：`erase-flash`
- 用户怀疑构建状态脏了：`fullclean`

不要无缘无故执行 `set-target`。它会影响 `sdkconfig` 和当前 build 状态。

### 3. 普通 ESP-IDF 项目

对普通单工程 ESP-IDF 项目，优先用 `idf.py`：

- `idf.py build`
- `idf.py -p COMx flash`
- `idf.py -p COMx monitor`
- `idf.py -p COMx flash monitor`
- `idf.py merge-bin`

### 4. xiaozhi-esp32 多板卡仓库

这个仓库不是简单单板工程，它会根据板型、变体、target 注入不同配置。

当用户要求：

- 切换板型
- 切换变体
- 为某个板型重新生成构建状态

优先使用 `scripts/release.py`，通过 `scripts/xiaozhi_variant.ps1` 调用，而不是自己静默猜测原始 `idf.py` 参数。

### 5. 烧录后观察

烧录成功后，除非用户只要构建产物，否则优先进入 `monitor`。

启动 `monitor` 前，要说明它是交互式、长连接命令。

### 6. 调试升级路径

调试按这个顺序升级：

1. `build + flash + monitor`
2. 查看 panic 和重启日志
3. 有明确线索时再考虑 GDB stub
4. 真要断点调试时再上 OpenOCD + GDB

ESP32-S3 可能通过 USB Serial/JTAG 同时提供控制台和 JTAG 功能，不要默认它一定走 UART。

## 常用命令

探测：

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

列出 xiaozhi 支持的板型与变体：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\xiaozhi_variant.ps1 -Action list
```

为某个板型和变体重新构建：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\xiaozhi_variant.ps1 -Action build -Board bread-compact-wifi -Name bread-compact-wifi
```

## 失败处理

如果失败，按这个顺序排查：

1. 当前 shell 不是 ESP-IDF shell
2. 项目根目录不对
3. `COM` 口不对或被占用
4. target 与硬件不匹配
5. 线材、驱动、供电问题
6. bootloader 进入失败
7. `set-target`、旧 `build`、旧 `sdkconfig` 导致状态漂移

如果系统里有多个可疑端口，不要悄悄猜。先总结候选项，再说明最可能的是哪一个。

## 文件说明

- `scripts/list_serial_ports.ps1`：列出系统串口
- `scripts/espidf_probe.ps1`：探测环境、工程状态、当前板型
- `scripts/espidf_do.ps1`：执行普通 ESP-IDF 动作
- `scripts/xiaozhi_variant.ps1`：调用仓库自带 `scripts/release.py`
- `references/espidf-workflow.md`：ESP-IDF 5.5.4 通用工作流
- `references/xiaozhi-repo-notes.md`：当前仓库的多板卡规则
