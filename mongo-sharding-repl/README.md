# MongoDB Sharding with Replication using Docker Compose

Настройка кластера MongoDB в режиме шардирования с репликацией в Docker Compose.

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
         ├────────────────────────┬────────────────────────┐
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  Config Server  │    │ Shard 1 Replica  │    │ Shard 2 Replica  │
│  (Replica Set)  │    │      Set         │    │      Set         │
│  Port: 27017    │    │                  │    │                  │
└─────────────────┘    │  ┌────────────┐  │    │  ┌────────────┐  │
                       │  │  Primary   │  │    │  │  Primary   │  │
                       │  │ Port:27018 │  │    │  │ Port:27019 │  │
                       │  └────────────┘  │    │  └────────────┘  │
                       │  ┌────────────┐  │    │  ┌────────────┐  │
                       │  │ Secondary1 │  │    │  │ Secondary1 │  │
                       │  │ Port:27021 │  │    │  │ Port:27024 │  │
                       │  └────────────┘  │    │  └────────────┘  │
                       │  ┌────────────┐  │    │  ┌────────────┐  │
                       │  │ Secondary2 │  │    │  │ Secondary2 │  │
                       │  │ Port:27022 │  │    │  │ Port:27025 │  │
                       │  └────────────┘  │    │  └────────────┘  │
                       └──────────────────┘    └──────────────────┘
```

## Key Features

### High Availability
- **Replica Sets:** Каждый шард имеет 3 узла (1 Primary + 2 Secondary)
- **Automatic Failover:** При отказе Primary узла, один из Secondary автоматически становится Primary
- **Data Redundancy:** Данные реплицируются на все узлы в replica set

### Horizontal Scalability
- **Sharding:** Данные распределяются между двумя шардами
- **Load Distribution:** Запросы распределяются между шардами через mongos router

### Data Integrity
- **Write Concerns:** Возможность настройки гарантий записи
- **Read Preferences:** Возможность чтения с Secondary узлов для снижения нагрузки

## Components

### 1. Config Server (`configSrv`)
- **Port:** 27017
- **Role:** Хранит метаданные и конфигурацию распределенного кластера шардов.
- **Replica Set:** `config_server`

### 2. Shard 1 (`mongo-shard1`)
- **Port:** 27018
- **Role:** Основной узел шарда 1, обрабатывает запросы на чтение и запись.
- **Replica Set:** `shard1`

#### 2.2. Secondary Node 1 (`mongo-shard1-repl1`)
- **Port:** 27021
- **Role:** Вторичная реплика шарда 1, синхронизирует данные с Primary.
- **Volume:** `shard1-data-repl1`

#### 2.3. Secondary Node 2 (`mongo-shard1-repl2`)
- **Port:** 27022
- **Role:** Вторичная реплика шарда 1, синхронизирует данные с Primary.
- **Volume:** `shard1-data-repl2`

### 3. Shard 2 Replica Set
- **Port:** 27019
- **Role:** Основной узел шарда 2, обрабатывает запросы на чтение и запись.
- **Replica Set:** `shard2`

#### 3.1. Primary Node (`mongo-shard2`)
- **Port:** 27019
- **Role:** Основной узел шарда 2, обрабатывает запросы на чтение и запись.
- **Volume:** `shard2-data`

#### 3.2. Secondary Node 1 (`mongo-shard2-repl1`)
- **Port:** 27024
- **Role:** Вторичная реплика шарда 2, синхронизирует данные с Primary.
- **Volume:** `shard2-data-repl1`

#### 3.3. Secondary Node 2 (`mongo-shard2-repl2`)
- **Port:** 27025
- **Role:** Вторичная реплика шарда 2, синхронизирует данные с Primary.
- **Volume:** `shard2-data-repl2`

### 4. Mongos Router (`mongos_router`)
- **Port:** 27020
- **Role:** Маршрутизирует запросы к соответствующему шарду.
- **Config:** Подключается к серверу конфигурации `config_server/configSrv:27017`

### 5. Mongos Initialization (`mongos_init`)
- **Role:** Разовая инициализация сервиса, которая:
  - Инициализирует replica set для config server
  - Инициализирует replica set для shard1 (3 узла)
  - Инициализирует replica set для shard2 (3 узла)
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
cd mongo-sharding-repl
docker compose --profile mongos-init up -d 
```

Выполняет:
1. Запускает сервер конфигурации.
2. Запускает оба шарда с репликами (6 узлов данных всего).
3. Запускает маршрутизатор mongos.
4. Запускает скрипт инициализации для:
   - Инициализации replica sets
   - Добавления шардов в кластер
   - Включения шардирования
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
