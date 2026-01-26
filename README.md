# Project to MD 📁→📄

[Русский](#%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9) | [English](#english)

## Русский

**Project to MD** - утилита для объединения файлов проекта в один Markdown документ. Идеально для отправки кода нейросетям, ChatGPT или аналогичным сервисам.

### 🎯 Для чего это нужно?

- 📤 **Отправка кода нейросетям** - весь проект в одном файле
- 📝 **Создание документации** - автоматическая генерация структуры с размерами файлов
- 🔍 **Обзор проекта** - быстрый просмотр всей кодовой базы
- 📊 **Анализ размеров** - видеть размер каждого файла в структуре проекта

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

```
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
- 📝 **Create documentation** - automatic structure generation with file sizes
- 🔍 **Project overview** - quick codebase review
- 📊 **Analyze file sizes** - see file sizes in project structure

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

```
node_modules/
*.log
.env
.DS_Store
```

---

## 🆕 Новое в этой версии / New in this version

### ✨ Отображение размеров файлов / File Size Display

**Русский:**
Теперь структура проекта показывает размер каждого файла:
- Автоматическое форматирование размеров (B, KB, MB, GB, TB)
- Правильное округление для читаемости
- Помогает оценить размер проекта и отдельных компонентов

**English:**
Project structure now displays file sizes:
- Automatic size formatting (B, KB, MB, GB, TB)
- Proper rounding for readability
- Helps evaluate project size and individual components

### Примеры вывода / Output examples

**Before / До:**
```
Project Structure
```
├── README.md
├── requirements.txt
└── src/
    ├── main.py
    └── config.py
```

**After / После:**
```
Project Structure
```
├── README.md (12.5 KB)
├── requirements.txt (342 B)
└── src/
    ├── main.py (35.2 KB)
    └── config.py (8.3 KB)
```

---

## 📋 Особенности / Features

✅ **Отображение размеров файлов** - каждый файл с указанием размера
✅ **Автоматическое создание директорий** - создаёт вложенные папки если их нет
✅ **Умная фильтрация** - пропускает бинарные файлы (.pyc, .so и т.д.)
✅ **Сохранение прав доступа** - автоматически делает `.sh` файлы исполняемыми
✅ **Обработка ошибок** - подробный вывод ошибок с кодом
✅ **UTF-8 поддержка** - правильно обрабатывает русский текст и Emoji
✅ **Кроссплатформенность** - работает везде (Python, Bash, Batch)
✅ **Нет зависимостей** - Python версия использует только встроенные модули

---

## 🛠️ Установка / Installation

### Python версия (рекомендуется)

```bash
# Скачать
curl -O https://raw.githubusercontent.com/nedoletoff/project_to_md/main/project_to_md.py

# Использовать
python3 project_to_md.py /path/to/project -o project.md
```

### Bash версия (Linux/macOS)

```bash
# Скачать
curl -O https://raw.githubusercontent.com/nedoletoff/project_to_md/main/project_to_md.sh
chmod +x project_to_md.sh

# Использовать
./project_to_md.sh /path/to/project -o project.md
```

### Batch версия (Windows)

```batch
REM Скачать
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/nedoletoff/project_to_md/main/project_to_md.bat', 'project_to_md.bat')"

REM Использовать
project_to_md.bat C:\path\to\project -o project.md
```

---

## 📞 Требования / Requirements

### Python версия
- Python 3.6 или выше
- ОС: Windows, macOS, Linux
- Зависимости: встроенные модули

### Bash версия
- Bash 4.0 или выше
- ОС: macOS, Linux, WSL на Windows
- Утилиты: awk, sed, find

### Batch версия
- Windows 7 или выше
- PowerShell 3.0 или выше

---

## ⚖️ Лицензия / License

MIT

---

## 👨‍💻 Автор / Author

[nedoletoff](https://github.com/nedoletoff)
