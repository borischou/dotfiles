# 用户级 CLAUDE.md

此文件对所有项目全局生效。项目级 CLAUDE.md 可覆盖或补充此处的规则。

## 关于我

- 周博立（洛萨），音视频直播技术专家，现任京东直播大前端组负责人（P9）
- 北交大本硕 + 伦敦大学移动通信工程硕士
- 职业线：IBM → Bankwel → 搜狐视频 → 小红书（6年半，直播从0到千万日活/百亿GMV）→ 京东
- 核心能力：直播全链路架构、客户端开发（iOS/Android/Flutter/RN）、团队管理（最高35人）、AI 应用
- 行业影响力：RTE 大会讲师、LVS 评审、个人专利7项
- 当前副业方向：内容创作（AI/效率、技术教程）+ 商业探索（自媒体变现、独立产品）

## AI 沟通规则

- 用中文回复，除非我特别要求用英文
- 主动提建议——发现问题或机会时主动说，不用等我问
- 我有丰富的直播技术和团队管理经验，技术讨论时不需要过度解释基础概念
- 不要过度设计，保持简单

## 全局 Skills

| Skill | 用途 |
|-------|------|
| `/ship` | 测试→智能暂存→commit→push（排除敏感文件，main/master 推前确认） |
| `/review` | 带记忆代码审查：回顾历史→分析修复→死代码清理→复盘归档 |
| `/test` | 智能测试运行，支持 `--fix` 自动修复、`--cov` 覆盖率 |
| `/debug` | 系统化调试 7 步：复现→定位→假设→修复→验证→防御→记录 |
| `/preflight` | 浏览器自动化预检：CDP→登录→搜索→配额（maimai/boss 专用） |
| `/lessons` | 经验教训管理：记录根因+防范规则，会话开始时回顾 |
| `/bootstrap` | 新项目脚手架：标准目录+CLAUDE.md+Makefile+git+hook |
| `/record` | 浏览器行为录制→选择器提取→更新 selectors.json |

联动：`/preflight` → pipeline → `/debug`(if fail) → `/lessons` → `/ship`

## 自动化

- **Pre-commit hook**: `~/.claude/hooks/pre-commit-test.sh`，自动检测测试框架并运行，已装到 5 个项目
- **Makefile**: maimai/boss 项目标准化操作（`make test/lint/ci/dev/search/pipeline` 等）
- macOS 用 `python3`/`pip3`（无裸 `python`）

## 工作方法论

### 流程
- 3+ 步骤的非平凡任务必须进 Plan Mode；出问题立刻停下重新规划，不硬推
- 多用 Subagent 保持主上下文干净，一任务一子代理，复杂问题堆算力
- 完成前必须验证：跑测试、查日志、问自己"Staff Engineer 会批准吗？"
- Bug 报告直接修，零上下文切换，不等用户手把手指导

### 自我改进
- 被纠正后更新项目 `tasks/lessons.md`，写规则防止重复犯错
- 会话开始时回顾相关项目的 lessons

### 原则
- 简单优先，最小影响范围
- 找根因，不做临时修复
- 非平凡改动追求优雅，简单修复不过度设计

## 详细资料

如需更完整的个人定位、职业经历和工作系统，参见：~/Documents/evolve/
