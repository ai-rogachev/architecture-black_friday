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
- **Role:** Хранит партиционированняе данные - часть 1.
- **Replica Set:** `shard1`

### 3. Shard 2 (`mongo-shard2`)
- **Port:** 27019
- **Role:**  Хранит партиционированняе данные - часть 2.
- **Replica Set:** `shard2`

### 4. Mongos Router (`mongos_router`)
- **Port:** 27020
- **Role:** Маршрутизирует запросы в соответствующему шарду.
- **Config:** Задается серверос конфигурации

### 5. Mongos Initialization (`mongos_init`)
- **Role:** Разовая инициализация сервиса которая:
  - Добавляет шарды в кластер
  - Включает сегментирование базы данных
  - Создает сегментированные коллекции
  - Добавляет тестовые данные

### 6. Python API (`pymongo_api`)
- **Port:** 8080
- **Framework:** FastAPI
- **Features:**
  - Запрос данных из кластека
  - Отображение состояния кластера
  - Управление пользователями

## Getting Started

### Start the Cluster

Запуск кластера вместе с инициализацией.

```bash
cd mongo-sharding
docker compose --profile mongos-init up -d 
```

Выполняет:
1. Запустите сервер конфигурации.
2. Запустите оба шарда.
3. Запустите маршрутизатор mongos.
4. Запустите скрипт инициализации, чтобы добавить шарды и включить шардирование.
5. Запустите API Python.

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
