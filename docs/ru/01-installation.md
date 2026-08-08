# Установка / Installation

## Требования

- FXServer (актуальная версия)
- Windows или Linux
- OneSync
- Lua 5.4 (используется актуальными сборками FXServer; директива `lua54` в манифесте больше не требуется)

## Пошаговая установка

### Шаг 1. Откройте папку ресурсов

Найдите папку `resources` вашего FiveM-сервера.

### Шаг 2. Создайте папку `[greencore]`

```text
resources/[greencore]/
```

### Шаг 3. Поместите `gc_core`

Скопируйте папку `gc_core` в `resources/[greencore]/`.

```text
resources/[greencore]/gc_core/
```

### Шаг 4. Откройте `server.cfg`

Найдите файл `server.cfg` в корне сервера.

### Шаг 5. Добавьте строку

```cfg
ensure gc_core
```

### Шаг 6. Сохраните `server.cfg`

### Шаг 7. Запустите FXServer

### Шаг 8. Проверьте запуск

Найдите сообщение:

```text
[GreenCore] [INFO] gc_core 0.1.2-alpha started successfully
```

## Инструкции для Windows

1. Откройте папку `resources`.
2. Создайте папку `[greencore]`.
3. Скопируйте `gc_core` внутрь.
4. Отредактируйте `server.cfg` в Блокноте.
5. Добавьте `ensure gc_core`.
6. Запустите `FXServer.exe`.

## Инструкции для Linux

1. Откройте папку `resources`.
2. Создайте папку `[greencore]`.
3. Скопируйте `gc_core` внутрь.
4. Отредактируйте `server.cfg`.
5. Добавьте `ensure gc_core`.
6. Запустите `./run.sh`.

## Проверка

После запуска игрок должен:

1. Подключиться к серверу.
2. Пройти проверку.
3. Получить Lua-сессию.
4. Появиться в заданной точке.

## Следующий шаг

Перейдите к [Первому запуску](02-first-start.md).
