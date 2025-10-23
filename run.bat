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
