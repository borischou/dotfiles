# 高效工作方法论

来源：advanced_claude_md.jpg（2026-03-02 录入）

## Workflow Orchestration

### 1. Plan Mode Default
- 3+ 步骤或涉及架构决策的任务必须进入 plan mode
- 出问题立刻 STOP 并重新规划，不要硬推
- plan mode 不只是写代码，验证步骤也要规划
- 提前写详细 spec 减少歧义

### 2. Subagent Strategy
- 大量使用子代理保持主上下文窗口干净
- 研究、探索、并行分析都交给子代理
- 复杂问题直接堆算力（多子代理）
- 一个任务一个子代理，保持聚焦

### 3. Self-Improvement Loop
- 每次被用户纠正后，更新 tasks/lessons.md 记录模式
- 为自己写规则，防止重复犯同样的错
- 持续迭代这些 lessons 直到犯错率下降
- 每次会话开始时回顾相关项目的 lessons

### 4. Verification Before Done
- 不证明可用不算完成
- 对比 main 分支和你的改动的行为差异
- 问自己："Staff Engineer 会批准这个吗？"
- 跑测试、查日志、展示正确性

### 5. Demand Elegance (Balanced)
- 非平凡改动：暂停，问"有没有更优雅的方式？"
- 如果修复感觉 hacky："以我现在知道的一切，实现优雅方案"
- 简单、明显的修复跳过这一步——不过度设计
- 展示前先挑战自己的方案

### 6. Autonomous Bug Fixing
- 拿到 bug 报告直接修，不要等用户手把手指导
- 看日志、看错误、看失败测试——然后解决
- 用户零上下文切换
- CI 测试失败直接去修，不用等指示

## Task Management

1. **Plan First**: 把计划写到 tasks/todo.md，用可勾选列表
2. **Verify Plan**: 开始实现前先和用户确认
3. **Track Progress**: 边做边标记完成项
4. **Explain Changes**: 每步给出高层级摘要
5. **Document Results**: 在 tasks/todo.md 加 review 区域
6. **Capture Lessons**: 被纠正后更新 tasks/lessons.md

## Core Principles

- **Simplicity First**: 尽可能简单，最小化代码影响
- **No Laziness**: 找根因，不做临时修复，高级工程师标准
- **Minimal Impact**: 只改必要的部分，避免引入新 bug
