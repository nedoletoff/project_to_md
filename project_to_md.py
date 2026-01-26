import os
import argparse
import fnmatch

def format_file_size(size_bytes):
    """Format file size in human-readable format, similar to du -h"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024:
            return f"{int(round(size_bytes))} {unit}"
        else:
            size_bytes /= 1024
    return f"{int(round(size_bytes))} PB"

def get_directory_size(path):
    """Calculate total size of directory including all files"""
    total_size = 0
    try:
        for dirpath, dirnames, filenames in os.walk(path):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                try:
                    total_size += os.path.getsize(filepath)
                except OSError:
                    pass
    except (OSError, PermissionError):
        pass
    return total_size

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
            dir_size = get_directory_size(entry_path)
                        size_str = format_file_size(dir_size)
                        items.append(f"{prefix}{connector}{entry}/ ({size_str})\n")
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
        md.write(f"*Generated by Project to MD tool* \n")
        md.write(f"*Total files processed: {file_count}* \n")
        
        if ignore_file_path and os.path.exists(ignore_file_path):
            md.write(f"*Ignore file used: {ignore_file_path}* \n")

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
