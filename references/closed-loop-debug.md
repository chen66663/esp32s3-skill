# 闭环调试说明

这个 skill 的核心目标是让 Codex 能形成下面这条闭环：

1. 修改代码
2. 构建
3. 烧录
4. 抓设备启动日志
5. 向串口发送调试命令
6. 接收设备返回信息
7. 继续分析并修改

## 什么时候应该走闭环

当用户要求：

- “改完烧进去看看”
- “把串口日志抓回来分析”
- “给设备发几条命令试试”
- “根据串口返回继续修”

优先使用 `scripts/esp32s3_loop.ps1`。

## 关键脚本分工

- `espidf_probe.ps1`：环境和端口探测
- `espidf_do.ps1`：单步 `idf.py` 动作
- `serial_roundtrip.ps1`：串口抓取和请求往返
- `esp32s3_loop.ps1`：串起完整闭环

## 输出约定

闭环脚本应尽量输出 JSON，方便 Codex 在 shell 输出里继续读取和分析。

重点字段：

- `boot_capture`
- `request_result`
- `initial_output`
- `response_output`
- `combined_output`
