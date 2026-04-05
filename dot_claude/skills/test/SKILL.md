---
name: test
description: 智能测试运行。自动检测框架、运行测试、解析结果、分析失败原因。支持 --fix 自动修复和 --cov 覆盖率模式。触发词：跑测试、test、验证、测试通过了吗。
---

# Smart Test Runner

自动检测测试框架，运行测试，解析并报告结果。

## 测试框架检测

按优先级自动检测（与 `/ship` 和 pre-commit hook 保持一致）：

1. `pyproject.toml` / `pytest.ini` / `setup.cfg` / `requirements.txt` 含 pytest → `pytest`
2. `package.json` 的 `scripts.test` → `npm/yarn/pnpm test`
3. `Makefile` 有 `test` target → `make test`
4. `Cargo.toml` → `cargo test`
5. `go.mod` → `go test ./...`
6. `build.gradle` / `pom.xml` → `./gradlew test` / `mvn test`
7. `tests/*.bats` → `bats`
8. 都没有 → 告知用户未检测到测试框架

检测到后告知用户使用的框架和命令。

## 基本流程

### Step 1: 运行测试

根据检测到的框架执行测试命令：

- **pytest**: `python -m pytest --tb=short -q`
- 如果用户指定了 `--cov`：追加 `--cov=src --cov-report=term-missing`
- 如果用户指定了特定文件/目录：只跑指定范围

### Step 2: 解析结果

从输出中提取：

- 通过/失败/跳过/错误的数量
- 失败测试的名称和位置
- 错误信息摘要

### Step 3: 报告

**全部通过**：
```
Tests: 81 passed in 0.75s
```

**有失败**：
```
Tests: 79 passed, 2 failed in 0.82s

Failed:
  1. tests/test_config.py::test_load_missing_file
     → FileNotFoundError: config/missing.json
  2. tests/test_validators.py::test_validate_empty_input
     → AssertionError: expected ValidationError
```

### Step 4: 失败分析（如有失败）

对每个失败测试：

1. 读取失败测试的源码
2. 读取被测代码的对应位置
3. 分析失败原因：是测试写错了，还是代码有 bug？
4. 向用户报告分析结果

## 参数

通过自然语言传入：

| 意图 | 示例 | 行为 |
|------|------|------|
| 运行全部 | `/test` | 运行所有测试 |
| 运行指定文件 | `/test test_config` | 只跑匹配的测试文件 |
| 覆盖率 | `/test --cov` | 追加覆盖率报告 |
| 自动修复 | `/test --fix` | 失败后自动分析并修复，然后重跑 |
| 详细输出 | `/test -v` | 使用 verbose 模式 |

## --fix 模式

当用户传入 `--fix` 时，在 Step 4 之后自动执行：

1. 对每个失败，判断是代码 bug 还是测试 bug
2. 应用最小修复（使用 Edit 工具）
3. 重新运行失败的测试验证修复
4. 如果修复引入新失败，回滚并报告
5. 全部修复后运行全量测试确认
6. 报告修复了什么

**--fix 不会自动提交**，修复完让用户决定是否 `/ship`。

## 注意事项

- 这是一个 **用户触发** 的 skill
- 不修改测试配置文件
- --fix 模式谨慎使用，每次只改一处并验证
- 如果测试失败涉及外部依赖（DB、网络、浏览器），标记为环境问题而非代码 bug
