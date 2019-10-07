import logging, os
from bot import Bot
from db import DB

logging.basicConfig(level=logging.INFO)

for session_name in DB.get_all_sessions():
    logging.info("Pre-startup: trying to sync {}".format(session_name))
    DB.sync(session_name, delay=1)
logging.info("Pre-startup: done.".format(session_name))

bot = Bot(token=os.environ['TELEGRAM_BOT_TOKEN'])
bot.start_polling()
