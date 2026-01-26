# Project Documentation: project_to_md

## Project Structure

```
├── README.md (5.49 KB)
├── LICENSE (1.1 KB)
├── project_to_md.py (9.38 KB)
├── project_to_md.sh (6.3 KB)
├── project_to_md.bat (4.2 KB)
├── run.sh (1.2 KB)
├── run.bat (1.5 KB)
└── project_documentation.md (66.2 KB)
```

## File Contents

`/README.md`

```markdown
# Project to MD 📁→📄

[Русский](#%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9) | [English](#english)

## Русский

**Project to MD** - утилита для объединения файлов проекта в один Markdown документ. Идеально для отправки кода нейросетям, ChatGPT или аналогичным сервисам.

### 🎯 Для чего это нужно?

- 📤 **Отправка кода нейросетям** - весь проект в одном файле
- 📝 **Создание документации** - автоматическая генерация структуры с размерами файлов
- 🔍 **Обзор проекта** - быстрый просмотр всей кодовой базы
- 📊 **Анализ размеров** - видеть размер каждого файла в структуре проекта
```

`/LICENSE`

```text
MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

`/project_to_md.py`

```python
import os
import argparse
import fnmatch

def format_file_size(size_bytes):
    """Format file size in human-readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}" if size_bytes >= 100 else f"{int(size_bytes)} {unit}"
        if size_bytes >= 1024:
            size_bytes /= 1024
    return f"{size_bytes:.1f} TB"

def read_ignore_patterns(ignore_file_path):
    """Read and parse .ignore file"""
    patterns = []
    
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
                    if not line or line.startswith('#'):
                        continue
                    
                    pattern = line.strip()
                    patterns.append(pattern)
                    
                    if pattern.endswith('/'):
                        patterns.append(pattern + '*')
                        patterns.append(pattern[:-1])
        except Exception as e:
            print(f"Warning: Could not read ignore file '{ignore_file_path}': {e}")
    
    return patterns

def should_ignore(path, ignore_patterns):
    """Check if file/folder should be ignored"""
    normalized_path = path.replace('\\', '/')
    basename = os.path.basename(path)
    
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(normalized_path, pattern):
            return True
        if fnmatch.fnmatch(basename, pattern):
            return True
        path_parts = normalized_path.split('/')
        for part in path_parts:
            if fnmatch.fnmatch(part, pattern):
                return True
    return False

def build_tree_structure(root_dir, ignore_patterns, prefix=''):
    """Build tree structure of directories and files WITH FILE SIZES"""
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
            try:
                file_size = os.path.getsize(entry_path)
                size_str = format_file_size(file_size)
                items.append(f"{prefix}{connector}{entry} ({size_str})\n")
            except OSError:
                items.append(f"{prefix}{connector}{entry}\n")
    
    return ''.join(items)
```

---

## Updated Features

### New: File Size Display

✨ **Version 2.0+** includes automatic file size display in project structure:

- **Format**: Files now show size (e.g., "README.md (12.5 KB)")
- **Auto-formatting**: Sizes automatically convert to B, KB, MB, GB, or TB
- **Smart rounding**: Proper decimal places for readability
- **No external deps**: Uses only Python standard library

### Example Output

**Before**:
```
Project Structure
├── README.md
├── requirements.txt
└── src/
    ├── main.py
    └── config.py
```

**After**:
```
Project Structure
├── README.md (12.5 KB)
├── requirements.txt (342 B)
└── src/
    ├── main.py (35.2 KB)
    └── config.py (8.3 KB)
```

---

*Generated by Project to MD tool*
*Updated with file size display feature*
*Total files: 7*
