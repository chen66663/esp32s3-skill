# esp32s3-skill

一个面向 `ESP32-S3 + ESP-IDF 5.5.4 + Windows PowerShell` 的 Codex skill 初版。

它用于帮助 Codex 在本地 ESP-IDF 工程中完成这些工作：

- 探测 ESP-IDF 环境
- 识别串口和 USB Serial/JTAG
- 执行 `idf.py build`
- 执行 `idf.py flash`
- 打开 `monitor`
- 生成 `merged binary`
- 在 `xiaozhi-esp32` 这类多板卡仓库里切换板型和变体

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

## 说明

- `SKILL.md`：skill 主说明和触发规则
- `agents/openai.yaml`：UI 元信息
- `scripts/`：可直接执行的 PowerShell 脚本
- `references/`：辅助参考文档

## 当前定位

这是一个可用的初版，重点先把“探测、构建、烧录、日志、板型切换”这一条链路打通。

后续还可以继续增强：

- 自动选择最可能的串口
- 一键 `build + flash + monitor`
- 更完整的 OpenOCD / GDB 调试支持
- 针对特定 ESP32-S3 开发板的默认参数模板
