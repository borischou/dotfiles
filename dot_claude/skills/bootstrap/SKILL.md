---
name: bootstrap
description: 新项目脚手架。根据项目类型创建标准目录结构、CLAUDE.md、Makefile、git 初始化、review-history、lessons.md。触发词：新项目、bootstrap、脚手架、初始化项目。
---

# Project Bootstrap

快速搭建新项目的标准结构，保持所有项目的一致性。

## 流程

### Step 1: 确认项目信息

通过 AskUserQuestion 逐步确认：

1. **项目名称**（用于目录名和 CLAUDE.md 标题）
2. **项目类型**：
   - `python-browser` — 浏览器自动化（如 maimai/boss 模式：Patchright + CDP + SQLAlchemy + FastAPI）
   - `python-api` — Python API 服务（FastAPI / Flask）
   - `python-cli` — Python CLI 工具（Click）
   - `node-api` — Node.js API 服务
   - `shell` — Shell 工具/脚本集合
   - `other` — 自定义
3. **一句话描述**（写入 CLAUDE.md 的 Project Overview）
4. **创建位置**（默认 `~/Documents/<项目名>`）

### Step 2: 创建目录结构

根据项目类型生成：

**python-browser（浏览器自动化模板）**：
```
<project>/
├── src/
│   ├── cli/            # Click CLI
│   ├── core/           # browser, session, anti_detection
│   ├── exceptions/     # 自定义异常
│   ├── models/         # SQLAlchemy models
│   ├── modules/        # auth, search, profile, message, export
│   ├── services/       # pipeline, scoring
│   ├── utils/          # rate_limiter, delays, retry
│   └── web/            # FastAPI routers, templates, static
├── tests/
├── scripts/
│   ├── setup_db.py
│   └── recorder.py     # 从 maimai-assistant 复制
├── config/
│   ├── settings.json
│   ├── selectors.json
│   └── message_templates.json
├── tasks/
│   └── lessons.md
├── .claude/
│   └── review-history.md
├── CLAUDE.md
├── Makefile
├── requirements.txt
├── .gitignore
└── README.md
```

**python-api / python-cli**：
```
<project>/
├── src/
├── tests/
├── scripts/
├── config/
├── tasks/
│   └── lessons.md
├── .claude/
│   └── review-history.md
├── CLAUDE.md
├── Makefile
├── requirements.txt
├── .gitignore
└── README.md
```

**node-api**：
```
<project>/
├── src/
├── tests/
├── scripts/
├── tasks/
│   └── lessons.md
├── .claude/
│   └── review-history.md
├── CLAUDE.md
├── Makefile
├── package.json
├── .gitignore
└── README.md
```

**shell**：
```
<project>/
├── scripts/
├── tests/
├── tasks/
│   └── lessons.md
├── .claude/
│   └── review-history.md
├── CLAUDE.md
├── .gitignore
└── README.md
```

### Step 3: 生成文件内容

**CLAUDE.md** — 基于项目类型的模板，包含：
- Project Overview（用户提供的描述）
- Quick Start（根据类型生成）
- Architecture（目录结构说明）
- Key Constraints（根据类型，如 CDP 模式、asyncio 等）
- Config（配置文件说明）
- Testing（测试命令）

**Makefile** — 参照 maimai/boss 的 Makefile 模板，根据类型调整：
- 所有 Python 项目用 `python3`/`pip3`
- 包含 help, install, test, lint, format, ci, clean
- 浏览器自动化项目额外包含 chrome, record, db

**tasks/lessons.md** — 初始模板：
```markdown
# Lessons Learned

项目经验教训记录，防止重复犯错。由 /lessons skill 维护。

---
```

**.claude/review-history.md** — 初始模板：
```markdown
# Code Review History

工程审查历史记录，由 /review skill 自动维护。

---
```

**.gitignore** — 根据类型生成（Python: __pycache__, .env, *.db, .mypy_cache 等）

**requirements.txt / package.json** — 根据类型生成基础依赖

### Step 4: Git 初始化

1. `git init`
2. `git add -A`
3. `git commit -m "chore: initial project scaffold"`

### Step 5: 安装 pre-commit hook

```bash
ln -sf ~/.claude/hooks/pre-commit-test.sh .git/hooks/pre-commit
```

### Step 6: 报告

```
✅ Project bootstrapped: ~/Documents/<项目名>
   Type: python-browser
   Files: 15 created
   Git: initialized with initial commit
   Hook: pre-commit test installed

   Next steps:
   1. cd ~/Documents/<项目名>
   2. pip3 install -r requirements.txt
   3. Start coding!
```

## 注意事项

- recorder.py 从 maimai-assistant 复制（已验证可用）
- python-browser 模板的 selectors.json 创建为空结构，需用 `/record` 录制填充
- 不创建空的 `__init__.py`，让用户按需添加
- README.md 只含项目名和一句话描述，不过度生成
