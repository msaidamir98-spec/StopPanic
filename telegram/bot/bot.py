"""Stillō Telegram bot.

Companion bot for the Stillō Mini App (panic attack self-help tool).

Features:
    * /start            -- greeting with a WebApp button opening the Mini App
    * /start support_N  -- deep link from the Mini App, sends a Telegram Stars invoice
    * /menu             -- main menu (Mini App, facts, note, techniques, crisis)
    * /facts            -- psychoeducation cards about panic attacks
    * /note             -- quick state note (stored in SQLite, survives restarts)
    * /techniques       -- 4-7-8 breathing and 5-4-3-2-1 grounding as text
    * /roadmap          -- what's next for Stillō (incl. the iOS app)
    * /crisis           -- crisis hotline numbers (also via inline callback)
    * /help             -- what the bot can do + disclaimer
    * /paysupport       -- payment/refund support contact (required by Stars rules)

Run: python3 bot.py (long polling). Restarts on failure are handled by systemd.
"""

from __future__ import annotations

import logging
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

from aiogram import Bot, Dispatcher, F, Router
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.filters import Command, CommandObject, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import (
    BotCommand,
    CallbackQuery,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    LabeledPrice,
    Message,
    PreCheckoutQuery,
    WebAppInfo,
)
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN: str = os.getenv("BOT_TOKEN", "")
WEBAPP_URL: str = os.getenv(
    "WEBAPP_URL", "https://msaidamir98-spec.github.io/StopPanic/app/"
)
SUPPORT_USERNAME: str = os.getenv("SUPPORT_USERNAME", "stillo_support")

BASE_DIR: Path = Path(__file__).resolve().parent
PAYMENTS_LOG: Path = BASE_DIR / "payments.log"
DB_PATH: Path = BASE_DIR / "stillo_bot.db"

# Allowed donation amounts in Telegram Stars (XTR).
SUPPORT_AMOUNTS: frozenset[int] = frozenset({100, 250, 500})

MAX_NOTE_LEN: int = 500
RECENT_NOTES_LIMIT: int = 5

CRISIS_CALLBACK: str = "crisis_lines"
FACTS_CALLBACK_PREFIX: str = "fact"
NOTE_ADD_CALLBACK: str = "note_add"
NOTE_LIST_CALLBACK: str = "note_list"
TECHNIQUES_CALLBACK: str = "techniques"
ROADMAP_CALLBACK: str = "roadmap"
MENU_CALLBACK: str = "menu"

logger = logging.getLogger("stillo-bot")

router = Router(name="stillo")

# --------------------------------------------------------------------------- #
# Texts
# --------------------------------------------------------------------------- #

GREETING_RU = (
    "Привет! Я — Stillō. 🌊\n\n"
    "Если накрывает паника или тревога — открой приложение, и мы вместе "
    "продышимся и вернём ощущение опоры. Это бесплатно и займёт пару минут.\n\n"
    "Ещё здесь есть: 📖 короткие факты, которые снимают страх перед паникой, "
    "🧰 техники текстом и 📝 быстрые заметки о состоянии.\n\n"
    "Ты справишься. Я рядом."
)

GREETING_EN = (
    "Hi! I'm Stillō. 🌊\n\n"
    "If panic or anxiety is rising — open the app and we'll breathe through it "
    "together and help you feel grounded again. It's free and takes a couple "
    "of minutes.\n\n"
    "Also here: 📖 short facts that take the fear out of panic, 🧰 text "
    "techniques and 📝 quick state notes.\n\n"
    "You've got this. I'm here."
)

CRISIS_TEXT = (
    "☎️ <b>Линии помощи</b>\n\n"
    "• ЦЭПП МЧС России: <b>+7 495 989-50-50</b> (круглосуточно)\n"
    "• Детский телефон доверия: <b>8-800-2000-122</b>\n"
    "• При угрозе жизни — звони <b>112</b>\n\n"
    "Ты не один. Звонки бесплатны и анонимны."
)

HELP_TEXT = (
    "🌊 <b>Stillō — помощь при панических атаках</b>\n\n"
    "Что я умею:\n"
    "• /start — открыть Mini App с дыхательными практиками и заземлением\n"
    "• /menu — главное меню\n"
    "• /facts — факты о панике, которые снимают страх\n"
    "• /techniques — дыхание 4-7-8 и заземление 5-4-3-2-1 текстом\n"
    "• /note — быстрая заметка о состоянии\n"
    "• /roadmap — что появится в Stillō дальше\n"
    "• /crisis — телефоны доверия и экстренной помощи\n"
    "• /paysupport — вопросы по платежам и возвратам\n"
    "• /help — это сообщение\n\n"
    "<i>Stillō — инструмент самопомощи, не замена врачу. Если тревога "
    "мешает жить, пожалуйста, обратись к специалисту.</i>"
)

