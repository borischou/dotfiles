---
name: skill-inspector
description: 检查和探索.skill文件的内部结构。.skill文件是ZIP压缩包，包含skill定义、脚本、参考文档等。支持列出文件、显示详情、解压查看、提取元数据等操作。当用户询问skill文件结构、如何查看skill内容、或需要探索skill包时使用。
---

# Skill Inspector

Skill Inspector 是一个用于检查和探索 .skill 文件内部结构的实用工具。由于 .skill 文件本质上是 ZIP 压缩包，本工具提供了便捷的方式来查看、解压和分析这些文件。

## 何时使用此 Skill

使用此 skill 当用户：
- 想要查看 .skill 文件的内部结构
- 需要了解 skill 包含哪些文件
- 想要提取或查看 skill 中的特定文件
- 需要检查 skill 的元数据（名称、描述等）
- 想要了解 .skill 文件格式

## 核心功能

### 1. 快速列出文件清单

显示 skill 文件中包含的所有文件和目录：

```bash
unzip -l <skill文件名>.skill
```

**示例输出：**
```
Archive:  openspec.skill
  Length      Date    Time    Name
---------  ---------- -----   ----
     8759  01-22-2026 14:55   openspec/SKILL.md
     5527  01-22-2026 14:51   openspec/references/cli-commands.md
---------                     -------
    41384                     9 files
```

### 2. 显示详细信息

显示文件大小、压缩率、CRC校验等详细信息：

```bash
unzip -v <skill文件名>.skill
```

**示例输出：**
```
 Length   Method    Size  Cmpr    Date    Time   CRC-32   Name
--------  ------  ------- ---- ---------- ----- --------  ----
    8759  Defl:N     3172  64% 01-22-2026 14:55 ca96e0cc  openspec/SKILL.md
```

### 3. 解压并探索

解压到临时目录进行详细探索：

```bash
# 解压到指定目录
unzip -q <skill文件名>.skill -d /tmp/skill-extracted

# 列出所有文件
find /tmp/skill-extracted -type f | sort

# 查看目录结构
ls -R /tmp/skill-extracted
```

### 4. 查看特定文件内容

无需解压，直接查看压缩包内的文件内容：

```bash
# 查看 SKILL.md 文件
unzip -p <skill文件名>.skill <skill名称>/SKILL.md

# 查看前几行
unzip -p <skill文件名>.skill <skill名称>/SKILL.md | head -20
```

### 5. 提取 Skill 元数据

提取 SKILL.md 文件中的 frontmatter 元数据（name、description）：

```bash
# 方法1: 使用 sed 提取
unzip -p <skill文件名>.skill <skill名称>/SKILL.md | sed -n '/^---$/,/^---$/p'

# 方法2: 查看完整的 SKILL.md
unzip -p <skill文件名>.skill <skill名称>/SKILL.md | head -10
```

## 工作流程

### 基本检查流程

1. **快速查看** - 列出文件清单
   ```bash
   unzip -l openspec.skill
   ```

2. **了解详情** - 查看文件大小和压缩信息
   ```bash
   unzip -v openspec.skill
   ```

3. **读取元数据** - 查看 skill 的名称和描述
   ```bash
   unzip -p openspec.skill openspec/SKILL.md | head -5
   ```

4. **深入探索** - 解压并查看完整内容
   ```bash
   unzip -q openspec.skill -d /tmp/openspec-inspect
   find /tmp/openspec-inspect -type f
   ```

### 完整检查流程

使用提供的脚本进行完整检查：

```bash
# 使用 inspect.sh 脚本进行完整检查
bash scripts/inspect.sh openspec.skill
```

该脚本会：
1. 验证文件是否为有效的 ZIP 格式
2. 显示文件清单
3. 提取并显示元数据
4. 显示目录结构
5. 可选：解压到临时目录供进一步探索

## Skill 文件格式规范

### 标准目录结构

```
<skill-name>/
├── SKILL.md              # 必需：skill 定义和说明
├── scripts/              # 可选：实用工具脚本
│   ├── *.py
│   ├── *.sh
│   └── *.js
├── references/           # 可选：参考文档
│   └── *.md
└── assets/               # 可选：模板、资源文件
    └── *.md
```

