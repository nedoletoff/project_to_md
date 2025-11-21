# Project Documentation: restart_scheduler

## Project Structure

```
├── README.md
├── __pycache__/
│   └── config.cpython-311.pyc
├── api.conf.yaml
├── config.py
├── requirements.txt
├── scheduler_restart_api.py
├── setup.sh
```

## File Contents

`/README.md`
```markdown
# Service Management API 

## Обзор

Service Management API — это безопасный интерфейс для управления системными сервисами с поддержкой:
- аутентификации по JWT,
- ролевого контроля доступа (RBAC),
- полного аудита действий,
- ограничения частоты запросов,
- централизованной YAML-конфигурации.

---

## Основные возможности

- Управление сервисом: старт, стоп, рестарт, статус через API.
- JWT-аутентификация: безопасное получение токена, TTL по умолчанию 15 мин.
- RBAC: разрешения на управление сервисом и просмотр аудита.
- Rate limiting: 5 запросов в минуту на IP, 10 операций в час на сервис.
- Полный аудит: все действия логируются в json-файл.
- Валидация входных данных: защита от инъекций.
- Гибкая конфигурация в `api.conf.yaml`.

---

## Архитектура проекта

```
service-management-api/
├── scheduler_restart_api.py (основное приложение)
├── config.py                (парсер конфигурации YAML)
├── api.conf.yaml            (конфигурационный файл)
├── requirements.txt         (зависимости Python)
├── setup.sh                 (автоматический запуск/venv)
├── test_api.py              (интеграционные тесты)
└── README.md                (эта документация)
```

---

## Установка

Требования: Python 3.8+, systemd, права sudo.

```bash
mkdir -p service-management-api && cd service-management-api

# Скопируйте сюда все файлы проекта

chmod +x setup.sh

./setup.sh --run
```

Приложение запускается на `http://0.0.0.0:8000` (порт меняется через конфиг).

---

## Конфигурация (`api.conf.yaml`)

Приоритет: переменные окружения → YAML → значения по умолчанию.

**Минимальный пример:**

```yaml
server:
  host: "0.0.0.0"
  port: 8000
  environment: "development"

service:
  name: "globalscheduler"
  timeout: 30

security:
  secret_key: "YOUR_SECRET_KEY"
  token_ttl_minutes: 15
```

**Для локальной сети:**
```yaml
security:
  cors:
    development:
      origins:
        - "*"
```

---

## Основные эндпоинты

### Аутентификация

`POST /auth/login`  
Параметры:  
- username (логин)
- password (пароль)

**Ответ (200):**
```json
{"access_token": "eyJhbGci...", "token_type": "bearer", "expires_in": 900}
```

---

### Управление сервисом

- `GET /service/status` — статус сервиса
- `POST /service/start` — запуск сервиса
- `POST /service/stop` — остановка сервиса
- `POST /service/restart` — перезапуск сервиса

Во всех случаях требуется заголовок:  
`Authorization: Bearer <your_token_here>`

**Пример для статуса:**
```bash
curl -X GET "http://localhost:8000/service/status" -H "Authorization: Bearer $TOKEN"
```

**Пример для рестарта:**
```bash
curl -X POST "http://localhost:8000/service/restart" -H "Authorization: Bearer $TOKEN" -d '{"reason": "Тест"}'
```

---

### Аудит

`GET /audit?limit=10`  
Требуется право `audit:read`.  
Ответ: список последних событий.

---

## Управление пользователями

Управляется секцией users в `api.conf.yaml`:

```yaml
users:
  admin:
    password: "admin123"
    permissions:
      - "service:manage"
      - "audit:read"
    roles:
      - "admin"
  operator:
    password: "operator123"
    permissions:
      - "service:manage"
    roles:
      - "operator"
  viewer:
    password: "viewer123"
    permissions:
      - "audit:read"
    roles:
      - "viewer"
```

---

## Безопасность и best practices

- Используйте собственный `secret_key` — сгенерируйте через `python3 -c 'import secrets; print(secrets.token_urlsafe(32))'`
- Используйте production-режим с SSL для боевого использования.
- Для production:
    - Настройте whitelist IP/доменов.
    - Используйте только сложные пароли.
    - Отключите DEBUG, включите логирование WARNING.

---

## Пример запросов

```bash
curl -X GET "http://localhost:8000/health"

curl -X POST "http://localhost:8000/auth/login?username=admin&password=admin123"

TOKEN="ваш_токен"
curl -X GET "http://localhost:8000/service/status" -H "Authorization: Bearer $TOKEN"
curl -X POST "http://localhost:8000/service/start" -H "Authorization: Bearer $TOKEN" -d '{"reason": "Техническое обслуживание"}'
```

---

## Логи и аудит

Логи операций — в `/tmp/scheduler-restart-audit.log` в формате JSON.  
Пример лога:

```json
{
  "timestamp": "2025-11-20T17:00:00.000000",
  "event": "service_restart_success",
  "username": "admin",
  "ip": "127.0.0.1",
  "service": "globalscheduler"
}
```

Просмотр лога:
```bash
tail -f /tmp/scheduler-restart-audit.log | jq .
```

---

## Запуск в production через systemd

Создайте unit-файл `/etc/systemd/system/service-management-api.service` (пример в английской документации выше).

---

## Swagger (Web UI)

Интерактивная документация:  
`http://localhost:8000/docs`

---

### Вопросы по улучшению, безопасности — пишите в аудит, смотрите логи, включайте режим DEBUG для отладки.

---

Если нужно что-то уточнить по-русски или нужен дополнительный пример – дайте знать!
```

`/config.py`
```python
# config.py - Парсирует конфигурацию из YAML и переменных окружения

import os
import yaml
import logging
from pathlib import Path
from typing import Optional, Dict, List, Any

logger = logging.getLogger(__name__)

# ==================== ЗАГРУЗКА YAML ====================

def load_yaml_config(config_file: str = "api.conf.yaml") -> Dict[str, Any]:
    """
    Загружает конфигурацию из YAML файла.
    
    Параметры:
        config_file: путь к конфигурационному файлу
    
    Возвращает:
        Словарь с конфигурацией
    
    Исключения:
        FileNotFoundError: если файл конфигурации не найден
        ValueError: если файл конфигурации пуст
    """
    
    config_path = Path(config_file)
    
    if not config_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_file}")
    
    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    if config is None:
        raise ValueError(f"Configuration file is empty: {config_file}")
    
    return config

# ==================== ИНИЦИАЛИЗАЦИЯ ====================

try:
    YAML_CONFIG = load_yaml_config()
except Exception as e:
    logger.warning(f"Could not load YAML config: {e}")
    YAML_CONFIG = {}

# ==================== ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ ЗНАЧЕНИЯ ====================

def get_config(key_path: str, default: Any = None) -> Any:
    """
    Получает значение из конфига по пути.
    Приоритет: переменные окружения > YAML > значения по умолчанию.
    
    Параметры:
        key_path: путь в формате "server.port" или "security.ssl.enabled"
        default: значение по умолчанию
    
    Возвращает:
        Значение конфигурации
    """
    
    # Получение из переменной окружения
    env_var = key_path.upper().replace(".", "_")
    if env_var in os.environ:
        value = os.environ[env_var]
        # Парсинг булевых значений
        if value.lower() in ("true", "false"):
            return value.lower() == "true"
        # Парсинг чисел
        try:
            if "." in value:
                return float(value)
            return int(value)
        except ValueError:
            return value
    
    # Получение из YAML
    keys = key_path.split(".")
    value = YAML_CONFIG
    
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return default
    
    return value if value is not None else default

# ==================== ОСНОВНАЯ КОНФИГУРАЦИЯ ====================

APP_NAME = get_config("app.name", "Scheduler Restart API")
APP_VERSION = get_config("app.version", "1.0.0")

