# Plan: 实现 recruit_manage 搜索模式 (Path D)

## Context

普通付费账号没有企业直聘/人才银行入口，只能通过首页"招聘管理"链接进入搜索页。录制数据显示这是一条独立的搜索路径：`#recruiter_manage` → `/ent/talents/discover/search_v2`，有结构化筛选字段（关键词、职位、城市、年限、公司预设标签），消息发送后跳转 IM tab 进行交换。

## 关键发现

- 搜索页 URL `/ent/talents/discover/search_v2` 与 enterprise 的 `/ent/talents/discover` 类似，**候选人卡片结构相同**，可复用 `_extract_enterprise_results()`
- 消息发送：`立即沟通` → textarea → `发送后继续沟通`（类似 talent_bank）
- 交换在**普通 IM 页面**（非 iframe），选择器简单：`text="交换手机"` / `text="交换微信"`
- 同 tab 导航（不开新 tab），但发消息后会打开 IM 新 tab

## 修改文件（5 个）

### 1. `config/selectors.json` — 添加 recruit_manage 选择器
新增 `recruit_manage` section，从录制中提取的选择器。

### 2. `src/modules/search.py` — 添加搜索函数
新增 `search_candidates_recruit_manage()`：
- 导航：首页 → 点击 `#recruiter_manage` → 等待 `search_v2` URL
- 填充筛选：关键词（必选）、职位/城市/年限/公司（可选，通过 preset tag 点选）
- 年限多选：`--min-years 3` → 点击 "3-5年" + "5-10年" + "10年以上"（每个额外 tag 先点 `+` 按钮）
- 公司多选：`--company` 映射到 preset tags，多选同理
- 提取：复用 `_extract_enterprise_results(page)`
- 翻页：infinite scroll（同 enterprise）

### 3. `src/modules/message.py` — 添加消息发送函数
新增 3 个函数：
- `send_message_recruit_manage_inline()` — 点击立即沟通 → 填 textarea → 发送后继续沟通 → 切换到 IM tab → 交换手机/微信 → 关闭 IM tab
- `_make_recruit_manage_sender()` — 创建 send_one callback
- `send_message_batch_recruit_manage()` — 批量发送入口，调用 `_send_message_batch_common()`

IM tab 交换比 talent_bank 简单（不需要 iframe 处理）：
```
im_page.locator("text='交换手机'").click()
im_page.locator("text='交换微信'").click()
im_page.locator("text='确定'").click()  # 微信确认弹窗
```

### 4. `src/services/pipeline.py` — 路由分发
- `SearchMode` 枚举：添加 `RECRUIT_MANAGE = "recruit_manage"`
- 导入新函数
- `send_batch()`：添加 `elif mode == SearchMode.RECRUIT_MANAGE` 分支
- `run_pipeline_default()`：添加 recruit_manage 的 search+send-per-keyword 逻辑块（同 talent_bank 模式，因为同 tab 翻页状态会变）
- `run_pipeline_default()` dry_run 分支：添加 recruit_manage 路由
- `run_pipeline_batched()`：添加 recruit_manage 分支

### 5. `src/cli/main.py` — CLI 选项
- `--mode` choices 加 `recruit_manage`（search 和 pipeline 命令）
- recruit_manage 默认开启 exchange_phone/exchange_wechat
- search 命令添加 recruit_manage 分发

## 不改的
- `src/utils/checkpoint.py` — mode 字段已支持任意字符串，无需修改
- `_extract_enterprise_results()` — 直接复用，不修改

## 实现顺序
1. selectors.json
2. search.py（搜索函数）
3. message.py（发送+交换函数）
4. pipeline.py（路由分发）
5. main.py（CLI 入口）

## 验证
```bash
# 1. 仅搜索（dry run）
venv/bin/python3 src/cli/main.py pipeline -k "安卓" -t jd_live -m recruit_manage --dry-run -p 1

# 2. 搜索+发消息+交换
venv/bin/python3 src/cli/main.py pipeline -k "安卓开发" -t jd_live -m recruit_manage \
  -c "TMDJ" -c "阿里" --exchange-phone --exchange-wechat -p 1 -y
```
