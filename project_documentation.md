# Project Documentation: project_to_md

## Project Structure

```
├── project_to_md.py
├── run.bat
└── run.sh
```

## File Contents

`/run.sh`
```bash
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
```

`/project_to_md.py`
```python
import os
import argparse
import fnmatch

def read_ignore_patterns(ignore_file_path):
    """Читает и парсит файл .ignore"""
    patterns = []
    
    # Встроенные паттерны по умолчанию (всегда игнорируем)
    default_patterns = [
        '.git', '.git/*', '.gitignore', '.gitmodules', '.gitattributes',
        '*.gitkeep', '.github/*', '.ignore'
    ]
    
    patterns.extend(default_patterns)
    
    if ignore_file_path and os.path.exists(ignore_file_path):
        try:
            with open(ignore_file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    # Пропускаем пустые строки и комментарии
                    if not line or line.startswith('#'):
                        continue
                    
                    # Убираем пробелы в начале и конце
                    pattern = line.strip()
                    
                    # Добавляем паттерн в список
                    patterns.append(pattern)
                    
                    # Если паттерн для папки (заканчивается на /), добавляем также рекурсивную версию
                    if pattern.endswith('/'):
                        patterns.append(pattern + '*')
                        patterns.append(pattern[:-1])  # Без слеша в конце
        except Exception as e:
            print(f"Warning: Could not read ignore file '{ignore_file_path}': {e}")
    
    return patterns

def should_ignore(path, ignore_patterns):
    """Проверяет, должен ли файл/папка быть проигнорирован"""
    # Нормализуем путь для сравнения
    normalized_path = path.replace('\\', '/')
    basename = os.path.basename(path)
    
    for pattern in ignore_patterns:
        # Проверяем полный путь
        if fnmatch.fnmatch(normalized_path, pattern):
            return True
        # Проверяем только имя файла/папки
        if fnmatch.fnmatch(basename, pattern):
            return True
        # Проверяем, является ли путь частью игнорируемой директории
        path_parts = normalized_path.split('/')
        for part in path_parts:
            if fnmatch.fnmatch(part, pattern):
                return True
    return False

def build_tree_structure(root_dir, ignore_patterns, prefix=''):
    """Строит древовидную структуру директорий и файлов"""
    items = []
    
    try:
        entries = sorted(os.listdir(root_dir))
    except PermissionError:
        return f"{prefix} [Permission Denied]\n"
    
    for i, entry in enumerate(entries):
        entry_path = os.path.join(root_dir, entry)
        rel_path = os.path.relpath(entry_path, start=os.path.dirname(root_dir))
        
        if should_ignore(rel_path, ignore_patterns):
            continue
            
        is_last = i == len(entries) - 1
        connector = '└── ' if is_last else '├── '
        
        if os.path.isdir(entry_path):
            items.append(f"{prefix}{connector}{entry}/\n")
            extension = '    ' if is_last else '│   '
            items.append(build_tree_structure(entry_path, ignore_patterns, prefix + extension))
        else:
            items.append(f"{prefix}{connector}{entry}\n")
    
    return ''.join(items)

def get_file_extension(filename):
    """Определяет расширение файла для подсветки синтаксиса"""
    ext = os.path.splitext(filename)[1].lower()
    extension_map = {
        '.py': 'python',
        '.js': 'javascript',
        '.jsx': 'jsx',
        '.ts': 'typescript',
        '.tsx': 'tsx',
        '.java': 'java',
        '.cpp': 'cpp',
        '.c': 'c',
        '.h': 'c',
        '.hpp': 'cpp',
        '.cs': 'csharp',
        '.php': 'php',
        '.rb': 'ruby',
        '.go': 'go',
        '.rs': 'rust',
        '.swift': 'swift',
        '.kt': 'kotlin',
        '.scala': 'scala',
        '.html': 'html',
        '.css': 'css',
        '.scss': 'scss',
        '.sass': 'sass',
        '.less': 'less',
        '.xml': 'xml',
        '.json': 'json',
        '.yml': 'yaml',
        '.yaml': 'yaml',
        '.md': 'markdown',
        '.sql': 'sql',
        '.sh': 'bash',
        '.bash': 'bash',
        '.zsh': 'bash',
        '.ps1': 'powershell',
        '.dockerfile': 'dockerfile',
        'dockerfile': 'dockerfile',
        '.toml': 'toml',
        '.ini': 'ini',
        '.cfg': 'ini',
        '.conf': 'ini',
        '.txt': 'text',
    }
    return extension_map.get(ext, 'text')

def read_file_content(file_path):
    """Читает содержимое файла с обработкой ошибок"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        try:
            with open(file_path, 'r', encoding='latin-1') as f:
                return f.read()
        except:
            return "# Unable to decode file content (binary file)\n"
    except PermissionError:
        return "# Permission denied\n"
    except Exception as e:
        return f"# Error reading file: {str(e)}\n"

def process_directory(root_dir, output_file, ignore_file_path=None):
    """Основная функция обработки директории"""
    ignore_patterns = read_ignore_patterns(ignore_file_path)
    
    # Добавляем игнорирование самого выходного файла
    if output_file:
        output_basename = os.path.basename(output_file)
        ignore_patterns.append(output_basename)
    
    with open(output_file, 'w', encoding='utf-8') as md:
        # Записываем заголовок
        project_name = os.path.basename(os.path.abspath(root_dir))
        md.write(f"# Project Documentation: {project_name}\n\n")
        
        # Записываем структуру проекта
        md.write("## Project Structure\n\n")
        md.write("```\n")
        tree_structure = build_tree_structure(root_dir, ignore_patterns)
        md.write(tree_structure)
        md.write("```\n\n")
        
        # Записываем содержимое файлов
        md.write("## File Contents\n\n")
        
        file_count = 0
        
        for root, dirs, files in os.walk(root_dir):
            # Фильтруем игнорируемые директории
            dirs[:] = [d for d in dirs if not should_ignore(
                os.path.relpath(os.path.join(root, d), start=os.path.dirname(root_dir)), 
                ignore_patterns
            )]
            
            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, start=os.path.dirname(root_dir))
                
                if should_ignore(rel_path, ignore_patterns):
                    continue
                
                # Получаем относительный путь для отображения
                display_path = '/' + os.path.relpath(file_path, start=root_dir)
                if display_path.startswith('/.'):
                    display_path = display_path[2:]
                
                extension = get_file_extension(file)
                content = read_file_content(file_path)
                
                md.write(f"`{display_path}`\n")
                md.write(f"```{extension}\n")
                md.write(content)
                if not content.endswith('\n'):
                    md.write('\n')
                md.write("```\n\n")
                file_count += 1
        
        # Добавляем статистику в конец файла
        md.write("---\n")
        md.write(f"*Generated by Project to MD tool*  \n")
        md.write(f"*Total files processed: {file_count}*  \n")
        
        if ignore_file_path and os.path.exists(ignore_file_path):
            md.write(f"*Ignore file used: {ignore_file_path}*  \n")

