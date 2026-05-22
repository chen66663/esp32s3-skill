# ESP-IDF 5.5.4 通用工作流

适用环境：

- Windows PowerShell
- ESP-IDF 5.5.4
- ESP32-S3 为主，也兼容一般 ESP32 系列

## 先做的事

先确认：

- `IDF_PATH` 是否存在
- `idf.py` 是否可执行
- Python 是否可执行
- 当前目录是不是 ESP-IDF 项目根目录

如果这些条件都不满足，不要继续往下烧录。

## 常用动作对应关系

- 编译：`idf.py build`
- 烧录：`idf.py -p COMx flash`
- 日志：`idf.py -p COMx monitor`
- 烧录加日志：`idf.py -p COMx flash monitor`
- 导出单文件镜像：`idf.py merge-bin`

## Target 规则

`idf.py set-target` 会影响构建状态和配置，不要轻易调用。

只有在这些情况才考虑：

- 用户明确要求切换 target
- 仓库自己的构建脚本要求重新设 target

## ESP32-S3 特别说明

ESP32-S3 可能通过以下方式暴露：

- USB 转串口
- 原生 USB CDC
- USB Serial/JTAG

不要默认系统里第一个 `COM` 口就是烧录口。优先结合设备名和上下文判断。

## 调试顺序

1. 先 `monitor`
2. 再看 panic 和 reset 日志
3. 有明确线索时再考虑 GDB stub
4. 真正需要断点才使用 OpenOCD + GDB
