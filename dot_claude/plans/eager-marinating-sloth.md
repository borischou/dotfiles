# Plan: Pipeline 运行历史汇总表格

## Context

每次 Pipeline 运行（搜索+发消息）完成后，结果散落在终端输出和 Excel 报告中，无法快速纵览历史。需要一个 **Markdown 汇总文档** 自动追加每次运行结果，方便随时查看。

## 方案

在 `generate_pipeline_report()` 旁边新增一个函数 `save_run_history()`，Pipeline 完成时调用。产出两个文件：

| 文件 | 用途 |
|------|------|
| `data/run_history.json` | JSON 数组，每次追加一条记录，程序可读 |
| `data/run_history.md` | Markdown 表格，每次从 JSON 重新生成，人类可读 |

两个文件都在 `data/` 下，**已被 `.gitignore` 覆盖**，无需额外修改。

## MD 表格格式

```markdown
# Pipeline 运行历史

| 时间 | 关键词 | 模板 | 模式 | 搜索数 | 发送 | 失败 | 跳过 | 限流 | 报告 |
|------|--------|------|------|--------|------|------|------|------|------|
| 2026-02-28 14:30 | 前端, 后端 | greeting | search_center | 45 | 30 | 2 | 10 | 3 | pipeline_20260228_143000.xlsx |
```

Dry run 的记录也保存，发送列显示 `-`（仅搜索无发送）。

## 修改文件

### 1. `src/services/pipeline.py` — 新增函数 + 调用

**新增 `save_run_history()` 函数**（放在 `generate_pipeline_report()` 后面）：
- 参数：keywords, template, mode, results, dry_run, report_path(可选)
- 读取现有 `data/run_history.json`（不存在则初始化为空数组）
- 追加本次记录（时间戳、参数、结果数据）
- 写回 JSON
- 从完整 JSON 重新生成 `data/run_history.md`

**在以下两处调用 `save_run_history()`：**
- `run_pipeline_default()` — 474 行 `generate_pipeline_report()` 之后（以及 dry_run 分支）
- `run_pipeline_batched()` — 629 行 `generate_pipeline_report()` 之后（以及 dry_run 完成时）

### JSON 记录结构

```json
{
  "timestamp": "2026-02-28T14:30:00",
  "keywords": ["前端", "后端"],
  "template": "greeting",
  "mode": "search_center",
  "dry_run": false,
  "total": 45,
  "sent": 30,
  "failed": 2,
  "skipped": 10,
  "rate_limited": 3,
  "report_file": "pipeline_20260228_143000.xlsx"
}
```

## 验证

```bash
# 跑一次 dry-run pipeline，检查文件生成
python src/cli/main.py pipeline -k "测试" -t greeting --dry-run

# 确认文件产出
cat data/run_history.md
cat data/run_history.json
```
