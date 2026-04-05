# Web UI 精简：5 页 → 2 页

## Context

当前 Web UI 有 5 个页面（Dashboard、Search、Pipeline、Candidates、Messages），对于一个招聘助手来说过于复杂。Search 和 Pipeline 功能高度重叠（Pipeline = Search + 发消息），Dashboard 信息量不足以独占一页，Candidates 和 Messages 可以合并。

目标：精简为 2 个页面，降低使用复杂度。

## 方案

### 页面 1: 主页 `/` — 合并 Dashboard + Search + Pipeline

- **顶部状态栏**：一行显示连接状态 + 队列信息（替代整个 Dashboard 页）
- **统一表单**：Pipeline 表单 + Location 字段（从 Search 页补充）
- **智能模式切换**：Template 下拉新增 "Search only" 选项（value=""），选中时隐藏消息选项，按钮文案变为 "Search"；选模板时按钮变为 "Start Pipeline"
- **双路 API**：无模板 → 调 `/api/search`；有模板 → 调 `/api/pipeline`（后端零改动）
- **搜索结果表**：search-only 完成后显示结果表 + 导出按钮
- **Pipeline 结果**：发消息完成后显示统计卡片

### 页面 2: 数据页 `/data` — 合并 Candidates + Messages

- Tab 切换：Candidates / Messages 两个标签页
- 内容完全复用现有 candidates.html 和 messages.html 的逻辑

## 文件变更

### 1. `src/templates/base.html` — 导航精简
- 5 个链接 → 2 个：`/`（Pipeline）、`/data`（Data）

### 2. `src/templates/index.html` — 重写为主页
- 顶部：紧凑状态栏（Browser/Login/Queue，10s 自动刷新）
- 中间：统一表单（keywords、company、location、template、pages）+ messaging options（仅模板选中时显示）
- 下方：progress / confirmation / search-results / pipeline-results 四个隐藏区域

### 3. `src/static/js/pipeline.js` — 支持双模式
- 表单提交：根据 `template` 是否为空决定调 `/api/search` 还是 `/api/pipeline`
- 新增 `showSearchResults()` 和 `exportResults()`（从 search.html 移植）
- 其余函数不变（handlePipelineEvent、showConfirmation、confirmCandidates、showPipelineResults）

### 4. `src/templates/data.html` — 新建
- Tab UI（纯 CSS + 6 行 JS 切换）
- Candidates tab：复用 candidates.html 的 HTML + JS
- Messages tab：复用 messages.html 的 HTML + JS

### 5. `src/web/routers/pages.py` — 路由更新
- 保留 `GET /`，新增 `GET /data`
- 旧 URL（/search、/pipeline、/candidates、/messages）301 重定向

### 6. `src/static/css/style.css` — 新增样式
- `#status-bar`：状态栏样式
- `.tabs` / `.tab`：数据页标签切换样式

### 7. 删除旧模板
- `src/templates/search.html`
- `src/templates/pipeline.html`
- `src/templates/candidates.html`
- `src/templates/messages.html`

## 不变的部分

- 所有后端 API 路由（零改动）
- `src/web/schemas.py`（零改动）
- `ws.js`、`app.js`（零改动）
- 数据库、服务层、模块层（零改动）

## 验证

1. 启动 `python -m src.web.app --port 8000`
2. 访问 `/` — 状态栏显示、表单可用、template 切换 Search/Pipeline 模式
3. 访问 `/data` — Tab 切换正常、Candidates 和 Messages 分页正常
4. 访问 `/search`、`/pipeline`、`/candidates`、`/messages` — 自动 301 重定向