THANKS_TEXT = (
    "💙 Спасибо за поддержку!\n\n"
    "Твой вклад помогает Stillō оставаться бесплатным для всех, "
    "кому сейчас тяжело. Это очень ценно."
)

INVOICE_TITLE = "Поддержка Stillō"
INVOICE_DESCRIPTION = (
    "Спасибо, что помогаешь развивать бесплатный инструмент против паники"
)

TECHNIQUES_TEXT = (
    "🧰 <b>Две техники, которые работают прямо в чате</b>\n\n"
    "🌬 <b>Дыхание 4-7-8</b>\n"
    "Главное — выдох длиннее вдоха (глубокие частые вдохи только разгоняют "
    "панику):\n"
    "1. Вдох через нос — на счёт <b>4</b>\n"
    "2. Пауза — на счёт <b>7</b>\n"
    "3. Медленный выдох через рот — на счёт <b>8</b>\n"
    "Повтори 4–6 кругов. Если 7 не держится — сократи, пропорция важнее цифр.\n\n"
    "🖐 <b>Заземление 5-4-3-2-1</b>\n"
    "Возвращает из «головы» в реальность. Найди вокруг и назови (можно вслух):\n"
    "• <b>5</b> вещей, которые видишь\n"
    "• <b>4</b> вещи, которых можешь коснуться\n"
    "• <b>3</b> звука, которые слышишь\n"
    "• <b>2</b> запаха\n"
    "• <b>1</b> вкус\n\n"
    "В Mini App эти практики идут с таймером и подсказками — там проще, "
    "когда трясёт. 🌊"
)

ROADMAP_TEXT = (
    "🔮 <b>Что дальше у Stillō</b>\n\n"
    "Уже скоро в боте:\n"
    "• 📊 трекер эпизодов — увидишь, что атаки становятся короче и реже\n"
    "• ☀️ утренний чек-ин — минута в день, чтобы замечать динамику\n\n"
    "И главное: готовлю <b>iOS-приложение Stillō</b> — кнопка SOS прямо "
    "на экране телефона и Apple Watch, работает без интернета.\n\n"
    "Хочешь повлиять на то, что появится раньше? Напиши пару слов "
    "@{support} — я читаю всё. 💙"
).format(support=SUPPORT_USERNAME)

NOTE_PROMPT_TEXT = (
    "📝 Напиши пару слов о своём состоянии прямо сейчас — одним сообщением.\n\n"
    "Например: «тревога 6/10, сжимает грудь, но дыхание помогло» или просто "
    "«сегодня спокойно».\n\n"
    "Заметки видишь только ты. Это помогает замечать, что атаки — не навсегда "
    "и им есть причины.\n\n"
    "<i>Передумал(а) — просто нажми любую команду, например /menu.</i>"
)

NOTE_SAVED_TEXT = (
    "Записал. 💙 Сам факт, что ты это заметил(а) и назвал(а), — уже шаг.\n\n"
    "Посмотреть последние записи: /note → «Мои заметки»."
)

NOTE_EMPTY_LIST_TEXT = (
    "Пока нет ни одной заметки. Нажми «✍️ Новая заметка» — займёт полминуты."
)

