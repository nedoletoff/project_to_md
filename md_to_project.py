#!/usr/bin/env python3

"""
MD to Project - утилита для распаковки проекта из Markdown документа

Противоположность project_to_md - распаковывает вложенные файлы проекта 
в отдельные файлы в директорию.

Использование:
    ./md_to_project.py project_documentation.md
    ./md_to_project.py project_documentation.md -o ./output_dir
    ./md_to_project.py -f project_documentation.md -o ./my_project

Поддерживаемые форматы:
    - Markdown файлы со встроенным кодом в блоках ```language
    - Структура:
        ## File Contents
        `/filename`
        ```language
        content
        ```

Требования:
    - Python 3.6+
    - Встроенные модули (нет зависимостей)

Автор: nedoletoff
Лицензия: MIT
"""

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Dict, Optional


class MarkdownToProject:
    """Распаковка проекта из Markdown документа."""

    VERSION = "1.0.0"

    def __init__(self, markdown_file: str, output_dir: str = "./extracted_project"):
        """
        Инициализация парсера.

        Args:
            markdown_file: путь к Markdown файлу с проектом
            output_dir: директория для распаковки файлов
        """
        self.markdown_file = Path(markdown_file)
        self.output_dir = Path(output_dir)
        self.files_extracted = 0
        self.files_skipped = 0
        self.errors = []

        if not self.markdown_file.exists():
            raise FileNotFoundError(f"Markdown файл не найден: {markdown_file}")

    def read_markdown(self) -> str:
        """Чтение содержимого Markdown файла."""
        with open(self.markdown_file, "r", encoding="utf-8") as f:
            return f.read()

    def extract_files(self) -> Dict[str, str]:
        """
        Извлечение всех файлов из Markdown.

        Возвращает словарь: {filename: content}
        """
        content = self.read_markdown()
        files = {}

        # Регулярное выражение для поиска файлов
        # Ищет: `(/path/to/file)` или `/path/to/file`
        pattern = r"`(/[^`\n]+)`\s*\n\s*```[\w]*\n(.*?)\n```"

        matches = re.finditer(pattern, content, re.DOTALL)

        for match in matches:
            filepath = match.group(1).strip()
            file_content = match.group(2)

            # Очистка контента
            file_content = file_content.rstrip()

            files[filepath] = file_content

        return files

    def create_files(self, files: Dict[str, str]) -> None:
        """
        Создание файлов в выходной директории.

        Args:
            files: словарь с путями и содержимым файлов
        """
        self.output_dir.mkdir(parents=True, exist_ok=True)

        print(f"\n📁 Распаковка файлов в: {self.output_dir.absolute()}\n")

        for filepath, content in sorted(files.items()):
            # Нормализация пути
            normalized_path = filepath.lstrip("/")
            full_path = self.output_dir / normalized_path

            # Создание директорий
            full_path.parent.mkdir(parents=True, exist_ok=True)

            # Проверка: содержимое похоже на бинарные данные?
            if self._is_binary_content(content):
                print(f"⏭️  {filepath} (пропущен - бинарные данные)")
                self.files_skipped += 1
                continue

            # Запись файла
            try:
                with open(full_path, "w", encoding="utf-8") as f:
                    f.write(content)

                # Если это скрипт - делаем его исполняемым
                if filepath.endswith(".sh"):
                    os.chmod(full_path, 0o755)

                size = len(content.encode("utf-8"))
                size_str = self._format_size(size)

                print(f"✅ {filepath:45} ({size_str})")
                self.files_extracted += 1

            except Exception as e:
                error_msg = f"❌ {filepath} - Ошибка: {str(e)}"
                print(error_msg)
                self.errors.append(error_msg)
                self.files_skipped += 1

    @staticmethod
    def _is_binary_content(content: str) -> bool:
        """Проверка, похоже ли содержимое на бинарные данные (pyc файл и т.д.)."""
        if len(content) < 10:
            return False

        # Проверка на нулевые байты (для .pyc файлов и других бинарных форматов)
        if "\x00" in content:
            return True

        # Проверка на странные символы
        non_printable = sum(1 for c in content if ord(c) < 32 and c not in "\n\r\t")
        if non_printable > len(content) * 0.1:  # Более 10% непечатных символов
            return True

        return False

    @staticmethod
    def _format_size(size: int) -> str:
        """Форматирование размера файла."""
        if size < 1024:
            return f"{size}B"
        elif size < 1024 * 1024:
            return f"{size / 1024:.1f}KB"
        else:
            return f"{size / (1024 * 1024):.1f}MB"

    def print_summary(self) -> None:
        """Вывод статистики."""
        print("\n" + "=" * 70)
        print(f"✨ Готово!")
        print("=" * 70)
        print(f"📦 Файлов распаковано: {self.files_extracted}")
        print(f"⏭️  Файлов пропущено:   {self.files_skipped}")
        if self.errors:
            print(f"⚠️  Ошибок:            {len(self.errors)}")
            for error in self.errors:
                print(f"   {error}")
        print(f"📍 Директория:         {self.output_dir.absolute()}")
        print("=" * 70 + "\n")

    def run(self) -> bool:
        """Запуск процесса распаковки."""
        try:
            print(f"\n📖 Чтение Markdown: {self.markdown_file.name}")
            files = self.extract_files()
            print(f"   Найдено файлов: {len(files)}")

            if not files:
                print("❌ Файлы не найдены в Markdown")
                return False

            self.create_files(files)
            self.print_summary()

            return self.files_extracted > 0

        except Exception as e:
            print(f"❌ Критическая ошибка: {e}")
            return False


def main():
    """Главная функция."""
    parser = argparse.ArgumentParser(
        description="Распаковка проекта из Markdown документа",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
  ./md_to_project.py project_documentation.md
  ./md_to_project.py -f project.md -o ./my_project
  python3 md_to_project.py project_documentation.md --output output_dir
        """,
    )

    parser.add_argument(
        "markdown_file",
        nargs="?",
        help="Путь к Markdown файлу с проектом",
    )

    parser.add_argument(
        "-f",
        "--file",
        dest="markdown_file_alt",
        help="Путь к Markdown файлу (альтернативный способ)",
    )

    parser.add_argument(
        "-o",
        "--output",
        default="./extracted_project",
        help="Директория для распаковки (по умолчанию: ./extracted_project)",
    )

    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"%(prog)s {MarkdownToProject.VERSION}",
    )

    args = parser.parse_args()

    # Определение файла
    markdown_file = args.markdown_file or args.markdown_file_alt

    if not markdown_file:
        parser.print_help()
        sys.exit(1)

    # Запуск распаковки
    try:
        extractor = MarkdownToProject(markdown_file, args.output)
        success = extractor.run()
        sys.exit(0 if success else 1)

    except FileNotFoundError as e:
        print(f"❌ {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Неожиданная ошибка: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
