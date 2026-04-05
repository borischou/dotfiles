# Maimai Assistant - Project Memory

> CLI 用法速查见 [cli-cheatsheet.md](cli-cheatsheet.md)，用户会用自然语言下达搜索/打招呼指令，直接拼命令执行。

## Architecture
- **Four search paths**: search_center (A), enterprise (B), talent_bank (C), recruit_manage (D, added Mar 2026)
- Enterprise path opens a new tab via "招聘" button, uses inline chat (no separate chat page)
- Talent bank path: same page navigation via "招人" → "搜索" tab, inline "立即沟通" + "发送后继续沟通"
- Talent bank IM: sends open a new IM tab with chat iframe (`/chat?fr=ent&in_iframe=1&...`); exchange buttons inside iframe `div.tool.normal`
- BrowserManager has multi-tab support: `wait_for_new_tab()`, `switch_to_primary_tab()`, `close_current_tab()`, `len(browser.context.pages)`
- BrowserManager does NOT have `tab_count` property — use `len(browser.context.pages)` instead
- `SearchMode` enum in `src/services/pipeline.py`: `SEARCH_CENTER` | `ENTERPRISE` | `TALENT_BANK` | `RECRUIT_MANAGE`
- **人才银行 vs 招聘管理互斥**: 企业认证账号有人才银行(Path C)，非企业认证有招聘管理(Path D)，同一账号只存在一个
- Recruit manage path (D): 已改版为 `/ent/v41/recruit/talents?tab=2`（旧 search_v2 已失效），左侧筛选面板+候选人列表，代码选择器需更新
- Recruit manage IM: regular `/chat` page (no iframe), direct `text='交换手机'`/`text='交换微信'`/`text='确定'` selectors
- Recruit manage filters: structured preset tags (年限多选 via `+` button, 公司 preset tags like TMDJ/阿里/美团/腾讯)
- Checkpoint saves/restores `mode` field for resume support
- **Multi-profile**: `--profile {name}` 隔离数据到 `data/profiles/{name}/`（DB/logs/session/checkpoints），`apply_profile()` in `src/utils/config.py` deep merge profile-local `settings.json` 到全局 config
- Multi-profile 是进程级隔离（两个终端各跑一个），不是单进程并发
- Alice 用默认端口 9222，Bob 用 9223（`data/profiles/bob/settings.json` 配置）

## Key Patterns
- `_extract_search_results` 的 JS 提取逻辑易受脉脉页面结构变化影响：name 正则需覆盖括号注释，`isSkippable()` 需随页面新增社交标签/活动标签更新
- `browser.page` returns the active tab; all existing modules work unchanged
- Enterprise search: opens new tab, extracts candidates, optionally keeps tab open for inline messaging
- `keep_tab_open=True` parameter on `search_candidates_enterprise()` keeps enterprise tab for `send_message_batch_enterprise()`
- Enterprise tab is closed between keyword searches to avoid tab accumulation (except the last keyword when messaging follows)
- Always `switch_to_primary_tab()` before navigating to homepage to avoid destructively changing user's original tab

## Config
- `config/selectors.json` v1.5.0: has `recruit_manage`, `talent_bank`, `enterprise`, `profile`, `message` sections
- Talent bank selectors: `text='招人'`, `text='搜索'`, `input.ant-input`, `text='立即沟通'`, `text='发送后继续沟通'`, iframe chat exchange buttons
- Enterprise selectors: `text='招聘'`, `text='添加关键词'`, `text='立即沟通'`, `text='发送后留在此页'`, etc.
- Talent bank IM iframe: recorder can't capture events (JS inject works but clicks lost); use CDP direct inspection instead
- **IM iframe 交换按钮**: Playwright 复合选择器(`:has(:text-is())`)在 iframe 中静默失败，必须用 `frame.evaluate()` + JS `el.click()` 直接点击
- **交换按钮实际文本**: "交换手机"(非"交换电话"/"交换手机号")、"交换微信"；点击后变为"申请中"/"交换中"
- **交换微信有确认弹窗**: 点击"交换微信"后出现 `<a class="confirm">确定</a>` 需二次确认，交换手机无需确认
- **Emunium CDP 兼容**: `viewport_size` 在 CDP 模式为 None，导致 Emunium `click_at()`/`type_at()` 抛 TypeError。`human_click`/`human_type` 已加 fallback
- **"立即沟通"按钮定位**: `text='立即沟通'` 匹配页面上第一个按钮而非当前候选人的。需从候选人名字元素向上遍历 DOM 找到所属卡片，再在卡片内定位按钮
- **textarea 填充**: 平台"立即沟通"弹窗会预填候选人名字。用 JS native setter (`HTMLTextAreaElement.prototype.value.set`) 强制覆盖，避免 React 受控组件合并文本
- **人才银行公司过滤**: 是客户端过滤（搜到后按 company 字段筛选），非页面 UI 筛选，候选人池小时需多搜几页

## CLI
- `--profile {name}` on top-level `cli` group — isolates data dir, envvar `MAIMAI_PROFILE`
- `--mode/-m search_center|enterprise|talent_bank|recruit_manage` on `search` and `pipeline` commands (default: search_center)
- `--exchange-phone` / `--exchange-wechat` flags on `pipeline` (talent_bank and recruit_manage modes default ON)
- `--min-years` filter on `pipeline` and `search` (talent_bank mode only, clicks 页面"工作年限"下拉)
- `--batch-pages` with enterprise/talent_bank mode warns user about infinite-scroll incompatibility
- Resume flow reads mode from checkpoint params

## User Preferences
- `/ship` 推送 main 分支时不需要确认，直接推

## Custom Skills & Automation (2026-03-02)
- **Global skills (9)**: `/ship`, `/review`, `/debug`, `/preflight`, `/lessons`, `/test`, `/bootstrap`, `/record`, `/peon-ping-toggle`
- **Pre-commit hook**: `~/.claude/hooks/pre-commit-test.sh` symlinked to maimai/boss/relay/peon-ping/stone-web
- **Makefile**: `make test/lint/format/typecheck/ci/cli/search/pipeline/record/backup/chrome/chrome-alice/chrome-bob/clean`
- macOS 环境 Makefile 用 `python3`/`pip3`（无 `python` 命令）
- **Skill 联动**: `/preflight` → `/test` or pipeline → `/debug` (if fails) → `/lessons` → `/ship`

## 待处理遗留项
1. **循环依赖 message↔selector_discovery** — deferred import，运行时正常但影响静态分析
2. **测试覆盖率低** — 18 个测试（test_config 12 + test_validators 6），纯逻辑模块需补测试
3. **min_years 跨关键词过滤待验证** — 只在第一个关键词设置 UI 过滤，需确认切关键词后筛选是否保持
