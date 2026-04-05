#!/bin/bash
# Skill Lister - 快速列出 .skill 文件的内容清单
# 用法: bash list.sh <skill文件名>.skill [--detailed]

set -e

# 颜色定义
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <skill文件名>.skill [--detailed]"
    echo ""
    echo "选项:"
    echo "  --detailed    显示详细信息（文件大小、压缩率等）"
    exit 1
fi

SKILL_FILE="$1"
DETAILED=false

if [ $# -ge 2 ] && [ "$2" == "--detailed" ]; then
    DETAILED=true
fi

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
echo -e "${BOLD}${CYAN}📦 $(basename "$SKILL_FILE")${NC}\n"

if [ "$DETAILED" = true ]; then
    # 详细模式
    unzip -v "$SKILL_FILE"
else
    # 简洁模式
    unzip -l "$SKILL_FILE"
fi

# 显示总结
echo ""
FILE_COUNT=$(unzip -l "$SKILL_FILE" | tail -1 | awk '{print $2}')
echo -e "${BOLD}总文件数:${NC} $FILE_COUNT"

# 尝试提取 skill 名称 - 先尝试子目录，再尝试根目录
# 只从前10行提取，避免匹配到文档中的示例代码
SKILL_NAME=$( (unzip -p "$SKILL_FILE" "*/SKILL.md" 2>/dev/null || unzip -p "$SKILL_FILE" "SKILL.md" 2>/dev/null) | head -10 | sed -n '/^name:/p' | sed 's/name: *//' | head -1)
if [ -n "$SKILL_NAME" ]; then
    echo -e "${BOLD}Skill 名称:${NC} $SKILL_NAME"
fi
