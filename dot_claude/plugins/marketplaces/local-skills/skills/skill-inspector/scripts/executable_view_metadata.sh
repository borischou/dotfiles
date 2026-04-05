#!/bin/bash
# Skill Metadata Viewer - 提取并显示 .skill 文件的元数据
# 用法: bash view_metadata.sh <skill文件名>.skill

set -e

# 颜色定义
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

print_error() {
    echo -e "${RED}✗${NC} $1"
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

# 验证是否为有效的 ZIP 文件
if ! file "$SKILL_FILE" | grep -q "Zip archive"; then
    print_error "不是有效的 ZIP 文件: $SKILL_FILE"
    exit 1
fi

# 显示标题
echo -e "${BOLD}${CYAN}📋 Skill 元数据${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 提取 SKILL.md 文件内容 - 先尝试子目录，再尝试根目录
SKILL_MD=$(unzip -p "$SKILL_FILE" "*/SKILL.md" 2>/dev/null || unzip -p "$SKILL_FILE" "SKILL.md" 2>/dev/null)

if [ -z "$SKILL_MD" ]; then
    print_error "未找到 SKILL.md 文件"
    exit 1
fi

# 提取 frontmatter - 只从前10行提取，避免匹配文档中其他的 --- 分隔符
FRONTMATTER=$(echo "$SKILL_MD" | head -10 | sed -n '/^---$/,/^---$/p' | grep -v '^---$')

if [ -z "$FRONTMATTER" ]; then
    print_error "未找到 frontmatter 元数据"
    echo ""
    echo "显示 SKILL.md 前 20 行:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$SKILL_MD" | head -20
    exit 1
fi

# 解析并显示 frontmatter
echo -e "${BOLD}Frontmatter:${NC}\n"

echo "$FRONTMATTER" | while IFS=: read -r key value; do
    if [ -n "$key" ] && [ -n "$value" ]; then
        key_clean=$(echo "$key" | sed 's/^ *//' | sed 's/ *$//')
        value_clean=$(echo "$value" | sed 's/^ *//' | sed 's/ *$//')

        echo -e "${BOLD}${BLUE}${key_clean}:${NC} ${value_clean}"
    fi
done

# 提取第一个标题
TITLE=$(echo "$SKILL_MD" | grep -m 1 "^# " | sed 's/^# //')

if [ -n "$TITLE" ]; then
    echo ""
    echo -e "${BOLD}${BLUE}标题:${NC} ${TITLE}"
fi

# 统计信息
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}SKILL.md 统计:${NC}"

LINE_COUNT=$(echo "$SKILL_MD" | wc -l)
WORD_COUNT=$(echo "$SKILL_MD" | wc -w)
CHAR_COUNT=$(echo "$SKILL_MD" | wc -c)

echo "  行数: $LINE_COUNT"
echo "  单词数: $WORD_COUNT"
echo "  字符数: $CHAR_COUNT"

# 提取主要章节
echo ""
echo -e "${BOLD}主要章节:${NC}"
echo "$SKILL_MD" | grep "^## " | sed 's/^## /  - /'

# 询问是否显示完整内容
echo ""
read -p "是否显示 SKILL.md 完整内容? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}SKILL.md 完整内容${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    echo "$SKILL_MD"
fi
