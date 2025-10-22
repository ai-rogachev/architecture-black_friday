# MongoDB Sharding with Docker Compose

Настройка кластека MongoDB в режиме шардирования в Docker Compose.

## Architecture

```
┌─────────────────┐
│  Python API     │
│  (FastAPI)      │
│  Port: 8080     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Mongos Router  │
│  Port: 27020    │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────┐  ┌─────────────┐
│  Config Server  │  │   Shard 1   │  │   Shard 2   │
│  Port: 27017    │  │ Port: 27018 │  │ Port: 27019 │
└─────────────────┘  └─────────────┘  └─────────────┘
```

## Components

### 1. Config Server (`configSrv`)
- **Port:** 27017
- **Role:** Хранит метаданные и конфигурацию распределенного кластера шардов.
- **Replica Set:** `config_server`

### 2. Shard 1 (`mongo-shard1`)
- **Port:** 27018
- **Role:** Основной узел шарда 1, обрабатывает запросы на чтение и запись.
- **Replica Set:** `shard1`

### 3. Shard 2 (`mongo-shard2`)
- **Port:** 27019
- **Role:** Основной узел шарда 2, обрабатывает запросы на чтение и запись.
- **Replica Set:** `shard2`

### 4. Mongos Router (`mongos_router`)
- **Port:** 27020
- **Role:** Маршрутизирует запросы к соответствующему шарду.
- **Config:** Подключается к серверу конфигурации `config_server/configSrv:27017`

### 5. Mongos Initialization (`mongos_init`)
- **Role:** Разовая инициализация сервиса, которая:
  - Инициализирует replica set для config server
  - Инициализирует replica set для shard1
  - Инициализирует replica set для shard2
  - Добавляет шарды в кластер
  - Включает шардирование для базы данных
  - Создает шардированные коллекции
  - Добавляет тестовые данные

### 6. Python API (`pymongo_api`)
- **Port:** 8080
- **Framework:** FastAPI
- **Features:**
  - Запрос данных из кластера
  - Отображение состояния кластера
  - Управление пользователями
  - Отображение статистики шардирования и репликации

## Getting Started

### Start the Cluster

Запуск кластера вместе с инициализацией.

```bash
cd mongo-sharding
docker compose --profile mongos-init up -d 
```

Выполняет:
1. Запускает сервер конфигурации.
2. Запускает оба шарда.
3. Запускает маршрутизатор mongos.
4. Запускает скрипт инициализации, чтобы добавить шарды и включить шардирование.
5. Запускает API Python.

### Check Status

```bash
# View all running containers
docker-compose ps

# Check logs
docker-compose logs -f

# Check specific service logs
docker-compose logs -f mongos_router
docker-compose logs -f mongos_init
docker-compose logs -f pymongo_api
```

## Stopping the Cluster

```bash
# Stop all services
docker compose --profile mongos-init down

# Stop and remove volumes (WARNING: deletes all data)
docker compose --profile mongos-init down -v
```
