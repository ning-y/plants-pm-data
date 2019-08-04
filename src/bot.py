import logging, os, subprocess
from telegram import ParseMode
from telegram.ext import CommandHandler, Job, Updater
from db import DB
from sensor import Sensor

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

class Bot(Updater):
    GSHEETS_LINK = 'https://docs.google.com/spreadsheets/d/{}'.format(
            os.environ['SPREADSHEET_KEY'])
    NEW_SESSION_USAGE = '<code>/new_session &lt;name&gt; &lt;seconds&gt;</code>'
    END_SESSION_USAGE = '<code>/end_session &lt;name&gt;</code>'
    COMMENT_USAGE = '<code>/comment &lt;comment&gt;</code>'

    def __init__(self, *, token):
        super().__init__(token=token)
        self.__session = None

        self.dispatcher.add_handler(CommandHandler(
                'status', self.__handle_status))
        self.dispatcher.add_handler(CommandHandler(
                'new_session', self.__handle_new_session, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'end_session', self.__handle_end_session, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'comment', self.__handle_comment, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'check_reading', self.__handle_check_reading))

    def __handle_status(self, bot, update):
        session_info = 'No active session.' if self.__session == None else \
                "Session '{}' is active.".format(self.__session)
        gsheets_info = r'<a href="{}">GSheets link.</a>'.format(
                self.GSHEETS_LINK)
        self.__send_message(
                bot, update, '{}\n{}'.format(session_info, gsheets_info))

    def __handle_new_session(self, bot, update, args):
        # Validate args
        try:
            assert len(args) == 2
            int(args[1])
        except (AssertionError, ValueError):
            return self.__send_message(bot, update, self.NEW_SESSION_USAGE)
        # Check no already active session
        if self.__session != None:
            return self.__send_message(bot, update,
                    "Already have active session '{}'".format(self.__session))
        # Check if this session already exists
        if args[0] in DB.get_all_sessions():
            return self.__send_message(bot, update,
                    "Session with name '{}' already exists.".format(args[0]))

        self.__session = args[0]
        interval = int(args[1])
        self.job_queue.run_repeating(
                self.__session_callback, name=self.__session,
                interval=interval, first=0)
        self.__send_message(bot, update,
                "Started session '{}' with interval {}s.".format(
                    self.__session, interval))

    def __handle_end_session(self, bot, update, args):
        # Validate args
        try:
            assert len(args) == 1
        except AssertionError:
            return self.__send_message(bot, update, self.END_SESSION_USAGE)
        # Check if no active session to end
        if self.__session == None:
            return self.__send_message(bot, update, 'No active session to end.')
        # Arg supplied must be same as active session name to confirm its end
        if args[0] != self.__session:
            return self.__send_message(bot, update,
                    'Provide the name of the session to end to confirm.')

        self.__session = None
        for job in self.job_queue.jobs():
            job.schedule_removal()  # removed w/o executing callback
        self.__send_message(bot, update, 'Session stopped.')

    def __handle_comment(self, bot, update, args):
        # Validate args
        try:
            assert len(args) > 0
        except AssertionError:
            return self.__send_message(bot, update, self.COMMENT_USAGE)
        # Check if active session to comment in
        if self.__session == None:
            return self.__send_message(bot, update,
                    'No active session to add comment.')

        comment = ' '.join(args)
        DB.add_comment(self.__session, comment)
        DB.sync(self.__session)
        self.__send_message(bot, update,
                "Comment added to '{}'.".format(self.__session))

    @classmethod
    def __handle_check_reading(cls, bot, update):
        try:
            readings = Sensor.get_readings()
            cls.__send_message(bot, update,
                    '<b>Warning:</b> will not save to database.\n{}'.format(
                        str(readings)))
        except Exception as e:
            cls.__send_message(bot, update,
                    '<b>{}</b>'.format(str(e)))

    @classmethod
    def __session_callback(cls, bot, job):
        try:
            readings = Sensor.get_readings()
            DB.add_pm2_5(job.name, readings['pm2.5'])
            DB.add_pm10(job.name, readings['pm10'])
            DB.sync(job.name)
        except Exception as e:
            cls.__send_message(bot, update,
                    'An exception was raised in the job callback:\n' +
                    '<b>{}</b>'.format(str(e)))

    @classmethod
    def __send_message(cls, bot, update, message):
        to_prepend = '<code>[{}]</code>\n'.format(cls.__get_sys_time())
        message = to_prepend + message
        return bot.send_message(
                chat_id=update.message.chat_id,
                text=message,
                parse_mode=ParseMode.HTML,
                disable_web_page_preview=True,
                disable_notifications=True)

    @staticmethod
    def __get_sys_time():
        datetime = subprocess.check_output(['date']).decode().strip()
        return ' '.join(datetime.split())
