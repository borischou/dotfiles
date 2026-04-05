# 移除 Web 层，专注 CLI

## Context

项目同时支持 Web（FastAPI）和 CLI 两种入口，但实际只使用 CLI。Web 层增加了维护成本和依赖复杂度。移除 Web 相关代码，让项目更精简。

## 现状分析

- Web 代码完全隔离在 `src/web/`、`src/templates/`、`src/static/`
- **唯一的反向依赖**：`src/services/pipeline.py` 和 `src/modules/message.py` import `emit_progress` from `src/web/progress.py`
- `emit_progress` 在 CLI 模式下是 no-op（contextvars 默认 None），移除零影响

## 执行步骤

### Step 1: 删除 Web 目录和文件
- `src/web/` — 整个目录（app.py, task_queue.py, progress.py, deps.py, schemas.py, routers/）
- `src/templates/` — Jinja2 模板（base.html, index.html, data.html）
- `src/static/` — 前端资源（js/, css/）

### Step 2: 清理 emit_progress 引用
- `src/services/pipeline.py`：删除 `from src.web.progress import emit_progress` 及所有 `emit_progress(...)` 调用（~8 处）
- `src/modules/message.py`：删除 `from src.web.progress import emit_progress` 及 `emit_progress(...)` 调用（~1 处），同时删除 `batch_config.emit_web_progress` 相关逻辑

### Step 3: 移除 Web 依赖（requirements.txt）
删除：
```
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
python-multipart>=0.0.6
jinja2>=3.1.3
```

### Step 4: 更新 Makefile
- 删除 `dev` 和 `web` targets
- 删除 `.PHONY` 中的 `dev` 和 `web`

### Step 5: 更新 CLAUDE.md
- 移除 Web 相关架构描述、API 文档、Web 启动说明
- 简化为 CLI-only 文档

### Step 6: 验证
- `python3 -m pytest --tb=short -q` 确保测试通过
- `python3 src/cli/main.py --help` 确保 CLI 正常
- `ruff check src/` 确保无 lint 错误

## 关键文件

| 操作 | 文件 |
|------|------|
| 删除 | `src/web/` (entire dir) |
| 删除 | `src/templates/` (entire dir) |
| 删除 | `src/static/` (entire dir) |
| 编辑 | `src/services/pipeline.py` — 移除 emit_progress |
| 编辑 | `src/modules/message.py` — 移除 emit_progress |
| 编辑 | `requirements.txt` — 移除 4 个 web 依赖 |
| 编辑 | `Makefile` — 移除 dev/web targets |
| 编辑 | `CLAUDE.md` — 简化为 CLI-only |
