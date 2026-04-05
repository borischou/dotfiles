#!/bin/bash
# Skill Inspector - 完整检查 .skill 文件的结构和内容
# 用法: bash inspect.sh <skill文件名>.skill

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 打印带颜色的标题
print_header() {
    echo -e "\n${BOLD}${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 打印成功信息
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# 打印错误信息
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# 打印警告信息
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <skill文件名>.skill"
    exit 1
fi

SKILL_FILE="$1"

# 检查文件是否存在
if [ ! -f "$SKILL_FILE" ]; then
    print_error "文件不存在: $SKILL_FILE"
    exit 1
fi

# 显示标题
echo -e "${BOLD}${BLUE}📦 Skill Inspector${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BOLD}Skill 文件:${NC} $SKILL_FILE"

# 验证是否为有效的 ZIP 文件
print_header "🔍 验证文件格式"
if file "$SKILL_FILE" | grep -q "Zip archive"; then
    print_success "有效的 ZIP 文件"
else
    print_error "不是有效的 ZIP 文件"
    exit 1
fi

# 测试文件完整性
if unzip -t "$SKILL_FILE" > /dev/null 2>&1; then
    print_success "文件完整性检查通过"
else
    print_error "文件损坏或不完整"
    exit 1
fi

# 获取 skill 名称（从文件名推断）
SKILL_NAME=$(basename "$SKILL_FILE" .skill)

# 提取并显示元数据
print_header "📋 元数据信息"
if unzip -l "$SKILL_FILE" | grep -q "SKILL.md"; then
    # 尝试提取 frontmatter - 先尝试子目录，再尝试根目录
    # 使用 head -10 限制只读取前10行，避免匹配到文档中其他的 --- 分隔符
    METADATA=$( (unzip -p "$SKILL_FILE" "*/SKILL.md" 2>/dev/null || unzip -p "$SKILL_FILE" "SKILL.md" 2>/dev/null) | head -10 | sed -n '/^---$/,/^---$/p' | grep -v '^---$' )

    if [ -n "$METADATA" ]; then
        while IFS=: read -r key value; do
            if [ -n "$key" ] && [ -n "$value" ]; then
                key_clean=$(echo "$key" | sed 's/^ *//' || echo "$key")
                value_clean=$(echo "$value" | sed 's/^ *//' || echo "$value")
                echo -e "${BOLD}${key_clean}:${NC}${value_clean}"
            fi
        done <<< "$METADATA"
    else
        print_warning "未找到 frontmatter 元数据"
    fi
else
    print_error "未找到 SKILL.md 文件"
fi

# 显示文件清单
print_header "📁 文件清单"
FILE_COUNT=$(unzip -l "$SKILL_FILE" | tail -1 | awk '{print $2}')
echo -e "${BOLD}文件总数:${NC} $FILE_COUNT\n"

# 格式化输出文件列表
unzip -l "$SKILL_FILE" | awk 'NR>3 && NF>3 && !/^-/ {
    size = $1
    name = $4

    # 格式化文件大小
    if (size < 1024) {
        size_str = sprintf("%d B", size)
    } else if (size < 1024*1024) {
        size_str = sprintf("%.1f KB", size/1024)
    } else {
        size_str = sprintf("%.1f MB", size/(1024*1024))
    }

    # 根据文件类型添加图标
    if (name ~ /\/$/) icon = "📁"
    else if (name ~ /\.md$/) icon = "📄"
    else if (name ~ /\.py$/) icon = "🐍"
    else if (name ~ /\.sh$/) icon = "🔧"
    else if (name ~ /\.js$/) icon = "📜"
    else icon = "📎"

    printf "  %-10s %s %s\n", size_str, icon, name
}'

# 显示总体统计
print_header "📊 统计信息"
TOTAL_SIZE=$(unzip -l "$SKILL_FILE" | tail -1 | awk '{print $1}')
COMPRESSED_SIZE=$(unzip -v "$SKILL_FILE" | tail -1 | awk '{print $2}')

if [ -n "$TOTAL_SIZE" ] && [ -n "$COMPRESSED_SIZE" ]; then
    COMPRESSION_RATIO=$(echo "scale=1; 100 - ($COMPRESSED_SIZE * 100 / $TOTAL_SIZE)" | bc)

    echo -e "${BOLD}原始大小:${NC} $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "$TOTAL_SIZE bytes")"
    echo -e "${BOLD}压缩后大小:${NC} $(numfmt --to=iec-i --suffix=B $COMPRESSED_SIZE 2>/dev/null || echo "$COMPRESSED_SIZE bytes")"
    echo -e "${BOLD}压缩率:${NC} ${COMPRESSION_RATIO}%"
fi

# 显示目录结构
print_header "🌳 目录结构"
unzip -l "$SKILL_FILE" | awk 'NR>3 && NF>3 && !/^-/ {print $4}' | sort | awk '
BEGIN {
    print "."
}
{
    # 分割路径
    split($0, parts, "/")
    depth = length(parts) - 1

    # 打印缩进和文件名
    indent = ""
    for (i = 0; i < depth; i++) {
        indent = indent "  "
    }

    if ($0 ~ /\/$/) {
        # 目录
        printf "%s├── %s/\n", indent, parts[length(parts)-1]
    } else {
        # 文件
        printf "%s├── %s\n", indent, parts[length(parts)]
    }
}'

# 询问是否解压
print_header "💡 后续操作"
echo "1. 查看 SKILL.md 完整内容: unzip -p \"$SKILL_FILE\" \"*/SKILL.md\" | less"
echo "2. 解压到临时目录: unzip -q \"$SKILL_FILE\" -d /tmp/${SKILL_NAME}-extracted"
echo "3. 查看特定文件: unzip -p \"$SKILL_FILE\" \"<文件路径>\""
echo "4. 测试文件完整性: unzip -t \"$SKILL_FILE\""

echo ""
read -p "是否解压到 /tmp/${SKILL_NAME}-extracted 供进一步探索? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    EXTRACT_DIR="/tmp/${SKILL_NAME}-extracted"
    rm -rf "$EXTRACT_DIR"

    print_header "📂 解压文件"
    unzip -q "$SKILL_FILE" -d "$EXTRACT_DIR"
    print_success "已解压到: $EXTRACT_DIR"

    # 显示解压后的文件树
    if command -v tree &> /dev/null; then
        echo ""
        tree "$EXTRACT_DIR"
    else
        echo ""
        find "$EXTRACT_DIR" -type f | sort
    fi

    echo -e "\n${BOLD}提示:${NC} 使用以下命令浏览文件："
    echo "  cd $EXTRACT_DIR"
    echo "  ls -la"
fi

echo ""
print_success "检查完成！"
