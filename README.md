# Dalnovid Server

Сервер для Dalnovid — удалённого доступа, который вы контролируете сами:
свой ID-сервер, свой relay, без обращений к чужим серверам.

Состоит из двух программ:

- **hbbs** — ID-сервер: регистрирует устройства и помогает им найти друг друга;
- **hbbr** — relay: передаёт трафик, когда прямое соединение невозможно.

Клиенты Dalnovid на Windows, macOS, Linux, Android и iOS подключаются к любому
серверу Dalnovid. Сам сервер работает на Linux (x86_64, ARM64), Windows и macOS.

## Быстрая установка (Ubuntu / Debian)

```bash
curl -fsSL https://raw.githubusercontent.com/MisteRun/dalnovid-server/main/install.sh | sudo bash -s -- relay.example.com
```

Аргумент — адрес, по которому клиенты достучатся до relay (домен или IP этого
сервера). Скрипт ставит последнюю версию в `/opt/dalnovid-server`, хранит ключи
и базу в `/var/lib/dalnovid-server`, заводит systemd-сервисы `dalnovid-hbbs`
и `dalnovid-hbbr`, открывает порты в ufw (если он включён) и в конце печатает
**публичный ключ сервера** — его нужно указать в клиентах.

## Docker

```bash
cd docker-dalnovid
# поправьте адрес relay в docker-compose.yml
docker compose up -d
cat data/id_ed25519.pub
```

Образ: `ghcr.io/misterun/dalnovid-server` (amd64, arm64).

## Порты

| Порт | Протокол | Программа | Назначение |
|---|---|---|---|
| 21115 | TCP | hbbs | проверка типа NAT |
| 21116 | TCP + UDP | hbbs | регистрация ID, поиск, hole punching |
| 21117 | TCP | hbbr | relay |
| 21118 | TCP | hbbs | WebSocket (веб-клиент) |
| 21119 | TCP | hbbr | WebSocket relay (веб-клиент) |

## Ключи

При первом запуске hbbs создаёт пару ключей `id_ed25519` / `id_ed25519.pub`.
Публичный ключ раздаётся клиентам: по нему клиент проверяет, что говорит именно
с вашим сервером. **Приватный ключ `id_ed25519` никому не передавайте и
сохраните в резервной копии** — при его потере все клиенты придётся
перенастроить.

## Сборка из исходников

```bash
cargo build --release
```

Результат: `target/release/hbbs`, `target/release/hbbr`,
`target/release/dalnovid-utils`.

Все параметры и переменные окружения:
[docs/environment-variables.md](docs/environment-variables.md).

## Лицензия

GNU AGPL-3.0, см. [LICENSE](LICENSE). Dalnovid Server — изменённая версия
открытого проекта; происхождение и авторские права указаны в [NOTICE](NOTICE).