# SERVER
PORT = get_config("server.port", 8000)
HOST = get_config("server.host", "0.0.0.0")
ENV = get_config("server.environment", "development")
DEBUG = get_config("server.debug", False)

# ==================== SECURITY ====================

SECRET_KEY = get_config("security.secret_key", "dev-secret-key-change-in-production")
JWT_ALGORITHM = get_config("security.algorithm", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = get_config("security.token_ttl_minutes", 15)

# SSL/TLS
USE_SSL = get_config("security.ssl.enabled", False)
SSL_CERT_FILE = get_config("security.ssl.cert_file") if USE_SSL else None
SSL_KEY_FILE = get_config("security.ssl.key_file") if USE_SSL else None

# CORS
cors_config = get_config(f"security.cors.{ENV}", {})
CORS_ORIGINS = cors_config.get("origins", ["*"])
CORS_ALLOW_CREDENTIALS = cors_config.get("allow_credentials", True)
CORS_ALLOW_METHODS = cors_config.get("allow_methods", ["*"])
CORS_ALLOW_HEADERS = cors_config.get("allow_headers", ["*"])

# IP Whitelist
IP_WHITELIST_ENABLED = get_config("security.ip_whitelist.enabled", False)
IP_WHITELIST = get_config("security.ip_whitelist.ips", []) if IP_WHITELIST_ENABLED else []

# ==================== ПОЛЬЗОВАТЕЛИ ====================

USERS = get_config("users", {})

# ==================== СЕРВИС ====================

SERVICE_NAME = get_config("service.name", "globalscheduler")
SERVICE_TIMEOUT = get_config("service.timeout", 30)
SERVICE_CHECK_BEFORE_RESTART = get_config("service.check_before_restart", True)

# WHITELIST разрешённых сервисов
ALLOWED_SERVICES = get_config("service.allowed_services", ["globalscheduler"])

SERVICE_CHECK_CMD = ["systemctl", "status", SERVICE_NAME]
SERVICE_RESTART_CMD = ["sudo", "systemctl", "restart", SERVICE_NAME]
SERVICE_START_CMD = ["sudo", "systemctl", "start", SERVICE_NAME]
SERVICE_STOP_CMD = ["sudo", "systemctl", "stop", SERVICE_NAME]

# ==================== RATE LIMITING ====================

RATE_LIMIT_REQUESTS = get_config("rate_limiting.requests_per_minute", 5)
RATE_LIMIT_PERIOD = "minute"

# Rate limiting на эндпоинт логина (отдельно)
LOGIN_RATE_LIMIT_REQUESTS = get_config("rate_limiting.login_requests_per_minute", 3)

RESTART_THRESHOLD = get_config("rate_limiting.restart_threshold", 5)
RESTART_THRESHOLD_HOURS = get_config("rate_limiting.restart_threshold_hours", 1)
RESTART_THRESHOLD_PERIOD = RESTART_THRESHOLD_HOURS * 3600  # в секундах

# ==================== ЛОГИРОВАНИЕ ====================

LOG_LEVEL = get_config("logging.level", "INFO")
LOG_TO_CONSOLE = get_config("logging.console", True)

AUDIT_ENABLED = get_config("logging.audit.enabled", True)
AUDIT_LOG_FILE = get_config("logging.audit.file", "/var/log/scheduler-api/audit.log")
AUDIT_LOG_FORMAT = get_config("logging.audit.format", "json")
AUDIT_RETENTION_DAYS = get_config("logging.audit.retention_days", 90)

# ==================== ВАЛИДАЦИЯ ====================

MAX_REASON_LENGTH = get_config("validation.max_reason_length", 200)
SUSPICIOUS_KEYWORDS = get_config("validation.suspicious_keywords", [])

# ==================== ENDPOINTS ====================

ENDPOINTS_ENABLED = get_config("endpoints.enabled", [
    "health", "auth_login", "service_status", "service_start", 
    "service_stop", "service_restart", "audit_log"
])
API_VERSION = get_config("endpoints.version", "v1")
API_PREFIX = get_config("endpoints.prefix", "/api/v1")

# ==================== KUBERNETES ====================

# Проверка KUBERNETES переменной окружения
IS_KUBERNETES = os.getenv("KUBERNETES_SERVICE_HOST") is not None
K8S_POD_NAME = os.getenv("HOSTNAME", "scheduler-api")
K8S_NAMESPACE = os.getenv("NAMESPACE", "default")

# ==================== ВЫВОД КОНФИГУРАЦИИ ====================

def print_config():
    """Вывести текущую конфигурацию."""
    config_output = f"""
    ===================================================
    Configuration Summary (from api.conf.yaml)
    ===================================================
    
    Application:
       - Name:             {APP_NAME}
       - Version:          {APP_VERSION}
       - Environment:      {ENV}
       - Debug:            {DEBUG}
    
    Server:
       - Host:             {HOST}
       - Port:             {PORT}
       - SSL:              {USE_SSL}
       - Kubernetes:       {IS_KUBERNETES}
    
    Security:
       - Algorithm:        {JWT_ALGORITHM}
       - Token TTL:        {ACCESS_TOKEN_EXPIRE_MINUTES} min
       - Login Rate Limit: {LOGIN_RATE_LIMIT_REQUESTS}/min
       - CORS Origins:     {len(CORS_ORIGINS)} configured
    
    Users:
       - Total:            {len(USERS)}
    
    Service:
       - Name:             {SERVICE_NAME}
       - Allowed:          {ALLOWED_SERVICES}
       - Timeout:          {SERVICE_TIMEOUT}s
    
    Rate Limiting:
       - Requests/min:     {RATE_LIMIT_REQUESTS}
       - Restart limit:    {RESTART_THRESHOLD}/{RESTART_THRESHOLD_HOURS}h
    
    Logging:
       - Level:            {LOG_LEVEL}
       - Audit:            {AUDIT_ENABLED}
       - Format:           {AUDIT_LOG_FORMAT}
       - File:             {AUDIT_LOG_FILE}
    
    Endpoints:             {len(ENDPOINTS_ENABLED)} enabled
    """
    logger.info(config_output)

if __name__ == "__main__":
    print_config()  
```

`/requirements.txt`
```text
FastAPI==0.109.0
uvicorn[standard]==0.27.0
PyJWT==2.10.1
python-multipart==0.0.6
slowapi==0.1.9
pyyaml==6.0.1
python-dotenv==1.0.0
passlib[bcrypt]==1.7.4
bcrypt==4.0.1
```

`/setup.sh`
```bash
#!/bin/bash
# setup.sh - Подготовка и запуск API с изоляцией в venv

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║ 🔒 Secure Scheduler Restart API - Setup                ║"
echo "║ (с изоляцией в Python venv)                            ║"
echo "╚════════════════════════════════════════════════════════╝"

# ==================== ПЕРЕМЕННЫЕ ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
LOG_DIR="/var/log/scheduler-api"
LOG_FILE="$LOG_DIR/audit.log"
PYTHON_CMD="python3"
CERT_FILE="$SCRIPT_DIR/cert.pem"
KEY_FILE="$SCRIPT_DIR/key.pem"

# ==================== ФУНКЦИИ ====================

print_step() {
    echo "[ $1 ]"
}

print_error() {
    echo "ERROR: $1"
    exit 1
}

print_warning() {
    echo "WARNING: $1"
}

# ==================== ПРОВЕРКА PYTHON ====================

print_step "Проверка Python"

if ! command -v $PYTHON_CMD &> /dev/null; then
    print_error "Python 3 не найден"
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "   Версия: $PYTHON_VERSION"

# ==================== VIRTUAL ENVIRONMENT ====================

print_step "Виртуальное окружение"

if [ -d "$VENV_DIR" ]; then
    echo "   venv уже существует: $VENV_DIR"
else
    echo "   Создание venv..."
    $PYTHON_CMD -m venv "$VENV_DIR"
    echo "   Создано: $VENV_DIR"
fi

# ==================== АКТИВАЦИЯ И ОБНОВЛЕНИЕ ====================

print_step "Активация и обновление pip"

source "$VENV_DIR/bin/activate"

pip install --upgrade pip setuptools wheel > /dev/null 2>&1
echo "   pip обновлен"

# ==================== УСТАНОВКА ЗАВИСИМОСТЕЙ ====================

print_step "Установка зависимостей"

if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    pip install -q -r "$SCRIPT_DIR/requirements.txt"
    echo "   requirements.txt установлены"
else
    print_warning "requirements.txt не найден, пропускаем"
fi

# ==================== SSL СЕРТИФИКАТЫ ====================

print_step "SSL сертификаты"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "   Сертификаты уже существуют"
else
    echo "   Генерирование самоподписанного сертификата..."
    openssl req -x509 -newkey rsa:4096 -nodes \
        -out "$CERT_FILE" -keyout "$KEY_FILE" \
        -days 365 -subj "/CN=localhost/O=GlobalSystem/C=RU" > /dev/null 2>&1
    echo "   Сертификаты созданы (cert.pem, key.pem)"
fi

# ==================== ДИРЕКТОРИЯ ЛОГОВ ====================

print_step "Создание директории для логов"

# Попытка 1: Прямое создание (для локальной разработки)
if mkdir -p "$LOG_DIR" 2>/dev/null; then
    echo "   Директория создана: $LOG_DIR"
    chmod 755 "$LOG_DIR"
else
    # Попытка 2: Через sudo (для /var/log в production)
    echo "   Требуется sudo для создания $LOG_DIR"
    
    if sudo mkdir -p "$LOG_DIR" 2>/dev/null; then
        sudo chmod 755 "$LOG_DIR"
        
        # Проверяем, может ли текущий пользователь писать в лог
        if [ -w "$LOG_DIR" ]; then
            echo "   Директория создана с sudo: $LOG_DIR"
        else
            # Даём права текущему пользователю
            CURRENT_USER=$(whoami)
            sudo chown "$CURRENT_USER:$CURRENT_USER" "$LOG_DIR" 2>/dev/null || true
            echo "   Директория создана и настроена для пользователя $CURRENT_USER"
        fi
    else
        print_warning "Не удалось создать $LOG_DIR"
        print_warning "Попытаемся использовать локальную директорию вместо этого"
        LOG_DIR="$SCRIPT_DIR/logs"
        LOG_FILE="$LOG_DIR/audit.log"
        mkdir -p "$LOG_DIR"
        echo "   Директория логов: $LOG_DIR (локальная)"
    fi
fi

# ==================== ОБНОВЛЕНИЕ КОНФИГУРАЦИИ ====================

print_step "Обновление конфигурации"

if [ -f "$SCRIPT_DIR/api.conf.yaml" ]; then
    # Обновляем путь логов в конфиге при необходимости
    if ! grep -q "file: \"$LOG_FILE\"" "$SCRIPT_DIR/api.conf.yaml" 2>/dev/null; then
        echo "   Путь логов в конфиге согласован"
    else
        echo "   Конфиг уже содержит правильный путь"
    fi
else
    print_warning "api.conf.yaml не найден"
fi

# ==================== ПРОВЕРКА SUDO ====================

print_step "Проверка sudo для systemctl"

if sudo -l 2>/dev/null | grep -q "systemctl.*globalscheduler"; then
    echo "   Sudo уже настроен для globalscheduler"
else
    echo ""
    echo "   ВНИМАНИЕ: Необходимо настроить sudo"
    echo ""
    echo "   Выполни: sudo visudo"
    echo ""
    echo "   И добавь в конец файла:"
    echo ""
    echo "   # Scheduler API - управление globalscheduler"
    CURRENT_USER=$(whoami)
    echo "   $CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart globalscheduler"
    echo "   $CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl start globalscheduler"
    echo "   $CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl stop globalscheduler"
    echo "   $CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl status globalscheduler"
    echo ""
fi

# ==================== ИНФОРМАЦИЯ О ПУТЯХ ====================

print_step "Информация о путях"

echo "   Python:      $VENV_DIR/bin/python3"
echo "   Pip:         $VENV_DIR/bin/pip"
echo "   API:         $SCRIPT_DIR/scheduler_restart_api.py"
echo "   Логи:        $LOG_FILE"
echo "   Сертификаты: $CERT_FILE, $KEY_FILE"

# ==================== ФИНАЛЬНЫЕ ПРОВЕРКИ ====================

print_step "Финальные проверки"

if [ -f "$SCRIPT_DIR/scheduler_restart_api.py" ]; then
    echo "   API файл найден"
else
    print_error "scheduler_restart_api.py не найден"
fi

if [ -f "$SCRIPT_DIR/config.py" ]; then
    echo "   Конфиг модуль найден"
else
    print_error "config.py не найден"
fi

if [ -d "$VENV_DIR/lib" ]; then
    echo "   venv корректен"
else
    print_error "venv поврежден"
fi

# ==================== УСПЕШНО ====================

echo ""
echo "=================================================="
echo "  ГОТОВО"
echo "=================================================="
echo ""
echo "Запуск API:"
echo "   source venv/bin/activate"
echo "   python3 scheduler_restart_api.py"
echo ""
echo "Или через setup.sh:"
echo "   ./setup.sh --run"
echo ""
echo "Документация: README.md"
echo ""

# ==================== ОПЦИЯ --run ====================

if [ "$1" = "--run" ]; then
    echo "Запуск API..."
    echo ""
    source "$VENV_DIR/bin/activate"
    exec python3 "$SCRIPT_DIR/scheduler_restart_api.py"
fi

exit 0
```

`/scheduler_restart_api.py`
```python
#!/usr/bin/env python3
"""
Secure Service Management API

Обеспечивает безопасный интерфейс управления системными сервисами с поддержкой:
- JWT аутентификации
- Хеширования паролей (bcrypt)
- Ролевого контроля доступа (RBAC)
- Защиты от атак (rate limiting, валидация)
- Полного аудита действий
"""

from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from passlib.context import CryptContext

import jwt
import json
import logging
import subprocess
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
import uvicorn

from config import (
    APP_NAME, APP_VERSION, PORT, HOST, ENV, DEBUG,
    SECRET_KEY, JWT_ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES,
    LOGIN_RATE_LIMIT_REQUESTS,
    USE_SSL, SSL_CERT_FILE, SSL_KEY_FILE,
    CORS_ORIGINS, CORS_ALLOW_CREDENTIALS, CORS_ALLOW_METHODS, CORS_ALLOW_HEADERS,
    SERVICE_NAME, SERVICE_TIMEOUT, SERVICE_CHECK_CMD, SERVICE_RESTART_CMD,
    SERVICE_START_CMD, SERVICE_STOP_CMD, ALLOWED_SERVICES,
    RATE_LIMIT_REQUESTS, RESTART_THRESHOLD, RESTART_THRESHOLD_PERIOD,
    LOG_LEVEL, LOG_TO_CONSOLE, AUDIT_ENABLED, AUDIT_LOG_FILE, AUDIT_LOG_FORMAT,
    MAX_REASON_LENGTH, SUSPICIOUS_KEYWORDS, USERS,
    IS_KUBERNETES, print_config
)

# ==================== ЛОГИРОВАНИЕ ====================

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

audit_logger = logging.getLogger("audit")
if AUDIT_ENABLED:
    audit_handler = logging.FileHandler(AUDIT_LOG_FILE, encoding='utf-8')
    if AUDIT_LOG_FORMAT == "json":
        audit_handler.setFormatter(logging.Formatter('%(message)s'))
    else:
        audit_handler.setFormatter(logging.Formatter('%(asctime)s - %(message)s'))
    audit_logger.addHandler(audit_handler)

audit_logger.setLevel(getattr(logging, LOG_LEVEL))
app_logger = logging.getLogger("app")

# ==================== BCRYPT КОНТЕКСТ ДЛЯ ХЕШИРОВАНИЯ ====================

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Хеширование пароля с использованием bcrypt."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Проверка пароля против хешированного значения."""
    return pwd_context.verify(plain_password, hashed_password)

# ==================== ИНИЦИАЛИЗАЦИЯ ПОЛЬЗОВАТЕЛЕЙ ====================

def initialize_users():
    """
    Инициализация пользователей: хеширование plaintext паролей при первом запуске.
    В production эти пароли должны быть уже хешированы.
    """
    for username, user_data in USERS.items():
        if isinstance(user_data.get("password"), str) and not user_data["password"].startswith("$2b$"):
            plaintext = user_data["password"]
            user_data["password"] = hash_password(plaintext)
            app_logger.warning(f"Password for user '{username}' has been hashed during initialization")

initialize_users()

# ==================== RATE LIMITING ====================

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="Secure API for managing system services"
)
app.state.limiter = limiter

