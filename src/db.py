import logging, os, sqlite3, time
import gspread
from oauth2client.service_account import ServiceAccountCredentials

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

class DB:
    FILENAME = 'data.db'
    _TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
    _TYPE_COMMENT = 'comment'
    _TYPE_PM2_5 = 'pm2.5'
    _TYPE_PM10 = 'pm10'

    @classmethod
    def add_pm2_5(cls, session, value):
        cls._append_row(session, cls._TYPE_PM2_5, str(value))

    @classmethod
    def add_pm10(cls, session, value):
        cls._append_row(session, cls._TYPE_PM10, str(value))

    @classmethod
    def add_comment(cls, session, value):
        cls._append_row(session, cls._TYPE_COMMENT, value)

    @classmethod
    def sync(cls, session, delay=0):
        """Syncs the local database onto Google Sheets."""
        local_data = cls._get_all(session)
        remote_obs_count = Sheet.get_obs_count(session)
        Sheet.add_rows(session, local_data[remote_obs_count:], delay=delay)

    @classmethod
    def get_all_sessions(cls):
        op = "SELECT name FROM sqlite_master WHERE type='table';"
        return [tup[0] for tup in cls._execute(op).fetchall()]

    @classmethod
    def _get_all(cls, session):
        op = 'SELECT * FROM "{}";'.format(session)
        return cls._execute(op).fetchall()

    @classmethod
    def _append_row(cls, session, datatype, value):
        cls._try_init_table(session)
        op = """INSERT INTO "{}" VALUES ('{}', '{}', '{}');""".format(
                session, cls._get_time_now(), datatype, value)
        logger.info(op)
        cls._execute(op)

    @classmethod
    def _execute(cls, op):
        con = sqlite3.connect(cls.FILENAME)
        with con:
            return con.execute(op)

    @classmethod
    def _try_init_table(cls, session):
        con = sqlite3.connect(cls.FILENAME)
        op = """
                CREATE TABLE IF NOT EXISTS
                "{}" (
                    datetime TEXT,
                    datatype TEXT,
                    value TEXT
                );""".format(session)
        with con:
            con.execute(op)

    @classmethod
    def _get_time_now(cls):
        return time.strftime(cls._TIME_FORMAT, time.localtime())


class Sheet:
    r"""
    Object for interacting with the Google Sheets storing our experimental data.
    Requires a JSON keyfile for the Google API service account at the project
    root named 'credentials.json'. Requires the spreadsheet key as an
    environmental variable, usually provided by a ``.env`` file and pipenv.
    """
    _SCOPE = [
        'https://spreadsheets.google.com/feeds',
        'https://www.googleapis.com/auth/drive']
    _CREDENTIALS = ServiceAccountCredentials.from_json_keyfile_name(
            'credentials.json', _SCOPE)
    _SPREADSHEET_KEY = os.environ['SPREADSHEET_KEY']

    @classmethod
    def add_rows(cls, session, rows, delay=0):
        if len(rows) == 0:
            return

        wks = cls.get_worksheet(cls._SPREADSHEET_KEY, session)
        for row in rows:
            time.sleep(delay)
            wks.append_row(row)

    @classmethod
    def get_obs_count(cls, session):
        r"""Returns the number of observations in the Google Sheets"""
        wks = cls.get_worksheet(cls._SPREADSHEET_KEY, session)
        return len(wks.get_all_values())

    @classmethod
    def get_worksheet(cls, spreadsheet_key, session):
        r"""
        Returns the ``gspread.models.Spreadsheet`` object corresponding to
        this spreadsheet_url and worksheet_index.
        """
        client = gspread.authorize(cls._CREDENTIALS)
        spreadsheet = client.open_by_key(spreadsheet_key)
        print(spreadsheet.worksheets())
        if not cls.pad(session) in \
                [ws.title for ws in spreadsheet.worksheets()]:
            return spreadsheet.add_worksheet(
                    title=cls.pad(session), rows='1', cols='3')
        return spreadsheet.worksheet(cls.pad(session))

    @staticmethod
    def pad(name):
        """
        Workaround for a Google Sheets API bug.
        See https://stackoverflow.com/a/53524012/
        """
        return '_{}_'.format(name)
