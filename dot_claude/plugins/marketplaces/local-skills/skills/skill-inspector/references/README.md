# Skill Inspector 快速入门

## 快速开始

### 1. 列出 skill 文件内容

```bash
bash scripts/list.sh openspec.skill
```

### 2. 查看详细信息

```bash
bash scripts/list.sh openspec.skill --detailed
```

### 3. 查看元数据

```bash
bash scripts/view_metadata.sh openspec.skill
```

### 4. 完整检查

```bash
bash scripts/inspect.sh openspec.skill
```

### 5. 解压文件

```bash
bash scripts/extract.sh openspec.skill
# 或指定目标目录
bash scripts/extract.sh openspec.skill /tmp/my-dir
```

## 命令速查

### 使用 unzip 命令

```bash
# 列出文件
unzip -l <skill>.skill

# 显示详细信息
unzip -v <skill>.skill

# 测试完整性
unzip -t <skill>.skill

# 查看特定文件
unzip -p <skill>.skill "*/SKILL.md"

# 解压到目录
unzip -q <skill>.skill -d /tmp/extracted
```

### 使用本工具脚本

| 脚本 | 用途 | 示例 |
|------|------|------|
| `list.sh` | 快速列出文件 | `bash scripts/list.sh file.skill` |
| `inspect.sh` | 完整检查 | `bash scripts/inspect.sh file.skill` |
| `extract.sh` | 解压文件 | `bash scripts/extract.sh file.skill` |
| `view_metadata.sh` | 查看元数据 | `bash scripts/view_metadata.sh file.skill` |

## 常见使用场景

### 场景 1: 了解 skill 功能

```bash
# 查看元数据
bash scripts/view_metadata.sh openspec.skill

# 查看 SKILL.md 完整内容
unzip -p openspec.skill "*/SKILL.md" | less
```

### 场景 2: 检查 skill 包含哪些脚本

```bash
# 列出所有文件
unzip -l openspec.skill | grep "scripts/"

# 查看特定脚本
unzip -p openspec.skill "openspec/scripts/validate_spec.py"
```

### 场景 3: 探索 skill 结构

```bash
# 完整检查（交互式）
bash scripts/inspect.sh openspec.skill

# 或直接解压
bash scripts/extract.sh openspec.skill
cd /tmp/openspec-extracted
tree . # 或 ls -R
```

### 场景 4: 比较两个 skill

```bash
# 比较文件列表
diff <(unzip -l skill1.skill) <(unzip -l skill2.skill)

# 比较元数据
diff <(bash scripts/view_metadata.sh skill1.skill) \
     <(bash scripts/view_metadata.sh skill2.skill)
```

## 技巧

### 批量处理

```bash
# 检查当前目录所有 skill
for skill in *.skill; do
    echo "=== $skill ==="
    bash scripts/list.sh "$skill"
    echo
done
```

### 查找特定内容

```bash
# 在所有 skill 的 SKILL.md 中搜索关键词
for skill in *.skill; do
    if unzip -p "$skill" "*/SKILL.md" | grep -q "openspec"; then
        echo "$skill 包含 'openspec'"
    fi
done
```

### 提取所有 SKILL.md

```bash
mkdir -p extracted-docs
for skill in *.skill; do
    name=$(basename "$skill" .skill)
    unzip -p "$skill" "*/SKILL.md" > "extracted-docs/${name}.md"
done
```

## 故障排查

### 问题: "Not a valid ZIP file"

```bash
# 检查文件类型
file your.skill

# 如果不是 ZIP，可能文件损坏或格式错误
```

### 问题: "Cannot find SKILL.md"

```bash
# 列出所有文件，查看是否存在 SKILL.md
unzip -l your.skill

# 如果存在但在不同路径，调整搜索模式
unzip -p your.skill "**SKILL.md"
```

### 问题: 脚本无法执行

```bash
# 添加执行权限
chmod +x scripts/*.sh

# 或直接用 bash 运行
bash scripts/inspect.sh your.skill
```

## 参考文档

- `skill-format.md` - 详细的 .skill 文件格式规范
- 本 skill 的 `SKILL.md` - 完整功能说明
