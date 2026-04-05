---
name: ship
description: 测试+提交+推送一条龙。自动检测测试框架、智能暂存、生成 conventional commit message、推送到远程。触发词：提交、推送、ship、发布、commit and push。
---

# Ship

测试 → 智能暂存 → Commit → Push，一条命令完成。

## 流程

### Step 1: 运行测试

按以下优先级自动检测项目的测试方式并运行：

1. `package.json` 的 `scripts.test` → `npm test` / `yarn test` / `pnpm test`（看 lockfile）
2. `pyproject.toml` / `pytest.ini` / `setup.cfg` 的 pytest 配置 → `pytest --tb=short -q`
3. `Makefile` 有 `test` target → `make test`
4. `Cargo.toml` → `cargo test`
5. `go.mod` → `go test ./...`
6. `build.gradle` / `pom.xml` → `./gradlew test` / `mvn test`
7. `test/` 或 `tests/` 目录下有 `.bats` 文件 → `bats tests/`
8. 以上都没有 → 跳过测试，告知用户

**测试失败则停止，报告失败详情，不继续提交。**

### Step 2: 智能暂存

检查 `git status`：

1. **暂存区已有内容** → 只提交已暂存的，不动其他文件
2. **暂存区为空** → 分析所有变更（staged + unstaged + untracked），执行以下逻辑：
   - **排除敏感文件**（不暂存）：匹配以下模式的文件直接跳过并警告用户
     - `.env*`、`*.env`
     - `*credential*`、`*secret*`、`*token*`
     - `*.pem`、`*.key`、`*.p12`、`*.pfx`
     - `*password*`、`*.keystore`
   - **暂存其余所有变更文件**：逐个 `git add <file>`（不用 `git add -A`）
3. **无任何变更** → 告知用户没有可提交的内容，停止

### Step 3: 生成 Commit Message

分析 `git diff --cached`，生成 **conventional commit** 格式的消息：

- 格式：`type(scope): description`
- type 从 diff 内容推断：`feat`/`fix`/`refactor`/`docs`/`test`/`chore`/`style`/`perf`
- scope 可选，从修改的目录/模块推断
- description 用英文，简洁描述 **why** 而非 what
- 如果变更涉及多个方面，用最主要的 type，body 中补充说明
- 末尾追加 `Co-Authored-By: Claude <noreply@anthropic.com>`

**向用户展示生成的 commit message，用户确认后再提交。**

### Step 4: Commit + Push

1. 执行 `git commit`
2. 检查当前分支是否有上游追踪分支：
   - 有 → `git push`
   - 没有 → `git push -u origin <branch>`
3. **安全规则**：
   - 永不 `--force` push
   - 如果当前分支是 `main` 或 `master`，**警告用户并要求确认**后再 push
   - 如果 push 失败（如远程有新提交），提示用户先 pull

### Step 5: 报告

输出简明报告：

```
Ship complete:
- Tests: 81 passed
- Files: 5 changed (+120 -45)
- Commit: abc1234 fix(search): handle empty profile_url in enterprise mode
- Pushed to: origin/main
```

## 参数

用户可以通过自然语言传入以下意图：

- **跳过测试**："ship 跳过测试" / "ship --no-test" → 跳过 Step 1（警告用户）
- **只提交不推送**："ship 不推" / "ship --no-push" → 跳过 push
- **指定 commit message**："ship -m 'xxx'" → 跳过自动生成，用用户提供的 message
- **dry run**："ship --dry-run" → 只展示会做什么，不实际执行

## 注意事项

- 这是一个 **用户显式触发** 的 skill，不要自动执行
- commit message 必须通过 HEREDOC 传递以保证格式正确
- 不要修改 git config
- 如果 pre-commit hook 失败，报告 hook 输出并停止