# Psychoeducation cards. Order matters: from "what is happening" to "what helps".
PANIC_FACTS: tuple[str, ...] = (
    "<b>Паническая атака не опасна для жизни.</b>\n\nЭто резкий выброс "
    "адреналина — древняя реакция «бей или беги», сработавшая без реальной "
    "угрозы. Тело исправно, оно просто перестаралось с защитой.",
    "<b>Пик паники длится 3–10 минут.</b>\n\nАдреналин — «топливо» паники — "
    "быстро сгорает, организм сам включает тормоз. Атака всегда заканчивается, "
    "даже если ничего не делать. С техниками — быстрее и мягче.",
    "<b>От панической атаки не сходят с ума.</b>\n\nОщущение «теряю контроль» — "
    "один из симптомов, а не реальная угроза. За всю историю наблюдений паника "
    "не «сводила с ума» — это страх, который врёт.",
    "<b>«Сердце сейчас остановится» — это тоже симптом.</b>\n\nПри панике "
    "сердце колотится, потому что адреналин велит ему качать кровь к мышцам. "
    "Здоровому сердцу такой режим не вредит — это как короткая пробежка.\n\n"
    "<i>Если боль в груди впервые и сомневаешься — не гадай, звони 112: "
    "проверить — нормально.</i>",
    "<b>Глубокие частые вдохи усиливают панику.</b>\n\nГипервентиляция вымывает "
    "CO₂ — отсюда головокружение и онемение. Работает наоборот: <b>медленный "
    "длинный выдох</b>. Попробуй 4-7-8 в /techniques.",
    "<b>Головокружение и «ватные ноги» — не обморок.</b>\n\nПри панике давление "
    "обычно слегка <i>повышается</i>, а для обморока нужно падение давления. "
    "Поэтому упасть в обморок от паники почти невозможно.",
    "<b>Дереализация — «мир как в кино» — это симптом, не безумие.</b>\n\n"
    "Так мозг экономит ресурсы при перегрузке. Неприятно, но безопасно и "
    "проходит вместе с атакой. Заземление 5-4-3-2-1 возвращает резкость.",
    "<b>Избегание кормит панику.</b>\n\nКаждый раз, когда обходишь «опасное» "
    "место, мозг записывает: «там правда страшно». Круг сужается. Возвращаться "
    "в такие места (в своём темпе, с опорой на техники) — и есть выздоровление.",
    "<b>Ты не один: панику переживал примерно каждый десятый.</b>\n\nЕдиничные "
    "атаки — очень частый человеческий опыт. Это не делает тебя «сломанным» — "
    "это делает тебя человеком, у которого чувствительная сигнализация.",
    "<b>Кофеин, недосып и алкоголь снижают порог атаки.</b>\n\nОни не "
    "«причина», но они делают сигнализацию чувствительнее. Если атаки "
    "участились — первым делом сон и меньше кофе. Скучно, но работает.",
    "<b>После атаки накрывает усталость — это нормально.</b>\n\nТело отработало "
    "«марафон» за десять минут. Слабость, дрожь, сонливость после — признак "
    "того, что система откатывается в норму, а не что «что-то не так».",
    "<b>Если атаки повторяются — лучший результат даёт КПТ.</b>\n\n"
    "Когнитивно-поведенческая терапия — золотой стандарт работы с паническим "
    "расстройством: понятный протокол на несколько месяцев, а не «годы на "
    "кушетке». Stillō — скорая самопомощь, а КПТ-специалист — путь к тому, "
    "чтобы атаки ушли совсем.",
)

# --------------------------------------------------------------------------- #
# Storage (SQLite, stdlib — no extra dependencies)
# --------------------------------------------------------------------------- #

_db: sqlite3.Connection | None = None


def get_db() -> sqlite3.Connection:
    """Return the module-wide SQLite connection, creating schema on first use."""
    global _db
    if _db is None:
        _db = sqlite3.connect(DB_PATH, check_same_thread=False)
        _db.execute("PRAGMA journal_mode=WAL")
        _db.execute(
            """
            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                text TEXT NOT NULL
            )
            """
        )
        _db.execute(
            "CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id, id DESC)"
        )
        _db.commit()
    return _db


def save_note(user_id: int, text: str) -> None:
    """Persist a single state note for the given user."""
    db = get_db()
    db.execute(
        "INSERT INTO notes (user_id, created_at, text) VALUES (?, ?, ?)",
        (user_id, datetime.now(timezone.utc).isoformat(), text),
    )
    db.commit()


def recent_notes(user_id: int, limit: int = RECENT_NOTES_LIMIT) -> list[tuple[str, str]]:
    """Return up to ``limit`` most recent (created_at, text) notes for a user."""
    rows = get_db().execute(
        "SELECT created_at, text FROM notes WHERE user_id = ? "
        "ORDER BY id DESC LIMIT ?",
        (user_id, limit),
    )
    return list(rows.fetchall())


# --------------------------------------------------------------------------- #
# FSM
# --------------------------------------------------------------------------- #


class NoteForm(StatesGroup):
    """Waiting for the user's free-form state note."""

    waiting_text = State()


# --------------------------------------------------------------------------- #
# Keyboards
# --------------------------------------------------------------------------- #


