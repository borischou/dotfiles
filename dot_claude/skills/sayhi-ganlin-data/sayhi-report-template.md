# Sayhi 系列执行汇总报告（模板）

执行任意 `/sayhi-*` 流水线（本仓库 CLI 或 `scripts/daily_pipeline.sh`）结束后，**必须**按本节生成汇报：  
1）在对话中输出完整汇总（Markdown）；2）将**同一份**内容写入项目根下文件：

`data/reports/sayhi_summary_<skill名>_<YYYYMMDD_HHMMSS>.md`

（若 `data/reports` 不存在则先创建。）

---

## 1. 元信息

- **Skill / 任务**：`<sayhi-boli-andr | sayhi-ganlin-data | …>`
- **执行时间**（完成时刻）：`<本地时间 ISO 或可读时间>`
- **项目根**：`<绝对路径>`
- **预检**：CDP 是否可达（写明检查的 URL 与 HTTP 码或 curl 是否成功）

---

## 2. 执行方式

- **前台 / 后台**、若后台则 **PID**、**完整日志路径**（如 `/tmp/...`、`data/daily/pipeline_*.log`）
- **退出码**（若可得）
- **是否与已有 pipeline 冲突**（若检测到已在跑则写「未重复启动」及如何查看进度）

---

## 3. 产出文件

| 类型 | 路径（尽量绝对路径） |
|------|----------------------|
| Pipeline Excel | 从日志提取 `Pipeline report saved to:` / `pipeline_*.xlsx` |
| 数据库备份 | 若日志含「数据库已自动备份」则抄录文件名 |
| 本汇总 Markdown | `data/reports/sayhi_summary_*.md`（本条） |

---

## 4. 发送与限流（从日志统计）

在**本次任务完整日志**上执行（将 `LOG` 换成实际路径）：

```bash
# 通用：报表路径、小时限流、ERROR
grep -E 'Pipeline report saved|Hourly rate limit exceeded|Rate limit hit|ERROR|失败' "$LOG" | tail -50

# 招聘管理 / sayhi-boli（单关键词）：Summary 与发送
grep -E 'Pipeline report saved|Will send to|Hourly rate limit|message sent|Pipeline Summary' "$LOG" | tail -40

# 人才银行多关键词：进度条、逐条发送成功
grep -E '^\[[0-9]+/[0-9]+\]|Talent bank: message sent inline|Sending messages \(talent bank\)' "$LOG" | tail -80

# 甘霖数据向：补交换收尾
grep -E '补交换|Exchange backfill skipped|补交换完成' "$LOG" | tail -30
```

根据 grep 结果填写：

- **日志中 `message sent inline`（或等价成功发送）条数**：`<N>`（若可统计）
- **是否触发每小时上限**（如 `Hourly rate limit exceeded for send_message. Limit: 30/hour`）：是/否，若是有无「后续关键词 0 发送」
- **其它限流**（Minimum interval、exchange 等）：摘要列表

---

## 5. 多关键词任务：按词汇总表（仅当本任务含多个 `-k` / 多轮 `[i/N]`）

| 轮次 | 关键词 / 标识 | 计划发送（Summary 中 Will send） | 实际发送（日志可核对） | 备注 |
|------|-----------------|-----------------------------------|-------------------------|------|
| … | … | … | … | 限流 / 跳过 |

单关键词任务（如 boli 安卓）可改为**两行结论**：计划人数、实际发送、是否限流。

---

## 6. 补交换（仅当命令行含 `--exchange-backfill-hours` 等）

- 日志收尾行「补交换完成: 成功尝试 X | 失败/跳过 Y」或等价统计
- 若大量 `Exchange backfill skipped (rate limit)`，在「建议」中说明需错峰或调配置

---

## 7. 结论与建议

- **一句话结论**（例如：10 词搜索跑完，但第 4～10 词因小时配额未发送）
- **建议**（可选）：等待下一小时、调高限流配置、分批跑、`--resume` 条件等

---

## 8. 写入文件

将**以上各节填满**后的 Markdown **原样**写入：

`data/reports/sayhi_summary_<skill名>_<YYYYMMDD_HHMMSS>.md`

对话中的最终回复应包含该汇总（可与文件内容一致，避免只说「已写入」而不展示要点）。
