# .skill 文件格式详细规范

## 概述

.skill 文件是 Claude Code 使用的技能包格式，本质上是一个 ZIP 压缩文件，包含技能定义、脚本、参考文档和其他资源。

## 文件本质

- **文件扩展名**: `.skill`
- **实际格式**: ZIP 压缩包（deflate 压缩算法）
- **MIME 类型**: `application/zip`
- **兼容性**: 可以使用任何标准 ZIP 工具打开和操作

## 标准目录结构

```
<skill-name>/
├── SKILL.md              # 必需：技能定义和主要文档
├── scripts/              # 可选：可执行脚本
│   ├── *.py             # Python 脚本
│   ├── *.sh             # Shell 脚本
│   ├── *.js             # JavaScript 脚本
│   └── *.ts             # TypeScript 脚本
├── references/           # 可选：参考文档
│   ├── *.md             # Markdown 文档
│   ├── *.txt            # 文本文档
│   └── *.json           # JSON 配置或数据
└── assets/               # 可选：资源文件
    ├── templates/       # 模板文件
    ├── examples/        # 示例文件
    └── *.md             # 其他资源

```

## SKILL.md 文件格式

SKILL.md 是 skill 的核心文件，必须包含在每个 .skill 包中。

### Frontmatter（必需）

使用 YAML 格式的 frontmatter 定义元数据：

```markdown
---
name: skill-name
description: 技能的简短描述，说明用途和触发场景。应包含关键词以便 Claude Code 识别何时使用此技能。
---
```

**字段说明：**

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `name` | string | ✓ | 技能的唯一标识符，通常使用小写字母和连字符 |
| `description` | string | ✓ | 技能描述，包括用途、触发场景、关键功能等 |

### 内容结构（推荐）

```markdown
---
name: skill-name
description: 技能描述
---

# 技能标题

简短介绍技能的作用和适用场景。

## 何时使用此 Skill

明确说明在什么情况下应该使用此技能：
- 场景 1
- 场景 2
- ...

## 核心功能

### 功能 1

功能描述和使用方法

### 功能 2

功能描述和使用方法

## 工作流程

描述典型的使用流程或工作步骤

## 示例

提供实际使用示例

## 参考资源

列出相关的脚本、文档等资源
```

## 脚本文件规范

### 支持的脚本类型

1. **Shell 脚本 (*.sh)**
   - 必须以 shebang 开头：`#!/bin/bash` 或 `#!/bin/sh`
   - 应包含使用说明注释
   - 建议使用 `set -e` 启用错误处理

2. **Python 脚本 (*.py)**
   - 必须以 shebang 开头：`#!/usr/bin/env python3`
   - 应包含 docstring 说明用途
   - 建议使用 argparse 处理命令行参数

3. **JavaScript/TypeScript (*.js, *.ts)**
   - Node.js 脚本应以 shebang 开头：`#!/usr/bin/env node`
   - 应导出清晰的函数接口

### 脚本最佳实践

```bash
#!/bin/bash
# 脚本名称 - 简短描述
# 用法: bash script.sh [参数]

set -e  # 遇到错误时退出

# 参数验证
if [ $# -eq 0 ]; then
    echo "用法: $0 <参数>"
    exit 1
fi

# 脚本逻辑
...
```

## 参考文档规范

### Markdown 文档

- 使用清晰的标题层级（# 到 ####）
- 提供代码示例时使用代码块
- 使用列表、表格等格式化元素提高可读性

### 文档组织

建议的参考文档类型：

- **API 文档**: 如果 skill 提供 API 或函数接口
- **使用指南**: 详细的使用说明和最佳实践
- **示例集合**: 实际使用案例
- **常见问题**: FAQ 文档
- **技术规范**: 详细的技术细节

## 创建 .skill 文件

### 基本步骤

1. **创建目录结构**
   ```bash
   mkdir -p my-skill/{scripts,references,assets}
   ```

2. **编写 SKILL.md**
   ```bash
   cat > my-skill/SKILL.md << 'EOF'
   ---
   name: my-skill
   description: 我的自定义技能
   ---

   # My Skill

   技能说明...
   EOF
   ```

