import logging, os
from bot import Bot
from db import DB

logging.basicConfig(level=logging.INFO)
bot = Bot(token=os.environ['TELEGRAM_BOT_TOKEN'])
bot.start_polling()
