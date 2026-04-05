#!/bin/bash
# Skill Extractor - 解压 .skill 文件到指定目录
# 用法: bash extract.sh <skill文件名>.skill [目标目录]

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <skill文件名>.skill [目标目录]"
    echo ""
    echo "示例:"
    echo "  $0 openspec.skill"
    echo "  $0 openspec.skill /tmp/my-extracted-skill"
    exit 1
fi

SKILL_FILE="$1"
SKILL_NAME=$(basename "$SKILL_FILE" .skill)

# 确定目标目录
if [ $# -ge 2 ]; then
    EXTRACT_DIR="$2"
else
    EXTRACT_DIR="/tmp/${SKILL_NAME}-extracted"
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

# 如果目标目录已存在，询问是否覆盖
if [ -d "$EXTRACT_DIR" ]; then
    print_warning "目标目录已存在: $EXTRACT_DIR"
    read -p "是否删除并重新解压? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$EXTRACT_DIR"
        print_success "已删除旧目录"
    else
        print_error "操作已取消"
        exit 1
    fi
fi

# 创建目标目录
mkdir -p "$EXTRACT_DIR"

# 解压文件
echo "正在解压 $SKILL_FILE..."
if unzip -q "$SKILL_FILE" -d "$EXTRACT_DIR"; then
    print_success "解压成功！"
else
    print_error "解压失败"
    exit 1
fi

# 显示统计信息
FILE_COUNT=$(find "$EXTRACT_DIR" -type f | wc -l)
DIR_COUNT=$(find "$EXTRACT_DIR" -type d | wc -l)
TOTAL_SIZE=$(du -sh "$EXTRACT_DIR" | awk '{print $1}')

echo ""
echo "📊 解压统计:"
echo "  文件数: $FILE_COUNT"
echo "  目录数: $DIR_COUNT"
echo "  总大小: $TOTAL_SIZE"
echo ""
echo "📂 解压位置: $EXTRACT_DIR"

# 显示目录树（如果安装了 tree）
if command -v tree &> /dev/null; then
    echo ""
    echo "🌳 目录结构:"
    tree -L 2 "$EXTRACT_DIR"
else
    echo ""
    echo "📁 文件列表:"
    find "$EXTRACT_DIR" -type f | sort | head -20
    if [ $FILE_COUNT -gt 20 ]; then
        echo "  ... 还有 $((FILE_COUNT - 20)) 个文件"
    fi
fi

# 提示后续操作
echo ""
echo "💡 后续操作:"
echo "  cd $EXTRACT_DIR"
echo "  cat */SKILL.md"
echo "  ls -la"

# 询问是否打开目录
if command -v open &> /dev/null; then
    echo ""
    read -p "是否在 Finder 中打开目录? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$EXTRACT_DIR"
    fi
fi
