# 重构：合并三个 send_message_batch 函数

## Context

`src/modules/message.py` 中三个批量发送函数（`send_message_batch` / `_enterprise` / `_talent_bank`）共 ~760 行，其中 ~70% 是完全重复的编排逻辑（过滤→预览→确认→循环发送→统计）。唯一差异是单个候选人的发送方式。提取公共编排 + 回调模式可消除 ~430 行重复代码。

## 架构设计

```
公共编排 _send_message_batch_common()
  ├── 初始化 (config/rate_limiter/db_manager/template)
  ├── 过滤已沟通
  ├── 可选模板预校验
  ├── 预览面板 + 确认
  └── 循环:
       ├── 限流检查
       ├── 构建变量 + 渲染模板
       ├── result = await send_one(candidate, content)  ← 回调
       ├── 记录结果 (abort_batch → break)
       ├── 进度条 + emit_progress
       └── 随机延迟

三个回调工厂:
  _make_search_center_sender()  → 重试+超时+send_message()
  _make_enterprise_sender()     → 滚动+inline发送+DB记录
  _make_talent_bank_sender()    → 滚动+DOM找按钮+inline发送+交换+DB记录
```

## 实现步骤

### Step 1: 添加数据类型

**文件**: `src/modules/message.py` (imports 区域后)

添加 `CandidateSendResult` dataclass:
```python
@dataclass
class CandidateSendResult:
    success: bool
    status: str       # 'sent', 'failed', 'quota_exhausted', 'rate_limited'
    reason: str = ""
    attempts: int = 1
    content: str = ""
    abort_batch: bool = False  # True → 停止剩余候选人
```

添加 `BatchConfig` dataclass:
```python
@dataclass
class BatchConfig:
    mode_label: str           # "" / "Enterprise Inline" / "Talent Bank Inline"
    panel_title: str          # Rich Panel 标题
    progress_description: str # 进度条描述
    pre_validate: bool = False
    emit_web_progress: bool = False
```

### Step 2: 编写 `_send_message_batch_common()` (~120行)

**文件**: `src/modules/message.py`，放在现有 `send_message_batch()` 之前

提取公共逻辑：
1. 加载 template + 初始化 results dict
2. 批量查 DB 过滤已沟通候选人
3. 空列表检查
4. `pre_validate=True` 时全量预校验模板变量
5. 构建预览面板（`mode_label` 非空时显示 Mode 行）
6. 确认弹窗（`skip_confirmation` 跳过）
7. Rich Progress 循环：
   - `async_check_rate_limit()` → `RateLimitExceededError` 则 break
   - 构建 per-candidate variables + `render_template()`（catch ValidationError 标记 failed）
   - `result = await send_one(candidate, content)`
   - 根据 `result.status` 更新 results dict
   - `result.abort_batch=True` → 计算 remaining rate_limited + break
   - `progress.advance()` + 可选 `emit_progress()` + `async_random_delay()`

### Step 3: 编写三个回调工厂

**文件**: `src/modules/message.py`

#### `_make_search_center_sender(browser, template_name, interactive, discovered_selectors)` (~60行)
- 内含重试循环（max_retries=2, 指数退避）
- `asyncio.wait_for(send_message(...), timeout=90)`
- 异常处理：QuotaExhaustedError/RateLimitExceededError → `abort_batch=True`，PermanentFailureError/TimeoutError → fail 不重试
- 返回 `CandidateSendResult(attempts=...)`

#### `_make_enterprise_sender(page, config, rate_limiter, db_manager, template_name)` (~35行)
- 滚动到候选人卡片
- `send_message_enterprise_inline(page, content, config)`
- 成功时 `rate_limiter.log_action()` + `_log_message()`
- 返回 `CandidateSendResult`

#### `_make_talent_bank_sender(page, browser, config, rate_limiter, db_manager, template_name, exchange_phone, exchange_wechat)` (~50行)
- 滚动 + `page.evaluate_handle()` DOM 遍历找 "立即沟通" 按钮
- `send_message_talent_bank_inline(..., chat_btn_handle=...)`
- 成功时 `rate_limiter.log_action()` + `_log_message()`
- 返回 `CandidateSendResult`

### Step 4: 重写三个公共函数为薄包装

三个公共函数**签名不变**，body 缩减为 ~15 行：
- 构建 `BatchConfig`
- 调用工厂创建 `send_one`
- 调用 `_send_message_batch_common()`

### Step 5: 合并 pipeline.py 三个 wrapper

**文件**: `src/services/pipeline.py`

将 `send_batch()` / `send_batch_enterprise()` / `send_batch_talent_bank()` 合并为一个：
```python
async def send_batch(candidates, template, variables, search_keywords, browser,
                     skip_messaged, mode=SearchMode.SEARCH_CENTER, **kwargs) -> dict:
    sorted_candidates = sort_candidates_by_score(candidates, search_keywords)
    dicts = _candidates_to_dicts(sorted_candidates)
    if mode == SearchMode.ENTERPRISE:
        return await send_message_batch_enterprise(page=browser.page, ...)
    elif mode == SearchMode.TALENT_BANK:
        return await send_message_batch_talent_bank(page=browser.page, ...)
    else:
        return await send_message_batch(candidates=dicts, ...)
```

更新 `run_pipeline_default()` 和 `run_pipeline_batched()` 中 6 处调用点，从 if/elif 分支改为 `send_batch(mode=mode, ...)`。

### Step 6: 删除旧代码

删除 pipeline.py 中的 `send_batch_enterprise()` 和 `send_batch_talent_bank()`。

## 关键文件

| 文件 | 改动 |
|------|------|
| `src/modules/message.py` | 主要：添加公共函数+回调，重写3个batch函数 |
| `src/services/pipeline.py` | 合并3个wrapper，简化6处调用 |
| `src/web/routers/message.py` | **不改** — 只用 Path A，签名不变 |

## 注意事项

1. **DB 记录归属**：Path A 的 `send_message()` 内部记 DB，B/C 的回调显式调 `_log_message()`。公共函数不碰 DB
2. **模板渲染 validate 参数**：`pre_validate=True`（Path A）时 render 传 `validate=False`；B/C 走默认 `validate=True`。公共函数统一 catch `ValidationError` 标记 failed（顺带修复 B/C 渲染异常会 crash 的潜在 bug）
3. **Preview 面板 Mode 行**：Path A 无 Mode 行（`mode_label=""`），B/C 有。公共函数按 `mode_label` 是否非空决定
4. **emit_progress**：仅 Path A 在循环内 emit（Web 服务用），B/C 不 emit

## 验证

```bash
# 静态检查
black src/modules/message.py src/services/pipeline.py
ruff check src/modules/message.py src/services/pipeline.py

# 现有测试
pytest tests/ -v

# 手动验证三条路径（--dry-run 或真实发送）
python src/cli/main.py pipeline -k "前端" -t greeting -p 1 --yes
python src/cli/main.py pipeline -k "前端" -t greeting -m enterprise -p 1 --yes
python src/cli/main.py pipeline -k "算法" -t ganlin -m talent_bank -p 1 --yes
```

## 预期效果

- message.py: ~760行 → ~330行（-57%）
- pipeline.py: 减少 ~50行，消除 mode dispatch 重复
- 公共 API 签名完全不变，所有调用者零改动