### SKILL.md 格式

SKILL.md 必须包含 frontmatter 元数据：

```markdown
---
name: skill-name
description: skill 描述，说明用途和触发场景
---

# Skill 标题

详细说明...
```

**Frontmatter 字段：**
- `name`: skill 的唯一标识符（必需）
- `description`: skill 的简短描述，包括用途和触发条件（必需）

## 实用技巧

### 批量检查多个 Skill 文件

```bash
for skill in *.skill; do
    echo "=== $skill ==="
    unzip -l "$skill"
    echo
done
```

### 比较两个 Skill 文件

```bash
# 比较文件列表
diff <(unzip -l skill1.skill) <(unzip -l skill2.skill)
```

### 验证 Skill 文件完整性

```bash
# 测试 ZIP 文件完整性
unzip -t <skill文件名>.skill
```

### 提取特定类型文件

```bash
# 只提取 markdown 文件
unzip <skill文件名>.skill "*.md" -d /tmp/skill-md-files
```

## 常见问题

### Q: .skill 文件的本质是什么？
A: .skill 文件是标准的 ZIP 压缩包，使用 deflate 压缩算法。可以使用任何 ZIP 工具打开。

### Q: 如何创建自己的 .skill 文件？
A: 创建符合规范的目录结构，然后使用 zip 命令打包：
```bash
cd <skill-name>
zip -r ../<skill-name>.skill .
```

### Q: 可以手动编辑 .skill 文件吗？
A: 可以。解压、编辑、重新打包即可：
```bash
unzip skill.skill -d skill-temp
# 编辑文件
cd skill-temp && zip -r ../skill-modified.skill .
```

### Q: SKILL.md 中的 frontmatter 是必需的吗？
A: 是的。frontmatter 中的 name 和 description 字段是 Claude Code 识别和加载 skill 的关键。

## 参考资源

- `@/skill-inspector/references/skill-format.md` - Skill 文件格式详细规范
- `@/skill-inspector/scripts/inspect.sh` - 完整的检查脚本
- `@/skill-inspector/scripts/extract.sh` - 解压脚本
- `@/skill-inspector/scripts/view_metadata.sh` - 元数据提取脚本

## 输出示例

使用本 skill 检查 openspec.skill 的示例输出：

```
📦 Skill Inspector
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Skill 文件: openspec.skill
验证状态: ✓ 有效的 ZIP 文件

📋 元数据信息
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
名称: openspec
描述: Spec-driven development workflow for AI coding assistants

📁 文件清单 (9 个文件)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  8,759  openspec/SKILL.md
  5,527  openspec/references/cli-commands.md
  6,962  openspec/references/spec-format-guide.md
 11,706  openspec/references/workflow-examples.md
  4,797  openspec/scripts/validate_spec.py
  1,262  openspec/assets/design-template.md
  1,473  openspec/assets/spec-delta-template.md
    403  openspec/assets/proposal-template.md
    495  openspec/assets/tasks-template.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
总计: 41,384 bytes (压缩后: 14,485 bytes, 65% 压缩率)
```

## 最佳实践

1. **检查前先验证** - 使用 `unzip -t` 确保文件完整性
2. **使用临时目录** - 解压到 `/tmp` 避免污染工作目录
3. **查看元数据优先** - 先读取 SKILL.md 了解 skill 用途
4. **批量处理时注意清理** - 及时删除临时解压的文件
5. **记录 skill 版本** - 使用 git 或其他方式管理 skill 文件版本

## 工作流整合

### 在 Claude Code 中使用

当用户询问关于 .skill 文件的问题时：

1. 首先使用 `unzip -l` 快速列出文件
2. 使用 `unzip -p` 读取 SKILL.md 的 frontmatter
3. 根据需要解压到临时目录进行深入探索
4. 向用户展示格式化的结果

### 与其他工具配合

- **版本控制**: 将 .skill 文件纳入 git 管理
- **CI/CD**: 在构建流程中验证 skill 文件格式
- **文档生成**: 从 SKILL.md 自动生成文档