def main():
    parser = argparse.ArgumentParser(description='Generate markdown documentation from project structure')
    parser.add_argument('directory', help='Path to the project directory')
    parser.add_argument('output', help='Output markdown file name')
    parser.add_argument('--ignore-file', help='Path to .ignore file', default='.ignore')
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.directory):
        print(f"Error: Directory '{args.directory}' does not exist")
        return
    
    process_directory(args.directory, args.output, args.ignore_file)
    print(f"Documentation generated: {args.output}")

if __name__ == "__main__":
    main()
```

`/run.bat`
```text
@echo off
setlocal enabledelayedexpansion

:: Скрипт для генерации документации проекта в Markdown
:: Использует .ignore файл для исключения файлов и папок

:: Параметры по умолчанию
set "PROJECT_DIR=."
set "OUTPUT_FILE=project_documentation.md"
set "IGNORE_FILE=.ignore"

:: Функция для вывода помощи
:show_help
echo Project to MD - Генератор документации проекта
echo.
echo Использование: %0 [ОПЦИИ]
echo.
echo ОПЦИИ:
echo   -d, --directory ПАПКА    Папка проекта ^(по умолчанию: текущая папка^)
echo   -o, --output ФАЙЛ       Выходной Markdown файл ^(по умолчанию: project_documentation.md^)
echo   -i, --ignore ФАЙЛ       Файл .ignore ^(по умолчанию: .ignore^)
echo   -h, --help              Показать эту справку
echo.
echo Примеры:
echo   %0 -d C:\project -o docs.md
echo   %0 --directory . --output README.md --ignore .ignore
echo   %0  # Использует настройки по умолчанию
echo.
echo Автоматически игнорируются:
echo   • Все Git-файлы и папки ^(.git, .gitignore, etc.^)
echo   • Файлы из .ignore ^(если указан^)
echo   • Сам выходной файл
echo.
echo Формат .ignore файла:
echo   # Комментарии начинаются с #
echo   build/          # Игнорировать папку build
echo   *.log           # Игнорировать все .log файлы
echo   /config.local.* # Игнорировать в корне проекта
goto :eof

