# Project to MD 📁→📄

[Русский](#русский) | [English](#english)

---

## Русский

**Project to MD** - утилита для объединения файлов проекта в один Markdown документ. Идеально для отправки кода нейросетям, ChatGPT или аналогичным сервисам.

### 🎯 Для чего это нужно?

- 📤 **Отправка кода нейросетям** - весь проект в одном файле
- 📝 **Создание документации** - автоматическая генерация структуры
- 🔍 **Обзор проекта** - быстрый просмотр всей кодовой базы

### 🚀 Быстрый старт

```bash
./run.sh
```

### ⚡ Использование

```bash
# Текущая папка
./run.sh

# Указать папку и выходной файл
./run.sh -d ~/myproject -o project.md

# С файлом исключений
./run.sh -i .ignore
```

### 📁 Файл .ignore

```ignore
node_modules/
*.log
.env
.DS_Store
```

---

## English

**Project to MD** - utility to merge project files into a single Markdown document. Perfect for sending code to AI models, ChatGPT or similar services.

### 🎯 What's it for?

- 📤 **Send code to AI** - entire project in one file
- 📝 **Create documentation** - automatic structure generation
- 🔍 **Project overview** - quick codebase review

### 🚀 Quick Start

```bash
./run.sh
```

### ⚡ Usage

```bash
# Current folder
./run.sh

# Specify folder and output
./run.sh -d ~/myproject -o project.md

# With ignore file
./run.sh -i .ignore
```

### 📁 .ignore File

```ignore
node_modules/
*.log
.env
.DS_Store
```
---
# MD to Project 📁→📄

**Утилита для распаковки проекта из Markdown документа**

Обратная сторона [project_to_md](https://github.com/nedoletoff/project_to_md) — распаковывает встроенные файлы из Markdown обратно в отдельные файлы и директории.

## Версии

| Язык | Файл | Платформа | Требования |
|------|------|-----------|-----------|
| **Python** | `md_to_project.py` | macOS, Linux, Windows | Python 3.6+ |
| **Bash** | `md_to_project.sh` | macOS, Linux | Bash 4.0+, awk |
| **Batch** | `md_to_project.bat` | Windows | Windows 7+, PowerShell 3.0+ |

## Зачем это нужно?

- 📥 **Восстановление проекта** — распаковать файлы из `project_documentation.md`
- 🔄 **Обратное преобразование** — из unified документа в структуру папок
- 📤 **Обмен с AI** — отправил проект в AI, получил Markdown, распаковал обратно
- 🔧 **Автоматизация** — интегрировать в CI/CD pipelines
- 🌐 **Кроссплатформенность** — работает везде

## Использование

### Python версия (рекомендуется)

```bash
# Текущая папка с выходом в ./extracted_project
python3 md_to_project.py project_documentation.md

# Указать выходную директорию
python3 md_to_project.py project_documentation.md -o ./my_project

# Альтернативный синтаксис
python3 md_to_project.py -f project_documentation.md -o ./output

# С помощью
python3 md_to_project.py --help
```

### Bash версия (Linux, macOS)

```bash
# Текущая папка
./md_to_project.sh project_documentation.md

# С опциями
./md_to_project.sh -f project.md -o ./my_project

# Помощь
./md_to_project.sh --help

# Сделать исполняемым (если нужно)
chmod +x md_to_project.sh
```

### Batch версия (Windows)

```batch
REM Текущая папка
md_to_project.bat project_documentation.md

REM С опциями
md_to_project.bat -f project.md -o my_project

REM Помощь
md_to_project.bat --help
```

## Формат входного Markdown

Скрипт ищет файлы в формате:

```markdown
## File Contents

`/path/to/file.ext`
```language
content of file
```

`/another/file.py`
```python
def hello():
    print("Hello")
```
```

### Поддерживаемые форматы кода

- **Web:** html, css, javascript, typescript, json
- **Backend:** python, go, java, cpp, rust, php, c#
- **Markup:** yaml, toml, xml, csv, json
- **Scripts:** bash, sh, zsh, powershell, batch
- **Docs:** markdown, latex
- **И другие:** скрипт распакует любые языки

## Быстрый старт

### Способ 1: Python (универсально)

```bash
# Скачать скрипт
curl -O https://raw.githubusercontent.com/nedoletoff/md-to-project/main/md_to_project.py

# Распаковать
python3 md_to_project.py project_documentation.md -o my_project

# Готово!
cd my_project && ls -la
```

### Способ 2: Bash (Linux/macOS)

```bash
# Скачать скрипт
curl -O https://raw.githubusercontent.com/nedoletoff/md-to-project/main/md_to_project.sh
chmod +x md_to_project.sh

# Распаковать
./md_to_project.sh project_documentation.md -o my_project
```

### Способ 3: Batch (Windows)

```batch
REM Скачать скрипт
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/nedoletoff/md-to-project/main/md_to_project.bat', 'md_to_project.bat')"

REM Распаковать
md_to_project.bat project_documentation.md -o my_project
```

## Опции команды

### Всех версиях

```
ФАЙЛ                Путь к Markdown файлу (позиционный аргумент)

-f, --file FILE     Путь к Markdown файлу (альтернативный синтаксис)
-o, --output DIR    Директория для распаковки (по умолчанию: ./extracted_project)
-v, --version       Версия скрипта
-h, --help          Справка
```

## Примеры

### Пример 1: Распаковка проекта FastAPI

```bash
# Скачиваем project_documentation.md
curl -O https://example.com/project_documentation.md

# Распаковываем на Linux/macOS
./md_to_project.sh project_documentation.md -o scheduler-api

# Или на Windows
md_to_project.bat project_documentation.md -o scheduler-api

# Переходим в проект
cd scheduler-api
ls -la

# Результат:
# README.md
# config.py
# requirements.txt
# scheduler_restart_api.py
# api.conf.yaml
# setup.sh
```

### Пример 2: Распаковка и установка

```bash
# Linux/macOS
./md_to_project.sh doc.md -o myapp
cd myapp
pip install -r requirements.txt
python3 main.py

# Windows
md_to_project.bat doc.md -o myapp
cd myapp
pip install -r requirements.txt
python main.py
```

### Пример 3: Множественные файлы

**Bash:**
```bash
for f in *.md; do
    output="${f%.md}_extracted"
    ./md_to_project.sh "$f" -o "$output"
done
```

**Batch:**
```batch
for %%f in (*.md) do (
    set "output=%%~nf_extracted"
    md_to_project.bat "%%f" -o "!output!"
)
```

## Особенности

✅ **Автоматическое создание директорий** — создаёт вложенные папки если их нет

✅ **Умная фильтрация** — пропускает бинарные файлы (.pyc, .so и т.д.)

✅ **Сохранение прав доступа** — автоматически делает `.sh` файлы исполняемыми

✅ **Обработка ошибок** — подробный вывод ошибок с кодом

✅ **UTF-8 поддержка** — правильно обрабатывает русский текст и Emoji

✅ **Форматирование вывода** — красивый вывод с размерами файлов

✅ **Кроссплатформенность** — работает везде (Python, Bash, Batch)

✅ **Нет зависимостей** — Python версия использует только встроенные модули

## Примеры вывода

### Успешная распаковка

```
📖 Чтение Markdown: project_documentation.md
   Найдено файлов: 7

📁 Распаковка файлов в: /home/user/extracted_project

✅ README.md                                  (12.5KB)
✅ config.py                                  (8.3KB)
✅ requirements.txt                           (342B)
✅ scheduler_restart_api.py                   (35.2KB)
✅ api.conf.yaml                              (5.1KB)
✅ setup.sh                                   (6.8KB)
⏭️  __pycache__/config.cpython-311.pyc       (пропущен - бинарные данные)

════════════════════════════════════════════════════════════
✨ Готово!
════════════════════════════════════════════════════════════
📦 Файлов распаковано: 6
⏭️  Файлов пропущено:   1
📍 Директория:         /home/user/extracted_project
════════════════════════════════════════════════════════════
```

## Требования

### Python версия

- **Python:** 3.6 или выше
- **ОС:** Windows, macOS, Linux
- **Зависимости:** Встроенные модули (нет внешних зависимостей)

### Bash версия

- **Bash:** 4.0 или выше
- **ОС:** macOS, Linux, WSL на Windows
- **Утилиты:** awk, sed, find (обычно предустановлены)
- **Опционально:** tree (для красивого вывода)

### Batch версия

- **Windows:** 7 или выше
- **PowerShell:** 3.0 или выше

## Ограничения

⚠️ **Бинарные файлы** — файлы типа `.pyc`, `.so`, `.dll` и другие пропускаются

⚠️ **Большие файлы** — рекомендуется сжимать очень большие проекты перед преобразованием

⚠️ **Специальные символы** — в путях файлов (лучше использовать alphanumeric + `_` + `/` + `.`)

⚠️ **Синхронизация с проектом** — перед распаковкой, убедитесь что Markdown актуален

## Troubleshooting

### Ошибка: "Markdown файл не найден"

```bash
# Проверить путь
ls -la project_documentation.md

# Использовать абсолютный путь
python3 md_to_project.py $(pwd)/project_documentation.md
```

### Файлы распаковались некорректно

- Проверить формат Markdown — должен быть `` `(/path/file)` ``
- Удостовериться, что язык указан в блоке кода (` ```python `)
- Проверить кодировку файла (должна быть UTF-8)

```bash
file project_documentation.md
```

### Недостаточно прав на запись (Linux/macOS)

```bash
# Изменить владельца
sudo chown -R $USER:$USER ./extracted_project

# Или использовать другую директорию
python3 md_to_project.py doc.md -o ~/my_project
```

## Сравнение с project_to_md

| Функция | project_to_md | md_to_project |
|---------|---------------|---------------|
| Направление | Проект → Markdown | Markdown → Проект |
| Назначение | Подготовка для AI | Восстановление проекта |
| Формат | Единый документ | Структура папок |
| Обратимость | Да (этот скрипт) | Да (project_to_md) |
| Кроссплатформа | Python, Bash | Python, Bash, Batch |

## CI/CD интеграция

### GitHub Actions

```yaml
name: Extract Project

on: [push]

jobs:
  extract:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Extract from Markdown
        run: python3 md_to_project.py docs/project.md -o ./src
      - name: Test
        run: pytest src/tests/
```

### GitLab CI

```yaml
extract-project:
  stage: build
  script:
    - python3 md_to_project.py docs/project.md -o ./src
    - cd src && pytest tests/
```

---

**Автор/Author:** [nedoletoff](https://github.com/nedoletoff)
**Лицензия/License:** MIT