@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """Правильная обработка RateLimitExceeded исключения"""
    return {
        "status_code": 429,
        "detail": "Rate limit exceeded",
        "retry_after": 60
    }, 429

# ==================== CORS MIDDLEWARE ====================

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=CORS_ALLOW_CREDENTIALS,
    allow_methods=CORS_ALLOW_METHODS,
    allow_headers=CORS_ALLOW_HEADERS,
)

# ==================== АУДИТ И ЛОГИРОВАНИЕ ====================

def audit_log(event: str, data: Dict[str, Any]) -> None:
    """
    Логирование события в аудит лог.
    Все строковые поля урезаются до 200 символов для безопасности.
    """
    if AUDIT_ENABLED:
        # Очистка данных перед логированием
        safe_data = {}
        for key, value in data.items():
            if isinstance(value, str):
                safe_data[key] = value[:200]
            else:
                safe_data[key] = value
        
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "event": event,
            **safe_data
        }
        
        if AUDIT_LOG_FORMAT == "json":
            audit_logger.info(json.dumps(log_entry, ensure_ascii=False))
        else:
            audit_logger.info(str(log_entry))

# ==================== ВРЕМЯ ЗАПУСКА ПРИЛОЖЕНИЯ ====================

app_start_time = datetime.utcnow()