:: Разбор аргументов командной строки
:parse_args
if "%~1"=="" goto :args_parsed

if "%~1"=="-d" (
    set "PROJECT_DIR=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="--directory" (
    set "PROJECT_DIR=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="-o" (
    set "OUTPUT_FILE=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="--output" (
    set "OUTPUT_FILE=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="-i" (
    set "IGNORE_FILE=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="--ignore" (
    set "IGNORE_FILE=%~2"
    shift
    shift
    goto :parse_args
)

if "%~1"=="-h" (
    call :show_help
    exit /b 0
)

if "%~1"=="--help" (
    call :show_help
    exit /b 0
)

echo Неизвестный параметр: %~1
echo.
call :show_help
exit /b 1

:args_parsed

:: Проверка существования директории
if not exist "%PROJECT_DIR%" (
    echo Ошибка: Директория '%PROJECT_DIR%' не существует
    exit /b 1
)

:: Проверка существования Python
python --version >nul 2>&1
if errorlevel 1 (
    echo Ошибка: Python не установлен или не найден в PATH
    echo Убедитесь, что Python установлен и добавлен в переменную PATH
    exit /b 1
)

:: Проверка существования основного скрипта
set "SCRIPT_DIR=%~dp0"
set "PYTHON_SCRIPT=%SCRIPT_DIR%project_to_md.py"

if not exist "%PYTHON_SCRIPT%" (
    echo Ошибка: Основной Python скрипт не найден: %PYTHON_SCRIPT%
    echo Убедитесь, что project_to_md.py находится в той же директории
    exit /b 1
)

:: Предупреждение о перезаписи файла
if exist "%OUTPUT_FILE%" (
    echo Внимание: Файл '%OUTPUT_FILE%' уже существует и будет перезаписан
    set /p "CONTINUE=Продолжить? (y/N): "
    if /i not "!CONTINUE!"=="y" (
        echo Отменено пользователем
        exit /b 0
    )
)

:: Проверка ignore файла
if not exist "%IGNORE_FILE%" (
    if not "%IGNORE_FILE%"=="" (
        echo Предупреждение: Файл .ignore '%IGNORE_FILE%' не найден
        echo Будет использован только встроенный список игнорирования
        set "IGNORE_FILE="
    )
) else (
    echo Используется .ignore: %IGNORE_FILE%
    echo Содержимое .ignore:
    if exist "%IGNORE_FILE%" (
        for /f "usebackq delims=" %%a in ("%IGNORE_FILE%") do echo   %%a
    )
)

:: Запуск Python скрипта
echo Генерация документации...
echo Папка проекта: %PROJECT_DIR%
echo Выходной файл: %OUTPUT_FILE%

if defined IGNORE_FILE (
    python "%PYTHON_SCRIPT%" "%PROJECT_DIR%" "%OUTPUT_FILE%" --ignore-file "%IGNORE_FILE%"
) else (
    python "%PYTHON_SCRIPT%" "%PROJECT_DIR%" "%OUTPUT_FILE%"
)

:: Проверка успешности выполнения
if errorlevel 1 (
    echo Ошибка при генерации документации
    exit /b 1
)

echo ✓ Документация успешно сгенерирована: %OUTPUT_FILE%

:: Показываем информацию о файле
for /f "tokens=1" %%i in ('dir /-c "%OUTPUT_FILE%" ^| find "1 File(s)"') do set "FILE_SIZE=%%i"
set /a LINE_COUNT=0
for /f "usebackq" %%a in ("%OUTPUT_FILE%") do set /a LINE_COUNT+=1

set /a FILE_COUNT=0
for /f "usebackq" %%a in (`findstr /r "^``/" "%OUTPUT_FILE%" ^| find /c /v ""`) do set FILE_COUNT=%%a

echo Статистика:
echo   Размер файла: %FILE_SIZE%
echo   Количество строк: %LINE_COUNT%
echo   Файлов в документации: %FILE_COUNT%

endlocal
```

---
*Generated by Project to MD tool*  
*Total files processed: 3*  
