#!/bin/bash

# Скрипт для генерации документации проекта в Markdown
# Использует .ignore файл для исключения файлов и папок

set -e  # Завершить скрипт при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода помощи
show_help() {
    echo -e "${BLUE}Project to MD - Генератор документации проекта${NC}"
    echo ""
    echo "Использование: $0 [ОПЦИИ]"
    echo ""
    echo -e "${YELLOW}ОПЦИИ:${NC}"
    echo "  -d, --directory ПАПКА    Папка проекта (по умолчанию: текущая папка)"
    echo "  -o, --output ФАЙЛ       Выходной Markdown файл (по умолчанию: project_documentation.md)"
    echo "  -i, --ignore ФАЙЛ       Файл .ignore (по умолчанию: .ignore)"
    echo "  -h, --help              Показать эту справку"
    echo ""
    echo -e "${YELLOW}Примеры:${NC}"
    echo "  $0 -d /path/to/project -o docs.md"
    echo "  $0 --directory . --output README.md --ignore .ignore"
    echo "  $0  # Использует настройки по умолчанию"
    echo ""
    echo -e "${GREEN}Автоматически игнорируются:${NC}"
    echo "  • Все Git-файлы и папки (.git, .gitignore, etc.)"
    echo "  • Файлы из .ignore (если указан)"
    echo "  • Сам выходной файл"
    echo ""
    echo -e "${YELLOW}Формат .ignore файла:${NC}"
    echo "  # Комментарии начинаются с #"
    echo "  build/          # Игнорировать папку build"
    echo "  *.log           # Игнорировать все .log файлы"
    echo "  /config.local.* # Игнорировать в корне проекта"
}

# Параметры по умолчанию
PROJECT_DIR="."
OUTPUT_FILE="project_documentation.md"
IGNORE_FILE=".ignore"

# Разбор аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            PROJECT_DIR="$2"
            shift
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift
            shift
            ;;
        -i|--ignore)
            IGNORE_FILE="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Неизвестный параметр: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Проверка существования директории
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Ошибка: Директория '$PROJECT_DIR' не существует${NC}"
    exit 1
fi

# Проверка существования Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Ошибка: Python3 не установлен или не найден в PATH${NC}"
    exit 1
fi

# Проверка существования основного скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/project_to_md.py"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo -e "${RED}Ошибка: Основной Python скрипт не найден: $PYTHON_SCRIPT${NC}"
    echo "Убедитесь, что project_to_md.py находится в той же директории"
    exit 1
fi

# Предупреждение о перезаписи файла
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Внимание: Файл '$OUTPUT_FILE' уже существует и будет перезаписан${NC}"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Отменено пользователем"
        exit 0
    fi
fi

# Проверка ignore файла
if [ ! -f "$IGNORE_FILE" ] && [ "$IGNORE_FILE" != "" ]; then
    echo -e "${YELLOW}Предупреждение: Файл .ignore '$IGNORE_FILE' не найден${NC}"
    echo "Будет использован только встроенный список игнорирования"
    IGNORE_FILE=""
else
    echo -e "${GREEN}Используется .ignore: $IGNORE_FILE${NC}"
    echo -e "${BLUE}Содержимое .ignore:${NC}"
    if [ -f "$IGNORE_FILE" ]; then
        cat "$IGNORE_FILE" | while read line; do
            echo "  $line"
        done
    fi
fi

# Запуск Python скрипта
echo -e "${BLUE}Генерация документации...${NC}"
echo "Папка проекта: $(realpath "$PROJECT_DIR")"
echo "Выходной файл: $OUTPUT_FILE"

if [ -n "$IGNORE_FILE" ]; then
    python3 "$PYTHON_SCRIPT" "$PROJECT_DIR" "$OUTPUT_FILE" --ignore-file "$IGNORE_FILE"
else
    python3 "$PYTHON_SCRIPT" "$PROJECT_DIR" "$OUTPUT_FILE"
fi

# Проверка успешности выполнения
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Документация успешно сгенерирована: $OUTPUT_FILE${NC}"
    
    # Показываем статистику
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
    FILE_COUNT=$(grep -c "^\`/" "$OUTPUT_FILE" || true)
    
    echo -e "${BLUE}Статистика:${NC}"
    echo "  Размер файла: $FILE_SIZE"
    echo "  Количество строк: $LINE_COUNT"
    echo "  Файлов в документации: $FILE_COUNT"
else
    echo -e "${RED}✗ Ошибка при генерации документации${NC}"
    exit 1
fi
