# Boss Assistant Web 服务化方案

## Context

当前 Boss Assistant 是 CLI 工具，每次执行命令需要手动输入。目标是将其改造为持续运行的 Web 服务，用户通过浏览器可视化操作搜索候选人、发消息、运行 Pipeline，同时保留 CLI 兼容。

## 技术选型

| 决策 | 选择 | 理由 |
|------|------|------|
| Web 框架 | **FastAPI** + Jinja2 | async 原生，HTMX 兼容，SSE/WebSocket 内置 |
| 前端 | **HTMX** + Simple.css | 零构建工具，服务端渲染，classless CSS |
| 实时进度 | **SSE**（非 WebSocket） | HTMX 原生 SSE 扩展，单向数据流更简单 |
| 后台任务 | **asyncio.create_task** | 单用户场景，同事件循环，不需要 Celery |
| Chrome 管理 | **服务自动启动** headed 模式 | Boss 直聘需要可见浏览器处理验证码/登录 |
| DB 连接池 | **NullPool** 替代 StaticPool | Web + 后台任务并发安全 |
| CLI | **保留** | Web 和 CLI 共享 modules 层，两者并存 |

## 新增依赖

```
fastapi==0.109.0
uvicorn[standard]==0.27.0
jinja2==3.1.3
python-multipart==0.0.6
sse-starlette==1.8.2
```

## 项目结构（新增部分）

```
src/web/                          # 新增 Web 层
  __init__.py
  app.py                          # FastAPI app factory + lifespan
  routes/
    __init__.py
    dashboard.py                  # GET /
    auth.py                       # /auth/status, /auth/check, /auth/logout
    search.py                     # GET/POST /search
    candidates.py                 # /candidates, /candidates/{boss_id}
    messages.py                   # /messages/preview, /messages/send
    pipeline.py                   # /pipeline, /pipeline/start, /pipeline/cancel, /pipeline/progress (SSE)
    export.py                     # /export, /export/download
    templates.py                  # /templates, /templates/{name}
    settings.py                   # /settings
    status.py                     # /status (rate limits)
  templates/
    base.html                     # 基础布局（导航、HTMX/SSE 引入）
    dashboard.html
    search.html
    candidates.html
    candidate_detail.html
    pipeline.html
    templates.html
    settings.html
    status.html
    partials/                     # HTMX 局部更新片段
      candidate_table.html
      search_results.html
      pipeline_progress.html
      toast.html
  static/
    css/style.css                 # 少量自定义样式
    js/app.js                     # 少量 JS（SSE 事件处理等）
  services/
    __init__.py
    chrome_manager.py             # Chrome 进程生命周期管理
    task_manager.py               # Pipeline 后台任务管理
run_web.py                        # Web 服务入口
```

## 路由设计

| 当前 CLI 命令 | Web 路由 | 方法 | 说明 |
|--------------|----------|------|------|
| — | `GET /` | GET | 仪表盘：登录/Chrome 状态、今日统计、Pipeline 状态 |
| `login` | `GET /auth/status` | GET | 登录状态检查 |
| `login` | `POST /auth/check` | POST | 触发登录检测 |
| `logout` | `POST /auth/logout` | POST | 清除 session |
| `search` | `GET /search` | GET | 搜索表单页 |
| `search` | `POST /search` | POST | 执行搜索，HTMX 返回结果片段 |
| `profile` | `GET /candidates` | GET | 候选人列表（DB） |
| `profile` | `GET /candidates/{id}` | GET | 候选人详情 |
| `profile` | `POST /candidates/{id}/extract` | POST | 从 Boss 直聘抓取 profile |
| `message` | `POST /messages/preview` | POST | 预览渲染后的消息 |
| `message` | `POST /messages/send` | POST | 发送消息 |
| `pipeline` | `GET /pipeline` | GET | Pipeline 控制面板 |
| `pipeline` | `POST /pipeline/start` | POST | 启动 Pipeline（返回 task_id） |
| `pipeline` | `DELETE /pipeline/cancel` | DELETE | 取消运行中的 Pipeline |
| `pipeline` | `GET /pipeline/progress/{id}` | GET(SSE) | SSE 实时进度流 |
| `export` | `POST /export/download` | POST | 生成并下载文件 |
| `templates` | `GET /templates` | GET | 模板列表 + 编辑器 |
| `templates` | `PUT /templates/{name}` | PUT | 更新模板 |
| `status` | `GET /status` | GET | Rate limit 仪表盘 |
| — | `GET /settings` | GET | 配置页面 |
| — | `POST /settings` | POST | 保存配置 |

## 核心机制

### 1. Chrome 生命周期（`src/web/services/chrome_manager.py`）

