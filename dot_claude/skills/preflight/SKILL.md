---
name: preflight
description: 浏览器自动化预检。在跑 pipeline、搜索、发消息前检查 Chrome 连接、登录状态、搜索可用性和配额。适用于 maimai-assistant 和 boss-assistant 项目。触发词：预检、preflight、检查连接、检查登录。
---

# Preflight Check

跑 pipeline 前的强制预检，避免因环境问题浪费整个会话。

## 适用项目

- `maimai-assistant` — 脉脉招聘助手
- `boss-assistant` — Boss直聘招聘助手

在其他项目中触发时提示用户此 skill 仅适用于浏览器自动化项目。

## 检查流程

按顺序执行，任一步骤失败则 **停止并报告**，不继续后续步骤。

### Check 1: Chrome CDP 连接

验证 Chrome 是否以 debug 模式运行且可连接：

```python
# 检查 CDP 端口是否可达
import aiohttp
async with aiohttp.ClientSession() as session:
    async with session.get("http://localhost:9222/json/version") as resp:
        # 200 = 连接正常
```

**失败处理**：
```
❌ Chrome CDP 不可达 (localhost:9222)
   → 请启动 Chrome:
   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
       --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug-profile
```

### Check 2: 登录状态

通过项目的 auth 模块验证登录：

```python
# maimai: 调用 auth.check_login_status()
# boss:   调用 auth.check_login_status()
```

**失败处理**：
```
❌ 未登录脉脉/Boss直聘
   → 请在 Chrome 中手动登录后重试
```

### Check 3: 搜索可用性

执行一次最小搜索验证，确认搜索功能和数据提取正常：

1. 用一个通用关键词（如"测试"）执行搜索，限制 1 页
2. 验证返回结果非空
3. 验证至少一个候选人有 `profile_url`

**失败处理**：
```
❌ 搜索返回空结果
   → 可能原因：页面结构变化、选择器失效、反爬触发
   → 建议运行 recorder.py 重新录制选择器
```

### Check 4: 配额检查（仅 maimai）

检查当日消息发送配额余量：

1. 读取 DB 中今日已发送消息数
2. 对比 settings.json 中的日限额配置
3. 如果余量 < 5，警告用户

**警告处理**：
```
⚠️ 今日消息配额剩余: 3/50
   → pipeline 可能中途因配额耗尽停止
   → 建议明天再跑，或只执行搜索（不发消息）
```

## 输出格式

全部通过时：
```
✅ Preflight Check Passed
   Chrome CDP:  connected (localhost:9222)
   Login:       logged in (脉脉/Boss直聘)
   Search:      OK (returned 10 candidates, profile_url present)
   Quota:       42/50 remaining

   Ready to run pipeline.
```

部分失败时在第一个失败项停止，显示具体错误和修复建议。

## 执行方式

这是一个 **指导性 skill**，不直接执行代码。Claude 应该：

1. 读取项目代码，找到对应的 auth/search/config 模块
2. 用 Bash 工具依次执行检查（或写临时脚本）
3. 按上述格式报告结果
4. 全部通过后告知用户可以开始 pipeline

## 注意事项

- 预检不应修改任何数据或状态
- 测试搜索用最小参数（1 页、通用关键词），不写入 DB
- 如果用户直接要求跑 pipeline 而没有先 preflight，主动建议先预检
