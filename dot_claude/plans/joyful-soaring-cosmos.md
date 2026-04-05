# Maimai Assistant Web 服务化方案

## Context

当前项目是 CLI 工具，每次操作需要在终端敲命令。目标是加一层 Web 服务，部署在 Mac 上，团队 2-5 人通过浏览器使用。CLI 继续保留，Web 和 CLI 共享底层模块。

## 核心挑战

1. **浏览器是串行资源** — 一个 Chrome 实例 + CDP 连接，同一时刻只能执行一个浏览器操作
2. **长任务进度反馈** — Pipeline 可能运行几分钟，需要实时推送进度
3. **手动确认变异步** — CLI 用 questionary 阻塞等确认，Web 需要改成请求/响应模式

## 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| Web 框架 | **FastAPI** | 原生 async，和 Patchright 共享事件循环；内置 WebSocket；已有 pydantic |
| 前端 | **Jinja2 + vanilla JS + PicoCSS** | 零构建步骤，简洁实用，快速上线 |
| 并发控制 | **进程内 async 任务队列** | 浏览器本就串行，队列最简单；2-5 人不需要 Celery/Redis |
| 实时通信 | **WebSocket** | 双向通信（进度推送 + 手动确认都需要） |
| 数据库 | **SQLite WAL 模式** | 支持并发读 + 串行写，2-5 人足够 |

## 新增文件结构

```
src/
  web/                          # 新增：Web 层（与 cli/ 平行）
    __init__.py
    app.py                      # FastAPI 应用入口、lifespan、静态文件挂载
    deps.py                     # 依赖注入（browser、db、queue、broadcaster）
    schemas.py                  # Pydantic 请求/响应模型
    task_queue.py               # 串行浏览器任务队列（asyncio.PriorityQueue）
    progress.py                 # WebSocket 进度广播器 + contextvars 回调注入
    routers/
      __init__.py
      auth.py                   # GET /api/auth/status
      search.py                 # POST /api/search
      candidates.py             # GET /api/candidates
      message.py                # POST /api/message, POST /api/message/batch
      pipeline.py               # POST /api/pipeline, POST /api/pipeline/{id}/confirm
      templates.py              # GET /api/templates
      status.py                 # GET /api/status, GET /api/queue
      export.py                 # POST /api/export
      ws.py                     # WebSocket /ws/task/{id}, /ws/global
  templates/                    # 新增：Jinja2 HTML 页面
    base.html                   # 布局 + 导航
    index.html                  # 仪表盘（连接状态、队列、最近活动）
    search.html                 # 搜索表单 + 实时结果
    pipeline.html               # Pipeline 表单 + 进度条 + 候选人确认
    candidates.html             # 候选人列表（分页、筛选）
    messages.html               # 消息历史
  static/
    css/style.css
    js/app.js                   # 通用逻辑
    js/ws.js                    # WebSocket 客户端（自动重连）
    js/pipeline.js              # Pipeline 交互（进度条、候选人勾选确认）
```

## 需要修改的现有文件（改动量都很小）

### 1. `src/models/database.py`
- `DatabaseManager.__init__` 中 `StaticPool` 改为标准连接池 + WAL 模式
- 新增 `WebTask` 模型（记录任务状态，支持服务重启后恢复）
- 新增 migration v3

### 2. `src/services/pipeline.py`
- `run_pipeline_default()` 和 `run_pipeline_batched()` 增加可选参数 `progress_callback`
- 在搜索每个关键词、发送每条消息的关键节点调用 `progress_callback`（CLI 不传此参数，无影响）

### 3. `src/modules/message.py`
- `send_message_batch()` 增加可选参数 `progress_callback`
- 每发完一个候选人调用 `progress_callback` 报告进度

### 4. `src/core/browser.py`
- 新增 `is_connected` 属性（只读状态检查，供 status API 用）

### 5. `requirements.txt`
- 新增 `fastapi`、`uvicorn[standard]`、`python-multipart`、`jinja2`

## 核心设计

### 浏览器任务队列

