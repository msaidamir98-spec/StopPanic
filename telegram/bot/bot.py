"""Stillō Telegram bot.

Companion bot for the Stillō Mini App (panic attack self-help tool).

Features:
    * /start            -- greeting with a WebApp button opening the Mini App
    * /start support_N  -- deep link from the Mini App, sends a Telegram Stars invoice
    * /crisis           -- crisis hotline numbers (also via inline callback)
    * /help             -- what the bot can do + disclaimer
    * /paysupport       -- payment/refund support contact (required by Stars rules)

Run: python3 bot.py (long polling). Restarts on failure are handled by systemd.
"""

from __future__ import annotations

import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from aiogram import Bot, Dispatcher, F, Router
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.filters import Command, CommandObject, CommandStart
from aiogram.types import (
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

PAYMENTS_LOG: Path = Path(__file__).resolve().parent / "payments.log"

# Allowed donation amounts in Telegram Stars (XTR).
SUPPORT_AMOUNTS: frozenset[int] = frozenset({100, 250, 500})

CRISIS_CALLBACK: str = "crisis_lines"

logger = logging.getLogger("stillo-bot")

router = Router(name="stillo")

# --------------------------------------------------------------------------- #
# Texts
# --------------------------------------------------------------------------- #

GREETING_RU = (
    "Привет! Я — Stillō. 🌊\n\n"
    "Если накрывает паника или тревога — открой приложение, и мы вместе "
    "продышимся и вернём ощущение опоры. Это бесплатно и займёт пару минут.\n\n"
    "Ты справишься. Я рядом."
)

GREETING_EN = (
    "Hi! I'm Stillō. 🌊\n\n"
    "If panic or anxiety is rising — open the app and we'll breathe through it "
    "together and help you feel grounded again. It's free and takes a couple "
    "of minutes.\n\n"
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

# --------------------------------------------------------------------------- #
# Keyboards
# --------------------------------------------------------------------------- #


def main_keyboard() -> InlineKeyboardMarkup:
    """Keyboard with the Mini App button and a crisis-lines button."""
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="🌊 Открыть Stillō",
                    web_app=WebAppInfo(url=WEBAPP_URL),
                )
            ],
            [
                InlineKeyboardButton(
                    text="☎️ Телефон доверия",
                    callback_data=CRISIS_CALLBACK,
                )
            ],
        ]
    )


# --------------------------------------------------------------------------- #
# Handlers
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
    """Handle plain /start: greeting + Mini App button."""
    lang = (message.from_user.language_code or "") if message.from_user else ""
    text = GREETING_RU if lang.startswith("ru") else GREETING_EN
    await message.answer(text, reply_markup=main_keyboard())


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


async def main() -> None:
    """Configure the bot and start long polling."""
    if not BOT_TOKEN:
        logger.critical("BOT_TOKEN is not set. Fill in .env and restart.")
        sys.exit(1)

    bot = Bot(
        token=BOT_TOKEN,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML),
    )
    dispatcher = Dispatcher()
    dispatcher.include_router(router)

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
