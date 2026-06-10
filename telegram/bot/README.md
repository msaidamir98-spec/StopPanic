# Stillō Bot — деплой за 10 минут

Telegram-бот для Stillō: открывает Mini App, показывает телефоны доверия,
принимает донаты Telegram Stars.

## 1. BotFather (~3 мин)

1. Открой [@BotFather](https://t.me/BotFather) → `/newbot`.
2. Имя: `Stillō` (или `Stillō — помощь при панике`).
3. Username: предложение — `stillo_sos_bot` (должен заканчиваться на `bot`).
4. Скопируй токен — он понадобится в `.env`.
5. Включи кнопку меню с Mini App:
   `/mybots` → выбери бота → **Bot Settings** → **Menu Button** →
   **Configure Menu Button** → вставь URL:
   `https://msaidamir98-spec.github.io/StopPanic/app/`
   → название кнопки: `Stillō`.
6. `/setdescription` → выбери бота → текст, например:
   > Помощь при панических атаках: дыхание, заземление, телефоны доверия. Бесплатно и анонимно.

## 2. VPS (Ubuntu, ~5 мин)

```bash
# Код
git clone https://github.com/msaidamir98-spec/StopPanic.git   # или git pull, если уже есть
cd StopPanic/telegram/bot

# Окружение
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

# Конфиг
cp .env.example .env
nano .env        # вставь BOT_TOKEN от BotFather, укажи SUPPORT_USERNAME

# systemd
sudo cp stillo-bot.service /etc/systemd/system/
sudo nano /etc/systemd/system/stillo-bot.service   # поправь User= и пути, если отличаются
sudo systemctl daemon-reload
sudo systemctl enable --now stillo-bot

# Логи
journalctl -u stillo-bot -f
```

`Restart=always` в юните перезапускает бота при любых падениях поллинга.

## 3. GitHub Pages (~1 мин, если ещё не включено)

Репозиторий → **Settings** → **Pages** → Source: **Deploy from a branch** →
ветка `main`, папка `/docs` → Save. Mini App должен открываться по
`https://msaidamir98-spec.github.io/StopPanic/app/`.

## 4. Тест (~1 мин)

1. Напиши боту `/start` → кнопка «🌊 Открыть Stillō» открывает Mini App
   (web_app-кнопки работают только в личном чате с ботом — это норма).
2. Кнопка «☎️ Телефон доверия» и `/crisis` → номера линий помощи.
3. Донат: в Mini App нажми «Поддержать» → бот пришлёт invoice в Stars →
   оплати тестово → бот благодарит, запись появляется в `payments.log`.
4. `/paysupport` и `/help` отвечают.

## Вывод Stars

Stars выводятся через [Fragment](https://fragment.com) (нужен TON-кошелёк);
холд — 21 день с момента получения, поэтому возвраты обещаем в этот срок.
