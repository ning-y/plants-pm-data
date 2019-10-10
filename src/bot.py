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
    NEW_SESSION_USAGE = '<code>/new_session &lt;sensor_no&gt; &lt;name&gt; &lt;seconds&gt;</code>'
    END_SESSION_USAGE = '<code>/end_session &lt;name&gt;</code>'
    COMMENT_USAGE = '<code>/comment &lt;comment&gt;</code>'
    MONITOR_READINGS_USAGE = '<code>/monitor &lt;seconds&gt;</code>'

    def __init__(self, *, token):
        super().__init__(token=token)
        self.__session = [None for _ in range(4)]
        self.__jobs = [None for _ in range(4)]  # It seems like the JobQueue only holds
                                                # jobs that are meant to run immediately.
                                                # once executed, the jobs leave the queue,
                                                # only to be re-added just before they are due.
                                                # so, I need to keep track of the jobs myself
                                                # in order to always have them available for
                                                # cancellation.
        self.__monitor_job = None      # Keep this job as instance variable for the
                                                # same reason.

        self.dispatcher.add_handler(CommandHandler(
                'status', self.__handle_status))
        self.dispatcher.add_handler(CommandHandler(
                'new_session', self.__handle_new_session, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'end_session', self.__handle_end_session, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'comment', self.__handle_comment, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'check_readings', self.__handle_check_readings))
        self.dispatcher.add_handler(CommandHandler(
                'monitor', self.__handle_monitor, pass_args=True))
        self.dispatcher.add_handler(CommandHandler(
                'end_monitor', self.__handle_end_monitor))
        self.dispatcher.add_handler(CommandHandler(
                'resync', self.__handle_resync))
        logger.info('Bot initialised.')

    @classmethod
    def __handle_resync(cls, bot, update):
        start_message = cls.__send_message(bot, update.message.chat_id, 'Starting resync.')
        for session_name in DB.get_all_sessions():
            logger.info("Trying to sync {}".format(session_name))
            DB.sync(session_name, delay=1)
        logger.info("Done syncing.")
        return bot.send_message(
                update.message.chat_id,
                'Done with resync.',
                reply_to_message_id=start_message.message_id)

    def __handle_status(self, bot, update):
        sensor_lines = []
        readings = Sensor.get_readings()
        for sensor in range(1, 5):
            line = r'<b>sensor{}:</b> '.format(sensor)
            line += 'online, ' if type(readings[sensor-1]) == dict else 'OFFLINE, '
            line += 'recording at {}.'.format(self.__session[sensor-1]) \
                    if self.__session[sensor-1] != None else 'not recording.'
            sensor_lines.append(line)

        sensors_info = '\n'.join(sensor_lines)
        gsheets_info = r'<a href="{}">GSheets link.</a>'.format(
                self.GSHEETS_LINK)
        return self.__send_message(
                bot, update.message.chat_id, '{}\n{}'.format(sensors_info, gsheets_info))

    def __handle_new_session(self, bot, update, args):
        # Validate args
        try:
            assert len(args) == 3
            int(args[0])
            int(args[2])
        except (AssertionError, ValueError) as e:
            logger.warn(e, exc_info=True)
            return self.__send_message(bot, update.message.chat_id, self.NEW_SESSION_USAGE)

        sensor = int(args[0])
        # Check no already active session
        if self.__session[sensor-1] != None:
            return self.__send_message(bot, update.message.chat_id,
                    "Already have active session '{}' for sensor{}".format(
                        self.__session[sensor-1], sensor))
        # Check if this session already exists
        if args[1] in DB.get_all_sessions():
            return self.__send_message(bot, update.message.chat_id,
                    "Session with name '{}' already exists.".format(args[0]))

        self.__session[sensor-1] = args[1]
        interval = int(args[2])
        new_job = self.job_queue.run_repeating(
                self.__get_session_callback(sensor), name=self.__session[sensor-1],
                interval=interval, first=0, context={'chat_id': update.message.chat_id})
        self.__jobs[sensor-1] = new_job
        self.__send_message(bot, update.message.chat_id,
                "Started session '{}' on sensor{} with interval {}s.".format(
                    self.__session[sensor-1], sensor, interval))

    def __handle_end_session(self, bot, update, args):
        # Validate args
        try:
            assert len(args) == 1
        except AssertionError:
            return self.__send_message(bot, update.message.chat_id, self.END_SESSION_USAGE)
        # Check if no active session to end
        if all([session == None for session in self.__session]):
            return self.__send_message(bot, update.message.chat_id, 'No active sessions to end.')
        elif not args[0] in self.__session:
            return self.__send_message(bot, update.message.chat_id, 'Not an active session. Try: {}'.format(
                    ', '.join(filter(lambda s: s != None, self.__session))))

        sensor = 0
        for i, session in enumerate(self.__session):
            if args[0] == session:
                sensor = i+1
                break
        assert sensor != 0  # must have found a matching session name

        self.__session[sensor-1] = None
        self.__jobs[sensor-1].schedule_removal()
        self.__jobs[sensor-1] = None
        return self.__send_message(bot, update.message.chat_id, 'Session {} on sensor {} stopped.'.format(args[0], sensor))

    def __handle_comment(self, bot, update, args):
        # Validate args
        try:
            assert len(args) > 0
            int(args[0])
        except (AssertionError, ValueError) as e:
            return self.__send_message(bot, update.message.chat_id, self.COMMENT_USAGE)

        sensor = int(args[0])
        session = self.__session[sensor-1]
        if session == None:
            return self.__send_message(bot, update.message.chat_id,
                    'No active session associated with sensor{}.'.format(sensor))

        comment = ' '.join(args[1:])
        DB.add_comment(session, comment)
        DB.sync(session)
        self.__send_message(bot, update.message.chat_id,
                "Comment added to '{}' on sensor{}.".format(session, sensor))

    def __handle_monitor(self, bot, update, args):
        # Validate args
        try:
            assert len(args) == 1
            int(args[0])
        except (AssertionError, ValueError) as e:
            logger.warn(e, exc_info=True)
            return self.__send_message(bot, update.message.chat_id, self.MONITOR_READINGS_USAGE)
        # check if already running
        if self.__monitor_job != None:
            return self.__send_message(bot, update.message.chat_id, "Already monitoring.")

        interval = int(args[0])
        self.__monitor_job = self.job_queue.run_repeating(
                self.__monitor_callback, name='monitor',
                interval=interval, first=0, context={'chat_id': update.message.chat_id})

    def __monitor_callback(self, bot, job):
        sensor_lines = []
        readings = Sensor.get_readings()
        message = '\n'.join([
                '<b>{}: {}</b>'.format(i+1, s) for i, s in enumerate(readings)])
        return self.__send_message(bot, job.context['chat_id'], message)

    def __handle_end_monitor(self, bot, update):
        if self.__monitor_job == None:
            return self.__send_message(bot, update.message.chat_id, "Wasn't monitoring.")

        self.__monitor_job.schedule_removal()
        self.__monitor_job = None
        return self.__send_message(bot, update.message.chat_id, 'Stopped monitoring.')


    @classmethod
    def __handle_check_readings(cls, bot, update):
        readings = Sensor.get_readings()
        message = '\n'.join([
                '<b>{}: {}</b>'.format(i+1, s) for i, s in enumerate(readings)])
        cls.__send_message(bot, update.message.chat_id, message)

    @classmethod
    def __get_session_callback(cls, sensor):
        def __session_callback(bot, job):
            try:
                readings = Sensor.get_reading(sensor)
                DB.add_pm2_5(job.name, readings['pm2.5'])
                DB.add_pm10(job.name, readings['pm10'])
                DB.sync(job.name)
            except Exception as e:
                cls.__send_message(bot, job.context['chat_id'],
                        'An exception was raised in the job callback:\n' +
                        '<b>{}</b>'.format(str(e)))
        return __session_callback

    @classmethod
    def __send_message(cls, bot, chat_id, message):
        to_prepend = '<code>[{}]</code>\n'.format(cls.__get_sys_time())
        message = to_prepend + message
        return bot.send_message(
                chat_id=chat_id,
                text=message,
                parse_mode=ParseMode.HTML,
                disable_web_page_preview=True,
                disable_notifications=True)

    @staticmethod
    def __get_sys_time():
        uptime = subprocess.check_output(['uptime']).decode().strip().split(',')[0]
        return uptime
