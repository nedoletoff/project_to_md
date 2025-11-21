#!/bin/bash

# md_to_project.sh - Распаковка проекта из Markdown документа
# 
# Использование:
#   ./md_to_project.sh project_documentation.md
#   ./md_to_project.sh project_documentation.md -o ./output_dir
#   ./md_to_project.sh -f project.md -o ./my_project
#
# Требования: bash 4.0+, awk, sed, find
# Автор: nedoletoff
# Лицензия: MIT

set -e

# ==================== ПЕРЕМЕННЫЕ ====================

VERSION="1.0.0"
MARKDOWN_FILE=""
OUTPUT_DIR="./extracted_project"
FILES_EXTRACTED=0
FILES_SKIPPED=0

# ==================== ФУНКЦИИ ====================

print_help() {
    cat << 'EOF'
MD to Project - распаковка файлов проекта из Markdown

Использование:
    ./md_to_project.sh <markdown_file> [OPTIONS]
    ./md_to_project.sh -f <markdown_file> -o <output_dir>

Опции:
    -f, --file FILE         Путь к Markdown файлу
    -o, --output DIR        Директория для распаковки (по умолчанию: ./extracted_project)
    -h, --help              Справка
    -v, --version           Версия

Примеры:
    ./md_to_project.sh project_documentation.md
    ./md_to_project.sh -f project.md -o my_project
    ./md_to_project.sh project.md --output ./extracted

EOF
    exit 0
}

print_version() {
    echo "MD to Project v${VERSION}"
    exit 0
}

# ==================== ПАРСИНГ АРГУМЕНТОВ ====================

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            MARKDOWN_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            ;;
        -v|--version)
            print_version
            ;;
        *)
            MARKDOWN_FILE="$1"
            shift
            ;;
    esac
done

# ==================== ПРОВЕРКИ ====================

if [ -z "$MARKDOWN_FILE" ]; then
    echo "❌ Ошибка: не указан Markdown файл"
    echo ""
    print_help
fi

if [ ! -f "$MARKDOWN_FILE" ]; then
    echo "❌ Ошибка: файл не найден: $MARKDOWN_FILE"
    exit 1
fi

# ==================== СОЗДАНИЕ ДИРЕКТОРИИ ====================

mkdir -p "$OUTPUT_DIR"

echo ""
echo "📖 Чтение Markdown: $(basename "$MARKDOWN_FILE")"
echo "📁 Директория распаковки: $(cd "$OUTPUT_DIR" && pwd)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==================== ИЗВЛЕЧЕНИЕ ФАЙЛОВ ====================

awk '
BEGIN {
    file = ""
    in_code = 0
    code_content = ""
    files_extracted = 0
    files_skipped = 0
}

# Обнаружение начала блока кода с именем файла
/^`\/.*`$/ {
    if (file != "" && in_code) {
        save_file(file, code_content, output_dir)
        files_extracted++
    }
    match($0, /`\/([^`]+)`/, arr)
    file = arr[1]
    code_content = ""
    next
}

# Обнаружение начала/конца блока кода
/^```/ {
    if (file != "") {
        in_code = !in_code
        if (!in_code) {
            save_file(file, code_content, output_dir)
            files_extracted++
            file = ""
        }
    }
    next
}

# Содержимое файла
{
    if (in_code && file != "") {
        code_content = code_content $0 "\n"
    }
}

END {
    if (file != "" && code_content != "") {
        save_file(file, code_content, output_dir)
        files_extracted++
    }
}

function save_file(filepath, content, output_dir,    dir, fullpath) {
    # Удаляем последний перевод строки
    sub(/\n$/, "", content)
    
    # Полный путь
    fullpath = output_dir "/" filepath
    
    # Создаём директорию
    dir = fullpath
    sub(/\/[^\/]*$/, "", dir)
    system("mkdir -p \"" dir "\"")
    
    # Записываем файл
    print content > fullpath
    close(fullpath)
    
    # Если скрипт - делаем исполняемым
    if (filepath ~ /\.sh$/) {
        system("chmod +x \"" fullpath "\"")
    }
    
    # Вычисляем размер
    size = length(content)
    if (size < 1024) {
        size_str = size "B"
    } else if (size < 1024 * 1024) {
        size_str = sprintf("%.1f KB", size / 1024)
    } else {
        size_str = sprintf("%.1f MB", size / (1024 * 1024))
    }
    
    printf "✅ %-50s (%s)\n", filepath, size_str
}
' MARKDOWN_FILE="$MARKDOWN_FILE" output_dir="$OUTPUT_DIR" "$MARKDOWN_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==================== РЕЗУЛЬТАТЫ ====================

FILE_COUNT=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l)

if [ "$FILE_COUNT" -gt 0 ]; then
    echo "✨ Готово!"
    echo ""
    echo "📊 Статистика:"
    echo "   Файлов распаковано: $FILE_COUNT"
    echo "   Директория: $(cd "$OUTPUT_DIR" && pwd)"
    echo ""
    echo "📂 Структура файлов:"
    
    # Показываем структуру (tree если есть, иначе find)
    if command -v tree &> /dev/null; then
        tree -L 2 "$OUTPUT_DIR" 2>/dev/null || true
    else
        find "$OUTPUT_DIR" -type f | sed 's|^|   |' | sort | head -20
    fi
else
    echo "❌ Файлы не найдены в Markdown"
    exit 1
fi

echo ""
