@echo off
REM md_to_project.bat - Распаковка проекта из Markdown для Windows
REM
REM Использование:
REM   md_to_project.bat project_documentation.md
REM   md_to_project.bat project_documentation.md -o output_dir
REM   md_to_project.bat -f project.md -o my_project
REM
REM Требования: Windows 7+, PowerShell 3.0+
REM Автор: nedoletoff
REM Лицензия: MIT

setlocal enabledelayedexpansion
setlocal enableextensions

set "VERSION=1.0.0"
set "MARKDOWN_FILE="
set "OUTPUT_DIR=extracted_project"
set "FILES_EXTRACTED=0"
set "FILES_SKIPPED=0"

REM ==================== ПАРСИНГ АРГУМЕНТОВ ====================

if "%1"=="" (
    goto :SHOW_HELP
)

if "%1"=="/?" (
    goto :SHOW_HELP
)

if "%1"=="-h" (
    goto :SHOW_HELP
)

if "%1"=="--help" (
    goto :SHOW_HELP
)

if "%1"=="-v" (
    goto :SHOW_VERSION
)

if "%1"=="--version" (
    goto :SHOW_VERSION
)

if "%1"=="-f" (
    set "MARKDOWN_FILE=%2"
    if not "%3"=="" (
        if "%3"=="-o" (
            set "OUTPUT_DIR=%4"
        )
    )
    goto :VALIDATE_FILE
)

if "%1"=="--file" (
    set "MARKDOWN_FILE=%2"
    if not "%3"=="" (
        if "%3"=="-o" (
            set "OUTPUT_DIR=%4"
        )
    )
    goto :VALIDATE_FILE
)

if "%1"=="-o" (
    set "OUTPUT_DIR=%2"
    set "MARKDOWN_FILE=%3"
    goto :VALIDATE_FILE
)

if "%1"=="--output" (
    set "OUTPUT_DIR=%2"
    set "MARKDOWN_FILE=%3"
    goto :VALIDATE_FILE
)

set "MARKDOWN_FILE=%1"
if not "%2"=="" (
    if "%2"=="-o" (
        set "OUTPUT_DIR=%3"
    )
)

REM ==================== ПРОВЕРКА ФАЙЛА ====================

:VALIDATE_FILE
if "%MARKDOWN_FILE%"=="" (
    echo ❌ Ошибка: не указан Markdown файл
    echo.
    goto :SHOW_HELP
)

if not exist "%MARKDOWN_FILE%" (
    echo ❌ Ошибка: файл не найден: %MARKDOWN_FILE%
    exit /b 1
)

REM ==================== ОСНОВНОЙ ПРОЦЕСС ====================

echo.
echo 📖 Чтение Markdown: %MARKDOWN_FILE%
echo 📁 Директория распаковки: %OUTPUT_DIR%
echo.
echo ════════════════════════════════════════════════════════════
echo.

REM Создаём выходную директорию
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Используем PowerShell для парсинга Markdown
powershell -NoProfile -Command ^
    $md = Get-Content -Path '%MARKDOWN_FILE%' -Raw; ^
    $pattern = '`(/[^`]+)`\s+```[\w]*\n(.*?)\n```'; ^
    $matches = [regex]::Matches($md, $pattern, 'Singleline'); ^
    foreach ($match in $matches) { ^
        $filepath = $match.Groups[1].Value.Trim(); ^
        $content = $match.Groups[2].Value; ^
        $fullpath = '%OUTPUT_DIR%\' + $filepath.Replace('/', '\'); ^
        $dir = Split-Path $fullpath; ^
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null; } ^
        Set-Content -Path $fullpath -Value $content -Encoding UTF8; ^
        $size = ([System.Text.Encoding]::UTF8.GetByteCount($content)); ^
        if ($size -lt 1024) { $sizeStr = "$size B"; } ^
        elseif ($size -lt 1024*1024) { $sizeStr = "{0:F1} KB" -f ($size/1024); } ^
        else { $sizeStr = "{0:F1} MB" -f ($size/1024/1024); } ^
        Write-Host ("✅ {0,-50} ({1})" -f $filepath, $sizeStr); ^
    }

echo.
echo ════════════════════════════════════════════════════════════
echo.

REM Подсчёт файлов
for /f %%A in ('dir /b /s "%OUTPUT_DIR%" 2^>nul ^| find /c /v ""') do (
    set "FILE_COUNT=%%A"
)

if %FILE_COUNT% gtr 0 (
    echo ✨ Готово!
    echo.
    echo 📊 Статистика:
    echo    Файлов распаковано: %FILE_COUNT%
    echo    Директория: %CD%\%OUTPUT_DIR%
    echo.
    echo 📂 Структура файлов:
    tree /f "%OUTPUT_DIR%" /a 2>nul || (
        dir /s /b "%OUTPUT_DIR%" | findstr /v /c:"$" | sort
    )
) else (
    echo ❌ Файлы не найдены в Markdown
    exit /b 1
)

echo.
exit /b 0

REM ==================== СПРАВКА ====================

:SHOW_HELP
cls
echo MD to Project - распаковка файлов проекта из Markdown
echo.
echo Использование:
echo    md_to_project.bat ^<markdown_file^> [OPTIONS]
echo    md_to_project.bat -f ^<markdown_file^> -o ^<output_dir^>
echo.
echo Опции:
echo    -f, --file FILE         Путь к Markdown файлу
echo    -o, --output DIR        Директория для распаковки (default: extracted_project^)
echo    -h, --help              Справка
echo    -v, --version           Версия
echo.
echo Примеры:
echo    md_to_project.bat project_documentation.md
echo    md_to_project.bat -f project.md -o my_project
echo    md_to_project.bat project.md --output extracted
echo.
exit /b 0

REM ==================== ВЕРСИЯ ====================

:SHOW_VERSION
echo MD to Project v%VERSION%
exit /b 0
