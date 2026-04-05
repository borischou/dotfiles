---
name: sayhi-boli-andr
description: >-
  Boss直聘推荐页批量打招呼（Boli 固定条件）：Android 高级开发工程师岗位、北京、8 年以内、35 岁以下、本科及以上、互联网大厂关键词；不放宽参数。在用户提及 sayhi-boli-andr、/sayhi-boli-andr、Boli Android 推荐打招呼或同等意图时执行本流程。
---

# sayhi-boli-andr（/sayhi-boli-andr）

在 **boss-assistant** 仓库中，用推荐路径脚本按**固定收紧条件**跑批量打招呼；**不使用** `--no-bigco`、`--no-beijing`、`--no-edu`，也**不**增大 `--max-age` / `--max-years`。

## 固定条件（与脚本默认值一致时再显式写出）

| 维度 | 要求 |
|------|------|
| 路径 | Boss **推荐牛人**页，`scripts/batch_greet.py` |
| 职位 | **Android高级开发工程师**（与网页下拉一致） |
| Base | 期望/卡片信息含 **北京**（`require_beijing`，无 `--no-beijing`） |
| 年限 | **≤8 年**（`--max-years 8`） |
| 年龄 | **≤35 岁**（默认 `--max-age 35`，可省略） |
| 学历 | **本科及以上**（默认，无 `--no-edu`） |
| 公司 | **大厂关键词**命中（默认，无 `--no-bigco`） |

## 执行前（人工）

1. Chrome 以 CDP 启动（默认 `http://127.0.0.1:9222`），已登录 Boss直聘。
2. 打开 `https://www.zhipin.com/web/chat/recommend`，在侧栏/筛选项中尽量对齐：**北京、Android 岗、经验与年龄等与上表一致**（脚本仍会在卡片上再筛一层）。

## 命令（项目根目录）

工作区路径按实际替换（示例：`/Users/zhouboli/Documents/boss-assistant`）：

```bash
cd /Users/zhouboli/Documents/boss-assistant && python3 scripts/batch_greet.py \
  --max-years 8 \
  --max-age 35 \
  --job-name "Android高级开发工程师"
```

说明：`--max-age 35` 与脚本默认相同，仅为可读性保留；可删。

## `--job-value`

脚本内建默认 `DEFAULT_JOB_VALUE` 若与当前账号职位不一致，需从网页职位下拉 `li.job-item` 的 `value` 复制后加上：

```bash
python3 scripts/batch_greet.py \
  --job-value "粘贴的value" \
  --max-years 8 \
  --max-age 35 \
  --job-name "Android高级开发工程师"
```

## Agent 行为

- 在用户触发本 skill 时：**直接执行**上述命令（确认 CDP 可达后），或将完整命令交给用户在已就绪环境中运行。
- **禁止**为本 skill 主动添加 `--no-bigco`、`--no-beijing`、`--no-edu` 或放宽年限/年龄，除非用户**另行**明确要求放宽。
- 结果 JSON 默认写在 `data/greet_results/greet_*.json`；日志可重定向到文件便于排查。

## 关联

- 预检可用项目 skill：`preflight`（Chrome / 登录）。
- 实现细节与筛选逻辑见 boss-assistant 仓库内 `scripts/batch_greet.py`。