- 服务启动时自动拉起 Chrome（headed 模式，`--remote-debugging-port=9222`）
- 使用 `--user-data-dir=data/.chrome-profile` 持久化登录态
- 后台每 10 秒健康检查（HTTP GET `localhost:9222/json/version`）
- Chrome 崩溃时自动重启 + 重连 BrowserManager
- 服务关闭时优雅终止 Chrome（SIGTERM → SIGKILL）

### 2. SSE 实时进度

Pipeline 模块注入 `progress_callback`，取代 `console.print()`：

```python
# 事件类型
"search_start"      → {"keyword": "前端", "page": 1}
"search_progress"   → {"keyword": "前端", "page": 2, "found": 15}
"search_complete"   → {"total_candidates": 45}
"scoring_start"     → {"count": 45}
"scoring_complete"  → {"top_score": 87}
"send_start"        → {"total": 20}
"send_progress"     → {"current": 5, "total": 20, "name": "张三", "status": "sent"}
"send_complete"     → {"sent": 18, "failed": 1, "skipped": 1}
"pipeline_complete" → {summary}
"captcha_detected"  → {}  # 通知用户去 Chrome 窗口处理验证码
"error"             → {"message": "..."}
```

HTMX 前端通过 `hx-ext="sse"` + `sse-connect` 自动接收并更新 DOM。

### 3. 后台任务管理（`src/web/services/task_manager.py`）

- `asyncio.create_task()` 在同一事件循环执行 Pipeline
- 同时只允许一个 Pipeline 运行（浏览器是共享资源）
- 取消机制：`asyncio.Event` 标记，Pipeline 每步检查
- Pipeline 运行中，搜索/发消息按钮禁用

### 4. 浏览器锁

Pipeline 运行期间浏览器被独占，其他操作（搜索、发消息）需等待。前端显示 "Pipeline 运行中" 状态，禁用相关按钮。

## 需要修改的现有文件

| 文件 | 改动 |
|------|------|
| `src/core/browser.py` | 添加 `reset_instance()` 类方法，支持 Chrome 重启后重连 |
| `src/services/pipeline.py` | `run_pipeline()` / `search_all_keywords()` / `send_batch()` 添加 `progress_callback` 参数，替代 `console.print()` |
| `src/modules/search.py` | `search_candidates()` 添加可选 `progress_callback` |
| `src/modules/message.py` | `send_message()` 添加 `interactive=True` 参数，Web 模式下跳过 questionary 确认 |
| `src/modules/auth.py` | `login()` 添加可选回调，替代 console 输出 |
| `src/utils/captcha.py` | `_async_input()` 改为非阻塞：Web 模式下发 SSE 通知，轮询等待验证码消失 |
| `src/models/database.py` | StaticPool → NullPool；添加 `PipelineRun` 模型 |
| `config/settings.json` | 添加 `web` 配置段（host、port、chrome_auto_launch） |

## 实施阶段

### Phase 1: 基础框架
- 创建 `src/web/` 目录结构
- 实现 `app.py`（FastAPI app factory + lifespan）
- 实现 `ChromeProcessManager`
- 搭建 Jinja2 模板 + `base.html` 布局
- 实现 Dashboard（`/`）和 Status（`/status`）— 只读页面
- 验证：服务启动、Chrome 自动拉起、页面可访问

### Phase 2: 核心操作
- 实现 auth 路由（登录状态、检测、登出）
- 实现 search 路由（表单 + 执行搜索）
- 实现 candidates 路由（列表 + 详情 + profile 抓取）
- 实现 export 和 templates 路由
- 修改 `auth.py`、`search.py` 支持 progress_callback
- 修改 `captcha.py` 支持 Web 非阻塞模式
- 修改 `database.py`（NullPool + PipelineRun 模型）

### Phase 3: Pipeline + SSE
- 实现 `TaskManager`
- 修改 `pipeline.py`、`message.py` 注入 progress_callback
- 实现 SSE endpoint（`/pipeline/progress/{task_id}`）
- Pipeline 控制面板前端
- 取消/暂停支持

### Phase 4: 收尾
- Settings 页面（在线编辑配置）
- 错误处理 + Toast 通知
- 入口脚本 `run_web.py`
- 更新 CLAUDE.md

## 验证方式

```bash
# 启动服务
python run_web.py

# 验证 Chrome 自动启动
curl http://localhost:9222/json/version

# 访问 Web UI
open http://localhost:8080

# 验证 CLI 仍可用
python -m src.cli.main status
```

## 风险项

1. **浏览器并发冲突** — Pipeline 运行时禁用其他浏览器操作，前端加锁
2. **验证码处理** — 推送 SSE 通知，用户在可见的 Chrome 窗口手动处理
3. **Chrome 远程部署** — 必须有 display（或 Xvfb），headed 模式是 Boss 直聘反检测的要求
4. **SQLite 并发写入** — 单用户低写入量，NullPool + `check_same_thread=False` 足够
