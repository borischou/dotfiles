---
description: 运行甘霖模板的数据向打招呼 pipeline（talent_bank + 固定10关键词）
argument-hint: [--pages=2] [--backfill-hours=168]
---

# Command: /sayhi-ganlin-data

执行 `maimai-assistant` 的甘霖数据向打招呼任务。

## 默认行为

1. 读取并遵循技能：`~/.claude/skills/sayhi-ganlin-data/SKILL.md`
2. 使用固定关键词和默认参数执行 pipeline：
   - `--pages` 默认 `2`
   - `--backfill-hours` 默认 `168`
3. 先做 CDP 预检（`9222`），通过后再开跑。
4. 如任务进入后台，持续回报进度。

## 参数覆盖

- `--pages=N`：覆盖默认 `-p 2`
- `--backfill-hours=N`：覆盖默认 `--exchange-backfill-hours 168`

## 执行命令模板

```bash
PY="$(test -x venv/bin/python && echo venv/bin/python || command -v python3)"
"$PY" src/cli/main.py pipeline \
  -m talent_bank \
  -k "指标平台" -k "数据中台" -k "BI" -k "增长分析" \
  -k "数据分析" -k "数据治理" -k "数仓" -k "商业分析" \
  -k "指标体系" -k "数据仓库" \
  -t ganlin \
  -p <PAGES> \
  --exchange-backfill-hours <BACKFILL_HOURS> \
  -y
```