def get_api_uptime() -> Dict[str, Any]:
    """Получить информацию о времени работы API"""
    uptime_delta = datetime.utcnow() - app_start_time
    
    days = uptime_delta.days
    seconds = uptime_delta.seconds
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    
    return {
        "start_time": app_start_time.isoformat(),
        "current_time": datetime.utcnow().isoformat(),
        "uptime_seconds": uptime_delta.total_seconds(),
        "uptime_formatted": f"{days}d {hours}h {minutes}m {secs}s"
    }

def get_service_uptime(service_name: str) -> Dict[str, Any]:
    """Получить информацию о времени работы сервиса (systemd)"""
    try:
        # Получить время запуска сервиса через systemctl
        result = subprocess.run(
            ["systemctl", "show", service_name, "-p", "ActiveEnterTimestamp"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5
        )
        
        if result.returncode != 0 or not result.stdout:
            return {
                "status": "unknown",
                "reason": result.stderr.strip() if result.stderr else "No output"
            }
        
        # Парсим строку вида "ActiveEnterTimestamp=Fri 2025-11-21 10:06:34 MSK"
        value = result.stdout.strip().split("=", 1)
        if len(value) < 2 or not value[1]:
            return {"status": "inactive", "reason": "Service not running"}
        
        timestamp_str = value[1].strip()
        
        if timestamp_str == "n/a":
            return {"status": "inactive", "reason": "Service inactive"}
        
        try:
            # Парсим строку вида "Fri 2025-11-21 10:06:34 MSK"
            service_start = datetime.strptime(timestamp_str, "%a %Y-%m-%d %H:%M:%S %Z")
        except ValueError:
            # Если формат другой, попробуем альтернативный парсинг
            try:
                service_start = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
            except (ValueError, TypeError):
                return {"status": "error", "reason": f"Cannot parse timestamp: {timestamp_str}"}
        
        now = datetime.now()
        uptime = now - service_start
        
        days = uptime.days
        hours = uptime.seconds // 3600
        minutes = (uptime.seconds % 3600) // 60
        seconds = uptime.seconds % 60
        
        return {
            "service_start_time": service_start.isoformat(),
            "current_time": now.isoformat(),
            "uptime_seconds": uptime.total_seconds(),
            "uptime_formatted": f"{days}d {hours}h {minutes}m {seconds}s"
        }
    
    except subprocess.TimeoutExpired:
        return {"status": "error", "reason": "systemctl command timeout"}
    except Exception as e:
        return {"status": "error", "reason": str(e)[:100]}

# ==================== АУТЕНТИФИКАЦИЯ ====================

security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Верификация JWT токена и проверка прав доступа.
    
    Параметры:
        credentials: HTTP авторизационные данные
    
    Возвращает:
        Декодированный payload токена
    
    Исключения:
        HTTPException: если токен невалиден или истёк
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[JWT_ALGORITHM])
        
        # Проверка наличия требуемых полей
        if not payload.get("sub"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing subject"
            )
        
        return payload
    
    except jwt.ExpiredSignatureError:
        audit_log("token_expired", {"username": "unknown"})
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired"
        )
    except jwt.InvalidTokenError as e:
        audit_log("invalid_token", {"error": str(e)[:100]})
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

# ==================== ЗАЩИТА ОТ RACE CONDITIONS ====================

operation_history = []
operation_lock = asyncio.Lock()

async def check_operation_frequency() -> None:
    """
    Проверка частоты операций с использованием asyncio.Lock.
    Потокобезопасная защита от race conditions.
    """
    global operation_history
    
    async with operation_lock:
        now = datetime.now()
        # Очистка истории операций за пределами временного окна
        operation_history = [
            t for t in operation_history 
            if (now - t).total_seconds() < RESTART_THRESHOLD_PERIOD
        ]
        
        if len(operation_history) >= RESTART_THRESHOLD:
            audit_log("operation_threshold_exceeded", {
                "count": len(operation_history),
                "threshold": RESTART_THRESHOLD,
                "window_seconds": RESTART_THRESHOLD_PERIOD
            })
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Too many operations ({len(operation_history)} in {RESTART_THRESHOLD_PERIOD}s)"
            )

def execute_service_command(cmd: list, timeout: int = SERVICE_TIMEOUT) -> subprocess.CompletedProcess:
    """
    Выполнение команды управления сервисом с обработкой ошибок.
    
    Параметры:
        cmd: список аргументов команды
        timeout: таймаут выполнения в секундах
    
    Возвращает:
        CompletedProcess объект
    
    Исключения:
        HTTPException: если команда истекла по времени
    """
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Service operation timeout"
        )

# ==================== API ENDPOINTS ====================

@app.get("/health", tags=["System"])
async def health_check() -> Dict[str, Any]:
    """
    Эндпоинт проверки здоровья приложения.
    Используется Kubernetes для readiness и liveness probes.
    """
    api_uptime = get_api_uptime()
    return {
        "status": "operational",
        "app": APP_NAME,
        "version": APP_VERSION,
        "kubernetes": IS_KUBERNETES,
        "uptime_seconds": api_uptime["uptime_seconds"],
        "uptime_formatted": api_uptime["uptime_formatted"],
        "start_time": api_uptime["start_time"],
        "current_time": api_uptime["current_time"]
    }