def main_keyboard() -> InlineKeyboardMarkup:
    """Main menu: Mini App first, then self-help blocks, then crisis line."""
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="🌊 Открыть Stillō (SOS)",
                    web_app=WebAppInfo(url=WEBAPP_URL),
                )
            ],
            [
                InlineKeyboardButton(
                    text="🧰 Техники текстом", callback_data=TECHNIQUES_CALLBACK
                ),
                InlineKeyboardButton(
                    text="📖 Факты о панике",
                    callback_data=f"{FACTS_CALLBACK_PREFIX}:0",
                ),
            ],
            [
                InlineKeyboardButton(
                    text="📝 Заметка о состоянии", callback_data=NOTE_ADD_CALLBACK
                ),
                InlineKeyboardButton(
                    text="🔮 Что дальше", callback_data=ROADMAP_CALLBACK
                ),
            ],
            [
                InlineKeyboardButton(
                    text="☎️ Телефон доверия", callback_data=CRISIS_CALLBACK
                )
            ],
        ]
    )


def facts_keyboard(index: int) -> InlineKeyboardMarkup:
    """Prev/next pager for fact cards + back to menu."""
    total = len(PANIC_FACTS)
    prev_index = (index - 1) % total
    next_index = (index + 1) % total
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="←", callback_data=f"{FACTS_CALLBACK_PREFIX}:{prev_index}"
                ),
                InlineKeyboardButton(
                    text=f"{index + 1}/{total}", callback_data="noop"
                ),
                InlineKeyboardButton(
                    text="→", callback_data=f"{FACTS_CALLBACK_PREFIX}:{next_index}"
                ),
            ],
            [InlineKeyboardButton(text="☰ Меню", callback_data=MENU_CALLBACK)],
        ]
    )


def note_keyboard() -> InlineKeyboardMarkup:
    """Entry points for the notes feature."""
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="✍️ Новая заметка", callback_data=NOTE_ADD_CALLBACK
                ),
                InlineKeyboardButton(
                    text="🗂 Мои заметки", callback_data=NOTE_LIST_CALLBACK
                ),
            ],
            [InlineKeyboardButton(text="☰ Меню", callback_data=MENU_CALLBACK)],
        ]
    )


def back_to_menu_keyboard() -> InlineKeyboardMarkup:
    """Single «back to menu» button."""
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [InlineKeyboardButton(text="☰ Меню", callback_data=MENU_CALLBACK)]
        ]
    )


# --------------------------------------------------------------------------- #
# Handlers: start / menu
# --------------------------------------------------------------------------- #


@router.message(CommandStart(deep_link=True))
async def cmd_start_deep_link(
    message: Message, command: CommandObject, bot: Bot
) -> None:
    """Handle /start with a payload (deep link from the Mini App)."""
    payload = (command.args or "").strip()
    if payload.startswith("support_"):
        amount_raw = payload.removeprefix("support_")
        if amount_raw.isdigit() and int(amount_raw) in SUPPORT_AMOUNTS:
            await send_support_invoice(bot, message.chat.id, int(amount_raw))
            return
        logger.warning("Unknown support payload: %r", payload)
    # Unknown payload -- fall back to the regular greeting.
    await cmd_start(message)


@router.message(CommandStart())
async def cmd_start(message: Message) -> None:
    """Handle plain /start: greeting + main menu."""
    lang = (message.from_user.language_code or "") if message.from_user else ""
    text = GREETING_RU if lang.startswith("ru") else GREETING_EN
    await message.answer(text, reply_markup=main_keyboard())


@router.message(Command("menu"))
async def cmd_menu(message: Message) -> None:
    """Show the main menu."""
    await message.answer("Я здесь. Что нужно прямо сейчас?", reply_markup=main_keyboard())


@router.callback_query(F.data == MENU_CALLBACK)
async def on_menu_callback(callback: CallbackQuery) -> None:
    """Show the main menu in response to the inline button."""
    if isinstance(callback.message, Message):
        await callback.message.answer(
            "Я здесь. Что нужно прямо сейчас?", reply_markup=main_keyboard()
        )
    await callback.answer()


@router.callback_query(F.data == "noop")
async def on_noop_callback(callback: CallbackQuery) -> None:
    """Silently ack decorative buttons (e.g. the page counter)."""
    await callback.answer()


# --------------------------------------------------------------------------- #
# Handlers: facts
# --------------------------------------------------------------------------- #


@router.message(Command("facts"))
async def cmd_facts(message: Message) -> None:
    """Show the first psychoeducation card."""
    await message.answer(PANIC_FACTS[0], reply_markup=facts_keyboard(0))


