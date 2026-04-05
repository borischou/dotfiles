# CLI Cheat Sheet

## 启动 Chrome

```bash
make chrome              # 默认单账号 (port 9222)
make chrome-alice        # alice (port 9222)
make chrome-bob          # bob (port 9223)
```

## 常用命令模板

```bash
# 基本搜索
python src/cli/main.py [--profile NAME] search -k "关键词" [-k "关键词2"] -p 页数 -m 模式

# Pipeline（搜索+打招呼）
python src/cli/main.py [--profile NAME] pipeline \
  -k "关键词" [-k "关键词2"] \
  -t 模板名 \
  -m 模式 \
  [-c "公司"] [-c "公司2"] \
  [--min-years N] [--max-years N] \
  [-p 页数] \
  [-y]              # 跳过确认

# 状态检查
python src/cli/main.py [--profile NAME] status
```

## 参数速查

| 参数 | 说明 | 可选值 |
|------|------|--------|
| `--profile` | 账号隔离 | alice, bob, 或任意名 |
| `-m` / `--mode` | 搜索模式 | search_center(默认), enterprise, talent_bank, recruit_manage |
| `-k` | 关键词（可多个） | 任意字符串 |
| `-t` | 消息模板 | greeting, ganlin, jd_live 等（见 message_templates.json） |
| `-c` | 公司筛选（可多个） | 公司名 或 preset tag: TMDJ, 阿里, 美团, 腾讯 |
| `-p` | 最大页数 | 数字，默认1 |
| `--min-years` | 最低工作年限 | 3, 5, 10 等 |
| `--max-years` | 最高工作年限 | recruit_manage 专用 |
| `--exchange-phone` | 交换手机 | talent_bank/recruit_manage 默认开启 |
| `--exchange-wechat` | 交换微信 | talent_bank/recruit_manage 默认开启 |
| `-y` | 跳过确认 | 直接发送 |
| `--dry-run` | 只搜不发 | |
| `--preview` | 预览前3条消息 | |
| `--resume` | 断点续传 | |
| `-l` | 地点筛选 | search_center 模式专用 |
| `--batch-pages N` | 每N页发一批 | |

## 模式 vs 账号类型

| 模式 | 适用账号 | 特点 |
|------|---------|------|
| search_center | 所有 | 首页搜索，覆盖广，支持地点 |
| enterprise | 企业认证 | "招聘"入口，内联发消息 |
| talent_bank | 企业认证 | "招人"→"搜索"，精准+交换联系方式 |
| recruit_manage | 标准付费 | "招聘管理"入口，年限多选+公司tags |

## 自然语言 → 命令示例

- "用alice搜前端，talent_bank，5年以上，搜3页，打招呼用ganlin模板"
  → `python src/cli/main.py --profile alice pipeline -k "前端" -t ganlin -m talent_bank --min-years 5 -p 3 -y`

- "bob搜安卓和音视频，recruit_manage，TMDJ的，3-10年，用jd_live模板"
  → `python src/cli/main.py --profile bob pipeline -k "安卓" -k "音视频" -t jd_live -m recruit_manage -c "TMDJ" --min-years 3 --max-years 10 -p 1 -y`

- "先预览一下alice搜Go后端的消息"
  → `python src/cli/main.py --profile alice pipeline -k "Go后端" -t greeting -m talent_bank --preview`

- "alice断点续传"
  → `python src/cli/main.py --profile alice pipeline --resume`