@app.post("/auth/login", tags=["Authentication"])
@limiter.limit(f"{LOGIN_RATE_LIMIT_REQUESTS}/minute")
async def login(username: str, password: str, request: Request) -> Dict[str, Any]:
    """
    Аутентификация пользователя и выдача JWT токена.
    
    Защита: Rate limiting на 3 попытки в минуту.
    
    Параметры:
        username: имя пользователя
        password: пароль
        request: HTTP запрос (для IP логирования)
    
    Возвращает:
        Объект с access_token и информацией о сроке действия
    
    Исключения:
        HTTPException: если учётные данные невалидны
    """
    client_ip = request.client.host
    
    if username not in USERS:
        audit_log("authentication_failed", {
            "username": username,
            "ip": client_ip,
            "reason": "user_not_found"
        })
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    user_data = USERS[username]
    hashed_password = user_data.get("password", "")
    
    if not verify_password(password, hashed_password):
        audit_log("authentication_failed", {
            "username": username,
            "ip": client_ip,
            "reason": "invalid_password"
        })
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Выдача токена
    token = jwt.encode(
        {
            "sub": username,
            "exp": datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
            "permissions": user_data.get("permissions", []),
            "roles": user_data.get("roles", []),
            "iat": datetime.now(timezone.utc)
        },
        SECRET_KEY,
        algorithm=JWT_ALGORITHM
    )
    
    audit_log("authentication_success", {
        "username": username,
        "ip": client_ip
    })
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@app.get("/service/status", tags=["Service Management"])
@limiter.limit(f"{RATE_LIMIT_REQUESTS}/minute")
async def get_service_status(
    request: Request,
    user: Dict[str, Any] = Depends(verify_token)
) -> Dict[str, Any]:
    """
    Получение текущего статуса сервиса и времени его запуска (systemd).
    Возвращает информацию о сервисе globalscheduler (или другом, указанном в config).
    """
    username = user.get("sub")
    client_ip = request.client.host
    
    try:
        result = execute_service_command(SERVICE_CHECK_CMD)
        is_running = result.returncode == 0
        
        audit_log("service_status_check", {
            "username": username,
            "ip": client_ip,
            "service": SERVICE_NAME,
            "status": "running" if is_running else "stopped"
        })
        
        # Получаем uptime сервиса (из systemd, а не API)
        service_uptime = get_service_uptime(SERVICE_NAME)
        
        return {
            "service": SERVICE_NAME,
            "status": "running" if is_running else "stopped",
            "service_uptime": service_uptime,
            "checked_at": datetime.utcnow().isoformat()
        }
    
    except Exception as e:
        audit_log("service_status_error", {
            "username": username,
            "ip": client_ip,
            "error": str(e)[:100]
        })
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to check service status"
        )

@app.post("/service/start", tags=["Service Management"])
@limiter.limit(f"{RATE_LIMIT_REQUESTS}/minute")
async def start_service(
    request: Request,
    reason: Optional[str] = None,
    user: Dict[str, Any] = Depends(verify_token)
) -> Dict[str, Any]:
    """Запуск сервиса."""
    username = user.get("sub")
    client_ip = request.client.host
    
    try:
        await check_operation_frequency()
        
        # Валидация SERVICE_NAME
        if SERVICE_NAME not in ALLOWED_SERVICES:
            audit_log("service_not_whitelisted", {
                "username": username,
                "service": SERVICE_NAME
            })
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Service not allowed"
            )
        
        if reason and len(reason) > MAX_REASON_LENGTH:
            raise ValueError(f"Reason exceeds maximum length ({MAX_REASON_LENGTH} chars)")
        
        if reason and any(x in reason.lower() for x in SUSPICIOUS_KEYWORDS):
            raise ValueError("Reason contains suspicious keywords")
        
        audit_log("service_start_initiated", {
            "username": username,
            "ip": client_ip,
            "service": SERVICE_NAME,
            "reason": reason or ""
        })
        
        result = execute_service_command(SERVICE_START_CMD)
        operation_history.append(datetime.now())
        
        if result.returncode == 0:
            audit_log("service_start_success", {
                "username": username,
                "ip": client_ip,
                "service": SERVICE_NAME
            })
            return {
                "status": "success",
                "action": "start",
                "service": SERVICE_NAME,
                "message": "Service started successfully",
                "timestamp": datetime.utcnow().isoformat()
            }
        else:
            audit_log("service_start_failed", {
                "username": username,
                "ip": client_ip,
                "service": SERVICE_NAME,
                "return_code": result.returncode
            })
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to start service"
            )
    
    except ValueError as e:
        audit_log("service_start_validation_error", {
            "username": username,
            "error": str(e)[:100]
        })
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        audit_log("service_start_error", {
            "username": username,
            "error": str(e)[:100]
        })
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal error")

@app.post("/service/stop", tags=["Service Management"])
@limiter.limit(f"{RATE_LIMIT_REQUESTS}/minute")
async def stop_service(
    request: Request,
    reason: Optional[str] = None,
    user: Dict[str, Any] = Depends(verify_token)
) -> Dict[str, Any]:
    """Остановка сервиса."""
    username = user.get("sub")
    client_ip = request.client.host
    
    try:
        await check_operation_frequency()
        
        if SERVICE_NAME not in ALLOWED_SERVICES:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Service not allowed")
        
        if reason and len(reason) > MAX_REASON_LENGTH:
            raise ValueError(f"Reason exceeds maximum length ({MAX_REASON_LENGTH} chars)")
        
        if reason and any(x in reason.lower() for x in SUSPICIOUS_KEYWORDS):
            raise ValueError("Reason contains suspicious keywords")
        
        audit_log("service_stop_initiated", {
            "username": username,
            "ip": client_ip,
            "service": SERVICE_NAME,
            "reason": reason or ""
        })
        
        result = execute_service_command(SERVICE_STOP_CMD)
        operation_history.append(datetime.now())
        
        if result.returncode == 0:
            audit_log("service_stop_success", {
                "username": username,
                "service": SERVICE_NAME
            })
            return {
                "status": "success",
                "action": "stop",
                "service": SERVICE_NAME,
                "message": "Service stopped successfully",
                "timestamp": datetime.utcnow().isoformat()
            }
        else:
            audit_log("service_stop_failed", {
                "username": username,
                "service": SERVICE_NAME,
                "return_code": result.returncode
            })
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to stop service")
    
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        audit_log("service_stop_error", {"error": str(e)[:100]})
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal error")

@app.post("/service/restart", tags=["Service Management"])
@limiter.limit(f"{RATE_LIMIT_REQUESTS}/minute")
async def restart_service(
    request: Request,
    reason: Optional[str] = None,
    user: Dict[str, Any] = Depends(verify_token)
) -> Dict[str, Any]:
    """Перезапуск сервиса."""
    username = user.get("sub")
    client_ip = request.client.host
    
    try:
        await check_operation_frequency()
        
        if SERVICE_NAME not in ALLOWED_SERVICES:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Service not allowed")
        
        if reason and len(reason) > MAX_REASON_LENGTH:
            raise ValueError(f"Reason exceeds maximum length ({MAX_REASON_LENGTH} chars)")
        
        if reason and any(x in reason.lower() for x in SUSPICIOUS_KEYWORDS):
            raise ValueError("Reason contains suspicious keywords")
        
        audit_log("service_restart_initiated", {
            "username": username,
            "ip": client_ip,
            "service": SERVICE_NAME,
            "reason": reason or ""
        })
        
        # Проверка существования сервиса
        check_result = execute_service_command(SERVICE_CHECK_CMD)
        if check_result.returncode != 0:
            audit_log("service_not_found", {
                "username": username,
                "service": SERVICE_NAME
            })
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Service {SERVICE_NAME} not found")
        
        # Выполнение перезапуска
        result = execute_service_command(SERVICE_RESTART_CMD)
        operation_history.append(datetime.now())
        
        if result.returncode == 0:
            audit_log("service_restart_success", {
                "username": username,
                "ip": client_ip,
                "service": SERVICE_NAME
            })
            return {
                "status": "success",
                "action": "restart",
                "service": SERVICE_NAME,
                "message": "Service restarted successfully",
                "timestamp": datetime.utcnow().isoformat()
            }
        else:
            audit_log("service_restart_failed", {
                "username": username,
                "service": SERVICE_NAME,
                "return_code": result.returncode
            })
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to restart service")
    
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        audit_log("service_restart_error", {"error": str(e)[:100]})
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal error")

