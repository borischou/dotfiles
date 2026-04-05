# Fix: 搜索结果提取 name/company/title 字段混乱

## Context

搜索功能已修复（改为交互式搜索 → 人脉 tab），但 `_extract_search_results` 的 JS 提取逻辑将社交标签和活动信息错误地混入了 name/company/title 字段。

**实际卡片文本结构**（TreeWalker 得到的 text nodes）：
```
"郭大明(猎头勿扰)" → "4天前活跃" → "字节跳动前端leader" → "同行，26个共同好友" → "+ 好友"
```

**期望**：name="郭大明", company="字节跳动", title="前端leader"
**实际**：name="字节跳动前端leader", company="同行，26个共同好友"

## 根因（3 个 bug）

### Bug 1: Name 正则不允许括号（line 372）
`/^[\u4e00-\u9fa5a-zA-Z·\s]+$/` 不匹配 "郭大明(猎头勿扰)" 中的括号 → 真实姓名被跳过 → 后面的公司职位文本被错误选为 name。

### Bug 2: 社交标签未加入 skip 列表（line 347-362）
"同行，26个共同好友"、"前同事，同行，6个共同好友" 未被 `isSkippable()` 过滤 → 被当作 company 或 title。

### Bug 3: Name 提取后未去除括号注释
"郭大明(猎头勿扰)" 应该只保留 "郭大明"，括号内是社交标注不是名字的一部分。

## 修改文件

`src/modules/search.py` — `_extract_search_results` 函数内的 JS `page.evaluate` 块

## 修改方案

### 1. 扩展 name 正则允许括号（line 372）

```javascript
// Before:
if (/^[\u4e00-\u9fa5a-zA-Z·\s]+$/.test(part)) {
// After:
if (/^[\u4e00-\u9fa5a-zA-Z·\s()（）]+$/.test(part)) {
```

### 2. 提取 name 后去除括号注释（line 373）

```javascript
name = part.replace(/[（(][^)）]*[）)]/g, '').trim();
```

### 3. 扩展 isSkippable 函数（line 358-363）

在 activity time 检查中增加社交关系关键词：

```javascript
const isSkippable = (text) => {
    if (skipPatterns.some(p => p.test(text))) return true;
    // Activity time
    if (/天前|小时前|分钟前|刚刚|活跃|在线/.test(text)) return true;
    // Social relationship labels
    if (/同行|前同事|校友|共同好友/.test(text)) return true;
    return false;
};
```

这样 "同行，26个共同好友" 和 "前同事，同行，6个共同好友" 都会被跳过。

## 验证

1. 重启 Web 服务
2. 调用搜索 API：`POST /api/search {"keywords": ["前端"], "pages": 1}`
3. 检查返回的候选人数据：
   - name 应该是纯姓名（如 "郭大明"），不应含公司/职位
   - company 应该是公司名（如 "字节跳动"），不应含社交标签
   - title 应该是职位（如 "前端leader"）
   - "同行"、"共同好友" 等文本不应出现在任何字段中