```
用户A: POST /api/search     →  队列 [task-1]  →  串行执行
用户B: POST /api/pipeline   →  队列 [task-1, task-2]
用户A: POST /api/message    →  队列 [task-1, task-2, task-3]
                                    ↑ 当前执行
```

- 所有涉及浏览器操作的 API 都走队列，返回 `{task_id}`
- 不涉及浏览器的操作（查候选人列表、查消息历史、预览模板）直接返回
- 任务有优先级：HIGH（状态检查）> NORMAL（搜索、消息）> LOW（pipeline）
- 使用 coroutine factory 模式（lambda 返回协程），避免协程只能 await 一次的问题

### WebSocket 进度协议

```json
{"task_id": "abc123", "event": "queued", "position": 2}
{"task_id": "abc123", "event": "search_progress", "keyword": "前端", "page": 2, "total_pages": 5, "found": 15}
{"task_id": "abc123", "event": "awaiting_confirmation", "candidates": [...]}
{"task_id": "abc123", "event": "send_progress", "sent": 5, "total": 20, "current": "张三"}
{"task_id": "abc123", "event": "completed", "result": {...}}
{"task_id": "abc123", "event": "failed", "error": "..."}
```

### 手动/自动模式

- **自动模式**（`auto_send: true`）：搜索完直接发送，等同 CLI 的 `--yes`
- **手动模式**（默认）：
  1. 搜索完成 → WebSocket 推送 `awaiting_confirmation` + 候选人列表
  2. 前端展示候选人，用户勾选
  3. 用户点确认 → `POST /api/pipeline/{task_id}/confirm` + 选中的 maimai_ids
  4. Pipeline 协程通过 `asyncio.Event` 等待确认后继续发送

### 进度回调注入（不侵入现有模块）

使用 `contextvars` 注入进度回调，现有模块代码基本不变：

```python
# src/web/progress.py
_progress_ctx = contextvars.ContextVar('_progress_ctx', default=None)

def emit_progress(event, **data):
    cb = _progress_ctx.get()
    if cb:  # Web 模式下有回调；CLI 模式下为 None，静默跳过
        asyncio.get_running_loop().create_task(cb(event, data))
```

Pipeline 和 message 模块在关键节点加一行 `emit_progress(...)` 即可。

## 实现顺序

### Phase 1: 基础设施
1. 新增 `src/web/task_queue.py` — 串行任务队列
2. 新增 `src/web/progress.py` — WebSocket 广播器
3. 新增 `src/web/app.py` — FastAPI 应用骨架 + lifespan
4. 新增 `src/web/deps.py` — 依赖注入
5. 新增 `src/web/schemas.py` — Pydantic 模型
6. 修改 `src/models/database.py` — WAL 模式 + WebTask 模型

### Phase 2: API 端点
7. 实现各 router（auth → search → candidates → message → pipeline → templates/status/export）
8. 实现 WebSocket 端点

### Phase 3: 现有模块适配
9. `pipeline.py` + `message.py` 加 progress_callback
10. `browser.py` 加 is_connected 属性

### Phase 4: 前端页面
11. base.html 布局 + 各页面
12. WebSocket 客户端 + Pipeline 交互逻辑
13. 基础样式（PicoCSS）

### Phase 5: 集成测试
14. 单用户全流程测试
15. 多用户并发测试（多浏览器标签页）

## 启动方式

```bash
# 1. 照旧启动 Chrome（手动登录脉脉）
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug-profile

# 2. 启动 Web 服务
python -m src.web.app --host 0.0.0.0 --port 8000

# 3. 浏览器访问 http://localhost:8000 或 http://<mac-ip>:8000
```

CLI 仍可独立使用（不能和 Web 同时运行，因为共享一个 Chrome CDP 连接）。

## 验证方式

1. 启动服务后访问 `/api/auth/status` 确认 Chrome 连接正常
2. 通过 `/api/search` 提交搜索任务，WebSocket 接收实时进度
3. 手动模式 Pipeline：提交 → 收到候选人列表 → 勾选确认 → 收到发送进度
4. 多标签页同时提交任务，验证队列串行执行、进度各自独立