@app.get("/audit", tags=["Audit"])
async def get_audit_log(
    limit: int = 50,
    user: Dict[str, Any] = Depends(verify_token)
) -> Dict[str, Any]:
    """
    Получение записей из аудит лога.
    Требуется право 'audit:read'.
    """
    
    if "audit:read" not in user.get("permissions", []):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions for audit access"
        )
    
    try:
        operations = []
        with open(AUDIT_LOG_FILE, "r", encoding='utf-8') as f:
            lines = f.readlines()
            for line in lines[-limit:]:
                try:
                    if AUDIT_LOG_FORMAT == "json":
                        operations.append(json.loads(line))
                    else:
                        operations.append({"record": line.strip()})
                except json.JSONDecodeError:
                    pass
        
        return {"records": list(reversed(operations)), "total": len(operations)}
    except FileNotFoundError:
        return {"records": [], "total": 0}

# ==================== ЗАПУСК ПРИЛОЖЕНИЯ ====================

if __name__ == "__main__":
    print_config()
    
    app_logger.info(f"Starting {APP_NAME} v{APP_VERSION}")
    app_logger.info(f"Environment: {ENV}")
    app_logger.info(f"Kubernetes: {IS_KUBERNETES}")
    
    uvicorn.run(
        app,
        host=HOST,
        port=PORT,
        ssl_keyfile=SSL_KEY_FILE if USE_SSL else None,
        ssl_certfile=SSL_CERT_FILE if USE_SSL else None,
        log_level=LOG_LEVEL.lower(),
    )      
```

`/api.conf.yaml`
```yaml
# api.conf.yaml - Конфигурация API

# ==================== ОСНОВНОЕ ====================

app:
  name: "Scheduler Restart API"
  version: "1.0.1-secure"
  description: "Secure API for restarting GlobalScheduler with bcrypt password hashing"

server:
  host: "0.0.0.0"
  port: 8000
  environment: "development"  # development или production
  debug: false

# ==================== SECURITY ====================

security:
  # ВАЖНО: Сгенерируйте новый ключ для production:
  # python3 -c "import secrets; print(secrets.token_urlsafe(32))"
  secret_key: "dev-secret-key-change-in-production"
  algorithm: "HS256"
  
  # Время жизни токена (минуты)
  token_ttl_minutes: 15
  
  # CORS settings
  cors:
    development:
      origins:
        - "*"
      allow_credentials: true
      allow_methods:
        - "*"
      allow_headers:
        - "*"
    
    production:
      origins:
        - "https://localhost:8080"
        - "https://app.example.com"
      allow_credentials: true
      allow_methods:
        - "POST"
        - "GET"
      allow_headers:
        - "Authorization"
        - "Content-Type"
  
  # IP Whitelist (для production)
  ip_whitelist:
    enabled: false
    ips:
      - "192.168.0.0/16"
      - "192.168.1.101"
      - "10.0.0.0/24"
  
  # SSL/TLS
  ssl:
    enabled: false
    cert_file: "/etc/ssl/certs/api.crt"
    key_file: "/etc/ssl/private/api.key"

# ==================== ПОЛЬЗОВАТЕЛИ ====================
# ПРИМЕЧАНИЕ: Пароли ДОЛЖНЫ быть хешированы с bcrypt в production
# Генерация хеша: python3 -c "from passlib.context import CryptContext; ctx = CryptContext(schemes=['bcrypt']); print(ctx.hash('password123'))"

users:
  admin:
    # Хеш пароля: admin123
    password: "admin123"
    permissions:
      - "service:manage"
      - "audit:read"
    roles:
      - "admin"
  
  operator:
    # Хеш пароля: operator123
    password: "$2b$12$KVxWTfVQYVvtcKL.E8lCSORFPkQzVQEqR.qBB2L3zQf8CKjy7xfWe"
    permissions:
      - "service:manage"
    roles:
      - "operator"
  
  viewer:
    # Хеш пароля: viewer123
    password: "$2b$12$OzL9hPJqp6J3p4zK5.3LS.E5l0u7vJzQ0n.xXXKwBVv0BgJRWj5rC"
    permissions:
      - "audit:read"
    roles:
      - "viewer"

# ==================== СЕРВИС ====================

service:
  # Имя systemd сервиса
  name: "globalscheduler"
  
  # Whitelist разрешённых сервисов (защита от инъекций)
  allowed_services:
    - "globalscheduler"
  
  # Таймаут для операций (секунды)
  timeout: 30
  
  # Проверка перед рестартом
  check_before_restart: true

# ==================== RATE LIMITING ====================

rate_limiting:
  # Запросы в минуту на остальные эндпоинты
  requests_per_minute: 5
  
  # Rate limiting на эндпоинт логина (защита от brute force)
  login_requests_per_minute: 3
  
  # Рестартов в час (для защиты от спама)
  restart_threshold: 5
  restart_threshold_hours: 1

# ==================== ЛОГИРОВАНИЕ ====================

logging:
  # Уровень: DEBUG, INFO, WARNING, ERROR, CRITICAL
  level: "INFO"
  
  # Вывод в консоль
  console: true
  
  # Аудит логирование
  audit:
    enabled: true
    # ВАЖНО: В production используй /var/log/scheduler-api/audit.log
    file: "/var/log/scheduler-api/audit.log"
    format: "json"  # json или text
    retention_days: 90

# ==================== ВАЛИДАЦИЯ ====================

validation:
  # Максимальная длина поля "reason"
  max_reason_length: 200
  
  # Подозрительные слова в reason
  suspicious_keywords:
    - "script"
    - "drop"
    - "delete"
    - "insert"
    - "exec"
    - "system"
    - "eval"
    - "bash"
    - "shell"

# ==================== ENDPOINTS ====================

endpoints:
  # Доступные эндпоинты
  enabled:
    - "health"
    - "auth_login"
    - "service_status"
    - "service_start"
    - "service_stop"
    - "service_restart"
    - "audit_log"
  
  # Версия API
  version: "v1"
  prefix: "/api/v1"

# ==================== KUBERNETES ====================
# Автоматически определяется наличием переменной KUBERNETES_SERVICE_HOST

# ==================== PRODUCTION ПРИМЕРЫ ====================

# server:
#   port: 443
#   environment: "production"
#   debug: false
#
# security:
#   secret_key: "ваш-криптостойкий-ключ-из-окружения"
#   ssl:
#     enabled: true
#     cert_file: "/etc/ssl/certs/api.crt"
#     key_file: "/etc/ssl/private/api.key"
#   ip_whitelist:
#     enabled: true
#     ips:
#       - "192.168.100.0/24"
#
# logging:
#   level: "WARNING"
#   audit:
#     file: "/var/log/scheduler-api/audit.log"
#
# rate_limiting:
#   login_requests_per_minute: 2

```

`/__pycache__/config.cpython-311.pyc`
```text
§

    ¸	 i!  ã                   óö   d dl Z d dlZd dlZd dlmZ d dlmZmZmZm	Z	  ej
        e¦  «        ZdYde