@router.callback_query(F.data.startswith(f"{FACTS_CALLBACK_PREFIX}:"))
async def on_fact_callback(callback: CallbackQuery) -> None:
    """Page through fact cards by editing the same message."""
    raw_index = (callback.data or "").split(":", maxsplit=1)[-1]
    index = int(raw_index) % len(PANIC_FACTS) if raw_index.isdigit() else 0
    if isinstance(callback.message, Message):
        try:
            await callback.message.edit_text(
                PANIC_FACTS[index], reply_markup=facts_keyboard(index)
            )
        except Exception:  # noqa: BLE001 -- "message is not modified" and alike
            logger.debug("Fact card edit skipped", exc_info=True)
    await callback.answer()


# --------------------------------------------------------------------------- #
# Handlers: techniques / roadmap
# --------------------------------------------------------------------------- #


@router.message(Command("techniques"))
async def cmd_techniques(message: Message) -> None:
    """Send the 4-7-8 + 5-4-3-2-1 techniques as text."""
    await message.answer(TECHNIQUES_TEXT, reply_markup=back_to_menu_keyboard())


@router.callback_query(F.data == TECHNIQUES_CALLBACK)
async def on_techniques_callback(callback: CallbackQuery) -> None:
    """Send techniques in response to the inline button."""
    if isinstance(callback.message, Message):
        await callback.message.answer(
            TECHNIQUES_TEXT, reply_markup=back_to_menu_keyboard()
        )
    await callback.answer()


@router.message(Command("roadmap"))
async def cmd_roadmap(message: Message) -> None:
    """Tell what is coming next (tracker, check-in, iOS app)."""
    await message.answer(ROADMAP_TEXT, reply_markup=back_to_menu_keyboard())


@router.callback_query(F.data == ROADMAP_CALLBACK)
async def on_roadmap_callback(callback: CallbackQuery) -> None:
    """Roadmap in response to the inline button."""
    if isinstance(callback.message, Message):
        await callback.message.answer(
            ROADMAP_TEXT, reply_markup=back_to_menu_keyboard()
        )
    await callback.answer()


# --------------------------------------------------------------------------- #
# Handlers: notes
# --------------------------------------------------------------------------- #


@router.message(Command("note"))
async def cmd_note(message: Message) -> None:
    """Entry point for notes: offer to add or list."""
    await message.answer(
        "📝 <b>Заметки о состоянии</b>\n\nКороткая запись помогает замечать "
        "динамику: что запускает тревогу и что помогает.",
        reply_markup=note_keyboard(),
    )


@router.callback_query(F.data == NOTE_ADD_CALLBACK)
async def on_note_add(callback: CallbackQuery, state: FSMContext) -> None:
    """Ask for the note text and switch FSM into waiting state."""
    await state.set_state(NoteForm.waiting_text)
    if isinstance(callback.message, Message):
        await callback.message.answer(NOTE_PROMPT_TEXT)
    await callback.answer()


@router.callback_query(F.data == NOTE_LIST_CALLBACK)
async def on_note_list(callback: CallbackQuery) -> None:
    """Show the user's recent notes."""
    user_id = callback.from_user.id
    notes = recent_notes(user_id)
    if isinstance(callback.message, Message):
        if not notes:
            await callback.message.answer(
                NOTE_EMPTY_LIST_TEXT, reply_markup=note_keyboard()
            )
        else:
            lines: list[str] = [f"🗂 <b>Последние {len(notes)} записей</b>\n"]
            for created_at, text in notes:
                day = created_at[:10]
                lines.append(f"<b>{day}</b> — {text}")
            await callback.message.answer(
                "\n\n".join(lines), reply_markup=note_keyboard()
            )
    await callback.answer()


@router.message(NoteForm.waiting_text, F.text & ~F.text.startswith("/"))
async def on_note_text(message: Message, state: FSMContext) -> None:
    """Save the free-form note typed after the prompt."""
    await state.clear()
    text = (message.text or "").strip()[:MAX_NOTE_LEN]
    if not text:
        await message.answer("Пустую заметку не сохранил. Попробуешь ещё раз? /note")
        return
    user_id = message.from_user.id if message.from_user else 0
    try:
        save_note(user_id, text)
    except sqlite3.Error:
        logger.exception("Failed to save note for user %d", user_id)
        await message.answer(
            "Не получилось сохранить заметку, уже разбираюсь. Попробуй позже. 🙏"
        )
        return
    await message.answer(NOTE_SAVED_TEXT, reply_markup=back_to_menu_keyboard())


