# 人才银行搜索-发消息路径：录制 + 集成

## Context

脉脉有一个新的「人才银行」入口，需要录制其搜索→发消息的操作路径，提取选择器，然后集成到项目中，作为第三种搜索模式（alongside search_center 和 enterprise）。

## Phase 1: 录制人才银行操作路径

### Step 1: 启动录制器
```bash
python3 scripts/recorder.py -o recorded_talent_bank.py
```

### Step 2: 用户操作
用户在 Chrome 中执行完整的人才银行路径：
- 进入人才银行入口
- 搜索候选人
- 发消息

### Step 3: 分析录制结果
- 读取 `recorded_talent_bank.json` 和 `recorded_talent_bank.py`
- 提取 URL 模式、关键选择器、时序信息
- 与用户确认选择器的语义

## Phase 2: 集成到项目（录制分析完成后细化）

### Step 4: 更新 `config/selectors.json`
- 新增 `talent_bank` section，放入录制提取的选择器

### Step 5: 新增 SearchMode
- `src/services/pipeline.py`: `SearchMode` 枚举新增 `TALENT_BANK = "talent_bank"`

### Step 6: 实现搜索函数
- `src/modules/search.py`: 新增 `search_candidates_talent_bank()`
- 参考 enterprise 路径结构（新 tab / 关键词过滤 / 结果提取）
- 新增 `_extract_talent_bank_results()` JS 提取逻辑

### Step 7: 实现消息发送
- `src/modules/message.py`: 根据人才银行的消息发送方式决定
  - 如果是内联发送（类似 enterprise）→ 新增 `send_message_talent_bank_inline()`
  - 如果导航到聊天页（类似 search_center）→ 复用现有逻辑

### Step 8: Pipeline 集成
- `src/services/pipeline.py`: 搜索和发消息阶段新增 talent_bank 分支

### Step 9: CLI / Web 暴露
- CLI: `--mode` 参数新增 `talent_bank` 选项
- Web: 前端 mode 下拉新增选项

## Verification
- 录制完成后先回放验证选择器可用
- 单元测试覆盖新的搜索模式
- 端到端：`python src/cli/main.py pipeline -k "前端" -m talent_bank -t greeting --dry-run`

## 关键文件
- `scripts/recorder.py` — 录制脚本
- `config/selectors.json` — 选择器配置
- `src/modules/search.py` — 搜索模块
- `src/modules/message.py` — 消息模块
- `src/services/pipeline.py` — Pipeline 编排
- `src/cli/main.py` — CLI 入口
