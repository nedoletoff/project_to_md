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

**Автор/Author:** [nedoletoff](https://github.com/nedoletoff)
**Лицензия/License:** MIT