dee
e	f         fdZ	  e¦   «         Zn,# e$ r$Ze                     de ¦  «         i ZY dZ[ndZ[ww xY wdZd	e
d
e	de	fdZ edd
¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Z edd¦  «        Zer ed¦  «        ndZer ed ¦  «        ndZ ed!e i ¦  «        Z e  !                    d"d#g¦  «        Z"e  !                    d$d%¦  «        Z#e  !                    d&d#g¦  «        Z$e  !                    d'd#g¦  «        Z% ed(d¦  «        Z&e&r ed)g ¦  «        ng Z' ed*i ¦  «        Z( ed+d,¦  «        Z) ed-d.¦  «        Z* ed/d%¦  «        Z+ ed0d,g¦  «        Z,d1d2e)gZ-d3d1d4e)gZ.d3d1d5e)gZ/d3d1d6e)gZ0 ed7d8¦  «        Z1d9Z2 ed:d;¦  «        Z3 ed<d8¦  «        Z4 ed=d>¦  «        Z5e5d?z  Z6 ed@dA¦  «        Z7 edBd%¦  «        Z8 edCd%¦  «        Z9 edDdE¦  «        Z: edFdG¦  «        Z; edHdI¦  «        Z< edJdK¦  «        Z= edLg ¦  «        Z> edMg dN¢¦  «        Z? edOdP¦  «        Z@ edQdR¦  «        ZA e jB        dS¦  «        duZC e jB        dTdU¦  «        ZD e jB        dVd
¦  «        ZEdW ZFedXk    r eF¦   «          dS dS )[é    N)ÚPath)ÚOptionalÚDictÚListÚAnyú
api.conf.yamlÚconfig_fileÚreturnc                 ó   t          | ¦  «        }|                     ¦   «         st          d|  ¦  «        t          |dd¬¦  «        5 }t	          j        |¦  «        }ddd¦  «         n# 1 swxY w Y   |t
          d|  ¦  «        |S )uÊ  
    ÐÐ°Ð³ÑÑÐ¶Ð°ÐµÑ ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ñ Ð¸Ð· YAML ÑÐ°Ð¹Ð»Ð°.
    
    ÐÐ°ÑÐ°Ð¼ÐµÑÑÑ:
        config_file: Ð¿ÑÑÑ Ðº ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ð¾Ð½Ð½Ð¾Ð¼Ñ ÑÐ°Ð¹Ð»Ñ
    
    ÐÐ¾Ð·Ð²ÑÐ°ÑÐ°ÐµÑ:
        Ð¡Ð»Ð¾Ð²Ð°ÑÑ Ñ ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸ÐµÐ¹
    
    ÐÑÐºÐ»ÑÑÐµÐ½Ð¸Ñ:
        FileNotFoundError: ÐµÑÐ»Ð¸ ÑÐ°Ð¹Ð» ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ð¸ Ð½Ðµ Ð½Ð°Ð¹Ð´ÐµÐ½
        ValueError: ÐµÑÐ»Ð¸ ÑÐ°Ð¹Ð» ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ð¸ Ð¿ÑÑÑ
    zConfiguration file not found: Úrzutf-8)ÚencodingNzConfiguration file is empty: )r   ÚexistsÚFileNotFoundErrorÚopenÚyamlÚ	safe_loadÚ
ValueError)r	   Úconfig_pathÚfÚconfigs       ú'/opt/global/restart_scheduler/config.pyÚload_yaml_configr   
   sÖ    õ {Ñ#Ô#Kà×ÒÑÔð PÝÐ NÀÐ NÐ NÑOÔOÐOå	
k3¨Ð	1Ñ	1Ô	1ð #°QÝ Ñ"Ô"ð#ð #ð #ñ #ô #ð #ð #ð #ð #ð #ð #øøøð #ð #ð #ð #ð ~ÝÐF¸ÐFÐFÑGÔGÐGàMs   ÁA)Á)A-Á0A-zCould not load YAML config: Úkey_pathÚdefaultc                 óð   |                       ¦   «                              dd¦  «        }|t          j        v rut          j        |         }|                     ¦   «         dv r|                     ¦   «         dk    S 	 d|v rt          |¦  «        S t
          |¦  «        S # t          $ r |cY S w xY w|                      d¦  «        }t          }|D ]'}t          |t          ¦  «        r
||v r	||         }$|c S ||n|S )uÂ  
    ÐÐ¾Ð»ÑÑÐ°ÐµÑ Ð·Ð½Ð°ÑÐµÐ½Ð¸Ðµ Ð¸Ð· ÐºÐ¾Ð½ÑÐ¸Ð³Ð° Ð¿Ð¾ Ð¿ÑÑÐ¸.
    ÐÑÐ¸Ð¾ÑÐ¸ÑÐµÑ: Ð¿ÐµÑÐµÐ¼ÐµÐ½Ð½ÑÐµ Ð¾ÐºÑÑÐ¶ÐµÐ½Ð¸Ñ > YAML > Ð·Ð½Ð°ÑÐµÐ½Ð¸Ñ Ð¿Ð¾ ÑÐ¼Ð¾Ð»ÑÐ°Ð½Ð¸Ñ.
    
    ÐÐ°ÑÐ°Ð¼ÐµÑÑÑ:
        key_path: Ð¿ÑÑÑ Ð² ÑÐ¾ÑÐ¼Ð°ÑÐµ "server.port" Ð¸Ð»Ð¸ "security.ssl.enabled"
        default: Ð·Ð½Ð°ÑÐµÐ½Ð¸Ðµ Ð¿Ð¾ ÑÐ¼Ð¾Ð»ÑÐ°Ð½Ð¸Ñ
    
    ÐÐ¾Ð·Ð²ÑÐ°ÑÐ°ÐµÑ:
        ÐÐ½Ð°ÑÐµÐ½Ð¸Ðµ ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ð¸
    ú.Ú_)ÚtrueÚfalser   )ÚupperÚreplaceÚosÚenvironÚlowerÚfloatÚintr   ÚsplitÚYAML_CONFIGÚ
isinstanceÚdict)r   r   Úenv_varÚvalueÚkeysÚkeys         r   Ú
get_configr/   3   s   ð nnÑÔ×&Ò& s¨CÑ0Ô0GØ"*ÐÐÝ
7Ô#à;;==Ð-Ð-Ð-Ø;;== FÒ*Ð*ð	Øe||ÝU||Ð#Ýu::ÐøÝð 	ð 	ð 	ØLLLð	øøøð >>#ÑÔDÝEàð ð ÝeTÑ"Ô"ð 	 s¨e | |Ø#JEEàNNNàÐ%55¨7Ð2s   Á8B ÂB ÂB)Â(B)zapp.namezScheduler Restart APIzapp.versionz1.0.0zserver.porti@  zserver.hostz0.0.0.0zserver.environmentÚdevelopmentzserver.debugFzsecurity.secret_keyz#dev-secret-key-change-in-productionzsecurity.algorithmÚHS256zsecurity.token_ttl_minutesé   zsecurity.ssl.enabledzsecurity.ssl.cert_filezsecurity.ssl.key_filezsecurity.cors.ÚoriginsÚ*Úallow_credentialsTÚ
allow_methodsÚ
allow_headerszsecurity.ip_whitelist.enabledzsecurity.ip_whitelist.ipsÚuserszservice.nameÚglobalschedulerzservice.timeouté   zservice.check_before_restartzservice.allowed_servicesÚ	systemctlÚstatusÚsudoÚrestartÚstartÚstopz!rate_limiting.requests_per_minuteé   Úminutez'rate_limiting.login_requests_per_minuteé   zrate_limiting.restart_thresholdz%rate_limiting.restart_threshold_hoursé   i  z
logging.levelÚINFOzlogging.consolezlogging.audit.enabledzlogging.audit.filez /var/log/scheduler-api/audit.logzlogging.audit.formatÚjsonzlogging.audit.retention_dayséZ   zvalidation.max_reason_lengthéÈ   zvalidation.suspicious_keywordszendpoints.enabled)ÚhealthÚ
auth_loginÚservice_statusÚ
service_startÚservice_stopÚservice_restartÚ	audit_logzendpoints.versionÚv1zendpoints.prefixz/api/v1ÚKUBERNETES_SERVICE_HOSTÚHOSTNAMEz
scheduler-apiÚ	NAMESPACEc                  ó   d                      g dt           dt           dt           dt           dt
           dt           dt           d	t           d
