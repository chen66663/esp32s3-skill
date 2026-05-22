# xiaozhi 仓库专用说明

当前仓库是多板卡 ESP-IDF 项目，不是单板简单工程。

## 重点文件

- `scripts/release.py`：板型和变体的核心入口
- `sdkconfig`：当前 target
- `build/compile_commands.json`：当前已编译板型
- `main/idf_component.yml`：组件和最低 IDF 版本要求

## 当前仓库已知特点

- 当前项目支持很多板卡目录，在 `main/boards/`
- 当前工程已知有 ESP32-S3 目标
- `release.py` 会处理板型附加配置，不适合用简单裸 `idf.py` 完全替代

## 实际决策

如果用户只是想对“当前已经准备好的工作区”执行编译、烧录、看日志，直接使用普通 `idf.py`。

如果用户想切换板型、变体、重建该板型的配置状态，优先使用：

```powershell
python scripts/release.py <board> --name <variant>
```

也就是通过 skill 中的 `scripts/xiaozhi_variant.ps1` 调用。