@router.message(NoteForm.waiting_text)
async def on_note_non_text(message: Message, state: FSMContext) -> None:
    """Reset the note state if a command or non-text message arrives."""
    await state.clear()
    await message.answer("Ок, заметку отменил. Меню: /menu")


# --------------------------------------------------------------------------- #
# Handlers: payments
# --------------------------------------------------------------------------- #


async def send_support_invoice(bot: Bot, chat_id: int, amount: int) -> None:
    """Send a Telegram Stars (XTR) invoice for the given amount."""
    await bot.send_invoice(
        chat_id=chat_id,
        title=INVOICE_TITLE,
        description=INVOICE_DESCRIPTION,
        payload=f"support_{amount}",
        currency="XTR",
        prices=[LabeledPrice(label="Поддержка Stillō", amount=amount)],
        provider_token="",  # Empty for Telegram Stars.
    )
    logger.info("Invoice for %d XTR sent to chat %d", amount, chat_id)


@router.pre_checkout_query()
async def on_pre_checkout(query: PreCheckoutQuery) -> None:
    """Approve every pre-checkout query (digital donation, nothing to verify)."""
    await query.answer(ok=True)


@router.message(F.successful_payment)
async def on_successful_payment(message: Message) -> None:
    """Thank the user and append the payment to payments.log."""
    payment = message.successful_payment
    user_id = message.from_user.id if message.from_user else 0
    amount = payment.total_amount if payment else 0
    ts = datetime.now(timezone.utc).isoformat()

    try:
        with PAYMENTS_LOG.open("a", encoding="utf-8") as fh:
            fh.write(f"{ts}\t{user_id}\t{amount}\n")
    except OSError:
        logger.exception("Failed to write payments.log")

    logger.info("Payment received: user=%d amount=%d XTR", user_id, amount)
    await message.answer(THANKS_TEXT)


@router.message(Command("paysupport"))
async def cmd_paysupport(message: Message) -> None:
    """Payment support contact (required by Telegram Stars rules)."""
    await message.answer(
        f"По вопросам платежей и возвратов напиши @{SUPPORT_USERNAME}. "
        "Возврат — в течение 21 дня."
    )


# --------------------------------------------------------------------------- #
# Handlers: crisis / help
# --------------------------------------------------------------------------- #


@router.message(Command("crisis"))
async def cmd_crisis(message: Message) -> None:
    """Send crisis hotline numbers."""
    await message.answer(CRISIS_TEXT)


@router.callback_query(F.data == CRISIS_CALLBACK)
async def on_crisis_callback(callback: CallbackQuery) -> None:
    """Send crisis hotline numbers in response to the inline button."""
    if isinstance(callback.message, Message):
        await callback.message.answer(CRISIS_TEXT)
    await callback.answer()


@router.message(Command("help"))
async def cmd_help(message: Message) -> None:
    """Describe what the bot does, with a disclaimer."""
    await message.answer(HELP_TEXT)


# --------------------------------------------------------------------------- #
# Entry point
# --------------------------------------------------------------------------- #

BOT_COMMANDS: tuple[tuple[str, str], ...] = (
    ("start", "Открыть Stillō"),
    ("menu", "Главное меню"),
    ("facts", "Факты о панике"),
    ("techniques", "Техники: 4-7-8 и 5-4-3-2-1"),
    ("note", "Заметка о состоянии"),
    ("roadmap", "Что дальше (и про iOS)"),
    ("crisis", "Телефоны доверия"),
    ("help", "Помощь"),
)


async def main() -> None:
    """Configure the bot and start long polling."""
    if not BOT_TOKEN:
        logger.critical("BOT_TOKEN is not set. Fill in .env and restart.")
        sys.exit(1)

    get_db()  # Fail fast if the SQLite file is not writable.

    bot = Bot(
        token=BOT_TOKEN,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML),
    )
    dispatcher = Dispatcher()
    dispatcher.include_router(router)

    await bot.set_my_commands(
        [BotCommand(command=cmd, description=desc) for cmd, desc in BOT_COMMANDS]
    )

    logger.info("Starting Stillō bot (long polling). WebApp: %s", WEBAPP_URL)
    await bot.delete_webhook(drop_pending_updates=True)
    await dispatcher.start_polling(bot)


if __name__ == "__main__":
    import asyncio

    logging.basicConfig(
        level=logging.INFO,
        stream=sys.stdout,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    asyncio.run(main())