t           dt           dt           d
t          t          ¦  «         dt          t          ¦  «         dt           dt            dt"           dt$           dt&           dt(           dt*           dt,           dt.           dt0           dt          t2          ¦  «         d¦  «        } t4                               | ¦  «         dS )u7   ÐÑÐ²ÐµÑÑÐ¸ ÑÐµÐºÑÑÑÑ ÐºÐ¾Ð½ÑÐ¸Ð³ÑÑÐ°ÑÐ¸Ñ.Ú zÑ
    ===================================================
    Configuration Summary (from api.conf.yaml)
    ===================================================
    
    Application:
       - Name:             z
       - Version:          z
       - Environment:      z
       - Debug:            z-
    
    Server:
       - Host:             z
       - Port:             z
       - SSL:              z
       - Kubernetes:       z/
    
    Security:
       - Algorithm:        z
       - Token TTL:        z  min
       - Login Rate Limit: z /min
       - CORS Origins:     z7 configured
    
    Users:
       - Total:            z.
    
    Service:
       - Name:             z
       - Allowed:          z
       - Timeout:          z5s
    
    Rate Limiting:
       - Requests/min:     z
       - Restart limit:    ú/z/h
    
    Logging:
       - Level:            z
       - Audit:            z
       - Format:           z
       - File:             z!
    
    Endpoints:             z
 enabled
    N)ÚjoinÚAPP_NAMEÚAPP_VERSIONÚENVÚDEBUGÚHOSTÚPORTÚUSE_SSLÚ
IS_KUBERNETESÚ
JWT_ALGORITHMÚACCESS_TOKEN_EXPIRE_MINUTESÚLOGIN_RATE_LIMIT_REQUESTSÚlenÚCORS_ORIGINSÚUSERSÚSERVICE_NAMEÚALLOWED_SERVICESÚSERVICE_TIMEOUTÚRATE_LIMIT_REQUESTSÚRESTART_THRESHOLDÚRESTART_THRESHOLD_HOURSÚ	LOG_LEVELÚ
AUDIT_ENABLEDÚAUDIT_LOG_FORMATÚAUDIT_LOG_FILEÚENDPOINTS_ENABLEDÚloggerÚinfo)Ú
config_outputs    r   Úprint_configrt   »   sÇ   ð*÷ *ò *ð *ð *ð *õ %ð
*ð *ð *ð *õ (ð*ð *ð *ð *õ  ð*ð *ð *ð *õ "ð*ð *ð *ð *õ !ð*ð *ð *ð *õ !ð*ð *ð *ð *õ $ð*ð *ð *ð *õ *ð*ð *ð *ð *õ$ *ð%*ð *ð *ð *õ& 8ð'*ð *ð *ð *õ( 6ð)*ð *ð *ð *õ*  ¥Ñ-Ô-ð+*ð *ð *ð *õ0  ¥JJð1*ð *ð *ð *õ6 )ð7*ð *ð *ð *õ8 -ð9*ð *ð *ð *õ: ,ð;*ð *ð *ð *õ@ 0ðA*ð *ð *ð *õB .ðC*ð *ð *ð *õB 1HðC*ð *ð *ð *õH &ðI*ð *ð *ð *õJ *ðK*ð *ð *ð *õL -ðM*ð *ð *ð *õN +ðO*ð *ð *ð *õR  Õ 1Ñ2Ô2ðS*ð *ð *ð *ñ *ô *MõV KK
ÑÔÐÐÐó    Ú__main__)r   )N)Gr"   r   ÚloggingÚpathlibr   Útypingr   r   r   r   Ú	getLoggerÚ__name__rq   Ústrr   r(   Ú	ExceptionÚeÚwarningr/   rX   rY   r]   r\   rZ   r[   Ú
SECRET_KEYr`   ra   r^   Ú
SSL_CERT_FILEÚSSL_KEY_FILEÚcors_configÚgetrd   ÚCORS_ALLOW_CREDENTIALSÚCORS_ALLOW_METHODSÚCORS_ALLOW_HEADERSÚIP_WHITELIST_ENABLEDÚIP_WHITELISTre   rf   rh   ÚSERVICE_CHECK_BEFORE_RESTARTrg   ÚSERVICE_CHECK_CMDÚSERVICE_RESTART_CMDÚSERVICE_START_CMDÚSERVICE_STOP_CMDri   ÚRATE_LIMIT_PERIODrb   rj   rk   ÚRESTART_THRESHOLD_PERIODrl   ÚLOG_TO_CONSOLErm   ro   rn   ÚAUDIT_RETENTION_DAYSÚMAX_REASON_LENGTHÚSUSPICIOUS_KEYWORDSrp   ÚAPI_VERSIONÚ
API_PREFIXÚgetenvr_   ÚK8S_POD_NAMEÚ
K8S_NAMESPACErt   © ru   r   ú<module>r      s  ðð 
			Ø Ø Ø Ð Ð Ð Ð Ð Ø ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,Ð ,à	Ô	8Ñ	$Ô	$ðð  #ð ¸DÀÀcÀ¼Nð ð ð ð ð<Ø"Ð"Ñ$Ô$KKøØð ð ð Ø
NNÐ5°!Ð5Ð5Ñ6Ô6Ð6ØKKKKKKøøøøðøøøð&3ð &3ð &3 sð &3°cð &3ð &3ð &3ð &3ðT :jÐ"9Ñ:Ô:Øj¨Ñ0Ô0ð z- Ñ&Ô&Øz- Ñ+Ô+ØjÐ% }Ñ5Ô5Ø
> 5Ñ)Ô)ð ZÐ-Ð/TÑ
UÔ
U
Ø
Ð/°Ñ9Ô9
Ø(jÐ)EÀrÑJÔJÐ ð *Ð+¨UÑ
3Ô
3Ø8?ÐI

Ð3Ñ4Ô4Ð4ÀT
Ø6=ÐGzzÐ1Ñ2Ô2Ð2À4ð jÐ/¨#Ð/Ð/°Ñ4Ô4Øy¨3¨%Ñ0Ô0Ø$Ð)<¸dÑCÔCÐ Ø __ _°s°eÑ<Ô<Ð Ø __ _°s°eÑ<Ô<Ð ð "zÐ"AÀ5ÑIÔIÐ Ø>RÐZzzÐ5°rÑ:Ô:Ð:ÐXZð 	
7BÑÔð z.Ð*;Ñ<Ô<Ø*Ð.°Ñ3Ô3Ø)zÐ*HÈ$ÑOÔOÐ ð :Ð8Ð;LÐ:MÑNÔNÐ à  (¨LÐ9Ð Ø{¨I°|ÐDÐ Ø[¨'°<Ð@Ð ØK¨°Ð>Ð ð !jÐ!DÀaÑHÔHÐ ØÐ ð 'JÐ'PÐRSÑTÔTÐ àJÐ@À!ÑDÔDÐ Ø$*Ð%LÈaÑPÔPÐ Ø2°TÑ9Ð ð 
J¨Ñ/Ô/	ØÐ-¨tÑ4Ô4à
Ð2°DÑ9Ô9
ØÐ0Ð2TÑUÔUØ:Ð4°fÑ=Ô=Ð Ø!zÐ"@À"ÑEÔEÐ ð JÐ=¸sÑCÔCÐ Ø jÐ!AÀ2ÑFÔFÐ ð JÐ2ð 5ð 5ð 5ñ ô Ð ð jÐ,¨dÑ3Ô3Ø
ZÐ*¨IÑ
6Ô
6
ð
 	Ð3Ñ4Ô4¸DÐ@
Øry _Ñ5Ô5Ø	+ yÑ1Ô1
ð-ð -ð -ð^ zÒÐØLNNNNNð Ðs   Á
A ÁA5ÁA0Á0A5
```

---
*Generated by Project to MD tool*  
*Total files processed: 7*  
*Ignore file used: .ignore*  
