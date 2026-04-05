---
name: sayhi-ganlin-data
description: 运行甘霖模板的数据分析/数据治理等人才银行打招呼流水线（固定10个关键词）。当用户提到“甘霖数据分析打招呼”“继续跑甘霖数据”“sayhi-ganlin-data”时使用。
---

# Say Hi Ganlin Data

用于 `maimai-assistant` 项目的固定打招呼流程：`ganlin` 模板 + 人才银行数据向关键词。

## 固定参数

- 模式：`talent_bank`
- 模板：`ganlin`
- 页数：`-p 2`
- 自动确认：`-y`
- 补交换：`--exchange-backfill-hours 168`
- 关键词（固定 10 个）：
  - `指标平台`
  - `数据中台`
  - `BI`
  - `增长分析`
  - `数据分析`
  - `数据治理`
  - `数仓`
  - `商业分析`
  - `指标体系`
  - `数据仓库`

## 执行步骤

1. 先做最小预检：
   - `curl -s -o /dev/null -w "%{http_code}" http://localhost:9222/json/version`
   - 结果不是 `200` 则停止，并提示先启动 Chrome CDP。
2. 在项目根目录执行命令（优先 `venv/bin/python`）：

```bash
PY="$(test -x venv/bin/python && echo venv/bin/python || command -v python3)"
"$PY" src/cli/main.py pipeline \
  -m talent_bank \
  -k "指标平台" -k "数据中台" -k "BI" -k "增长分析" \
  -k "数据分析" -k "数据治理" -k "数仓" -k "商业分析" \
  -k "指标体系" -k "数据仓库" \
  -t ganlin \
  -p 2 \
  --exchange-backfill-hours 168 \
  -y
```

3. 若命令超时，允许继续后台运行并提示用户“任务已在后台执行”，并记下完整日志路径供事后汇总。

4. **执行结束后汇总报告（必填）**  
   - 完整格式、日志 grep 指引与落盘路径见：本目录下 `sayhi-report-template.md`（与 `~/.claude/skills/sayhi-ganlin-data/sayhi-report-template.md` 同步）；若在 `maimai-assistant` 仓库内执行，亦可使用仓库内 `.cursor/skills/sayhi-report-template.md`。  
   - 任务结束（或用户追问结果）后：根据**当次**完整日志填写模板 **§1–§7**，在对话中输出完整 Markdown；并将**同一份**内容写入  
     `data/reports/sayhi_summary_sayhi-ganlin-data_<YYYYMMDD_HHMMSS>.md`。  
   - 必须覆盖：**多关键词表**（10 个词各自的计划发送 vs 实际发送，据 `Will send` / `message sent inline` / `Sending messages ... 0/N` / 小时限流行核对）、`Pipeline report saved` 路径、**补交换**收尾统计（`补交换完成` / `Exchange backfill skipped`）、限流与建议。

## 注意

- 不使用 `--resume`（除非 checkpoint 明确是同一组参数）。
- 若检测到当前任务已在运行，不重复启动，改为回传现有进度。