3. **添加脚本和文档**
   ```bash
   # 添加脚本
   echo '#!/bin/bash' > my-skill/scripts/example.sh
   chmod +x my-skill/scripts/example.sh

   # 添加参考文档
   echo '# 参考文档' > my-skill/references/guide.md
   ```

4. **打包成 .skill 文件**
   ```bash
   cd my-skill
   zip -r ../my-skill.skill .
   ```

### 使用压缩选项

```bash
# 使用最大压缩
zip -9 -r my-skill.skill my-skill/

# 排除特定文件
zip -r my-skill.skill my-skill/ -x "*.DS_Store" "*.git*"

# 显示详细输出
zip -r -v my-skill.skill my-skill/
```

## 验证 .skill 文件

### 基本验证

```bash
# 1. 检查文件类型
file my-skill.skill
# 输出应包含: Zip archive data

# 2. 测试文件完整性
unzip -t my-skill.skill

# 3. 查看文件列表
unzip -l my-skill.skill

# 4. 验证 SKILL.md 存在
unzip -l my-skill.skill | grep "SKILL.md"
```

### Frontmatter 验证

```bash
# 提取并验证 frontmatter
unzip -p my-skill.skill "*/SKILL.md" | sed -n '/^---$/,/^---$/p'
```

应输出类似：
```yaml
---
name: my-skill
description: 技能描述
---
```

## 版本管理

### Git 集成

.skill 文件是二进制文件，但可以纳入 Git 管理：

```bash
# .gitattributes
*.skill binary
```

### 版本命名建议

```bash
# 在文件名中包含版本号
my-skill-v1.0.0.skill
my-skill-v1.1.0.skill

# 或使用 Git 标签
git tag -a my-skill-v1.0.0 -m "Release version 1.0.0"
```

## 常见问题

### Q: 可以嵌套目录吗？

A: 可以。scripts、references、assets 目录下可以有任意深度的子目录。

### Q: 文件大小限制是什么？

A: 没有硬性限制，但建议保持在 10MB 以下以便快速加载。

### Q: 可以包含二进制文件吗？

A: 可以，但应谨慎使用。优先使用文本文件以便版本控制和审查。

### Q: 如何更新已安装的 skill？

A: 重新打包并替换原文件即可。Claude Code 会在下次加载时使用新版本。

## 最佳实践总结

1. **保持简洁**: 只包含必要的文件
2. **清晰文档**: SKILL.md 应详细说明使用场景
3. **可执行脚本**: 确保所有脚本都有执行权限和 shebang
4. **版本控制**: 使用语义化版本号
5. **测试验证**: 打包后验证文件完整性
6. **命名规范**: 使用小写字母和连字符
7. **压缩优化**: 使用适当的压缩级别

## 示例 Skills

参考这些示例学习 skill 文件格式：

1. **openspec.skill** - 复杂的多文件 skill
   - 包含多个参考文档
   - 包含 Python 验证脚本
   - 包含模板文件

2. **yt-dlp.skill** - 简单的工具 skill
   - 包含 Python 下载脚本
   - 包含平台参考文档

3. **skill-inspector.skill** - 本工具自身
   - 包含多个 Shell 脚本
   - 包含详细的参考文档

## 工具链

### 推荐工具

- **创建**: `zip` 命令行工具
- **查看**: `unzip`, `zipinfo`, `file`
- **编辑**: 任何文本编辑器
- **版本控制**: Git
- **验证**: 本 skill 提供的检查脚本

### 自动化脚本

```bash
# 创建 skill 的自动化脚本
#!/bin/bash
SKILL_NAME=$1
VERSION=$2

# 验证输入
if [ -z "$SKILL_NAME" ] || [ -z "$VERSION" ]; then
    echo "用法: $0 <skill-name> <version>"
    exit 1
fi

# 打包
cd "$SKILL_NAME"
zip -9 -r "../${SKILL_NAME}-${VERSION}.skill" .

# 验证
unzip -t "../${SKILL_NAME}-${VERSION}.skill"

echo "✓ 已创建: ${SKILL_NAME}-${VERSION}.skill"
```
