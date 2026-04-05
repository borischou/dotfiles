---
name: record
description: 浏览器行为录制。连接 CDP 录制用户操作，提取选择器和 URL 模式，更新 selectors.json。适用于 maimai/boss 等浏览器自动化项目。触发词：录制、record、录选择器、更新选择器。
---

# Browser Action Recorder

录制用户在浏览器中的操作，提取选择器，更新项目的 selectors.json。

## 适用场景

- 脉脉/Boss直聘页面结构变化，需要重新获取选择器
- 新增功能模块（如新的搜索路径、消息入口），需要发现 DOM 结构
- 初始化新的浏览器自动化项目，首次获取选择器

## 前置条件

1. Chrome 以 CDP 模式运行（`--remote-debugging-port=9222`）
2. 用户已在 Chrome 中登录目标平台
3. 项目目录下有 `scripts/recorder.py`

如果前置条件不满足，提示用户：
```
make chrome    # 启动 CDP Chrome
# 然后手动登录脉脉/Boss直聘
```

## 录制流程

### Step 1: 确认录制目标

询问用户要录制什么操作：

- **搜索流程**：从首页到搜索结果页
- **消息发送**：从候选人页面到发送消息
- **登录流程**：登录页面交互
- **自定义**：用户描述操作路径

### Step 2: 启动录制

运行项目中的 recorder.py：

```bash
python3 scripts/recorder.py --cdp http://localhost:9222 -o recorded_<目标>.py
```

提示用户：
```
录制已启动，请在 Chrome 中执行目标操作。
完成后按 Ctrl+C 停止录制。

操作提示：
- 正常速度操作，不需要刻意放慢
- 每个关键步骤都点一下，确保被捕获
- 如果需要等待页面加载，正常等待即可
```

### Step 3: 分析录制结果

录制结束后，读取生成的两个文件：

1. `recorded_<目标>.json` — 原始事件流
2. `recorded_<目标>.py` — 生成的 Playwright 回放脚本

从 JSON 中提取：

- **页面 URL 模式**：导航事件中的 URL，提取为模式（如 `https://maimai.cn/search?*`）
- **关键选择器**：点击和输入事件中的 selector，按操作步骤排列
- **时序信息**：步骤间的等待时间，识别需要 wait_for 的地方
- **页面结构**：从选择器路径推断 DOM 层级

向用户展示提取结果：
```
录制分析结果：

URL 模式:
  1. https://maimai.cn/search?query=...
  2. https://maimai.cn/contacts/...

关键选择器 (按操作顺序):
  1. CLICK  input[placeholder="搜索人脉"]     — 搜索框
  2. INPUT  input[placeholder="搜索人脉"]     — 输入关键词
  3. KEY    Enter                              — 触发搜索
  4. CLICK  text="立即沟通"                    — 发起聊天
  ...

建议等待点:
  - 步骤 3→4 之间有 2.5s 延迟，建议 wait_for_selector
```

### Step 4: 更新 selectors.json

如果项目有 `config/selectors.json`：

1. 读取现有内容
2. 将新选择器按模块分类（search/message/profile/auth）
3. 向用户展示 diff：哪些是新增、哪些是替换
4. 用户确认后更新文件

如果没有 selectors.json，按标准格式创建：
```json
{
  "version": "1.0.0",
  "search": { ... },
  "message": { ... },
  "profile": { ... },
  "auth": { ... }
}
```

### Step 5: 生成代码片段

根据录制结果，生成可以直接集成到模块中的代码片段：

```python
# 搜索流程 — 可集成到 src/modules/search.py
async def search_candidates(page, keyword):
    await page.locator('input[placeholder="搜索人脉"]').fill(keyword)
    await page.keyboard.press('Enter')
    await page.wait_for_selector('.search-result-item', timeout=10000)
    ...
```

向用户展示片段，说明应集成到哪个模块。

### Step 6: 清理

提示用户是否删除录制产物文件（`recorded_*.py` 和 `recorded_*.json`），还是保留备查。

## 注意事项

- recorder.py 只在项目本地的 scripts/ 下运行，不需要全局安装
- 录制过程中 Claude 无法直接控制浏览器，全靠用户操作
- 选择器优先级：`data-testid` > `#id` > `text=` > `placeholder` > CSS path
- text= 选择器更稳定（不受 CSS class 混淆影响），但中文文本可能随改版变化
- 录制完成后建议用回放脚本（`recorded_*.py`）验证选择器可用性
