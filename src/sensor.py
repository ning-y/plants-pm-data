import os, serial

class Sensor:
    BITRATE = 9600
    BYTE_0 = 0xaa  # 'Message header'
    BYTE_1 = 0xc0  # 'Commander No.'
    BYTE_9 = 0xab  # 'Message tail'

    @classmethod
    def get_readings(cls):
        """
        Receives and interprets the UART message. Highly adapted from
        https://gist.github.com/marw/9bdd78b430c8ece8662ec403e04c75fe.
        Nova PM specifications from https://nettigo.pl/attachments/398.
        """
        dev = serial.Serial(os.environ['SENSOR_PORT'], cls.BITRATE)
        if not dev.isOpen():
            dev.open()

        msg = dev.read(10)

        assert msg[0] == cls.BYTE_0
        assert msg[1] == cls.BYTE_1
        assert msg[9] == cls.BYTE_9

        pm2_5 = (256 * msg[3] + msg[2]) / 10.0
        pm10 = (256 * msg[5] + msg[4]) / 10.0
        assert sum(b for b in msg[2:8]) % 256 == msg[8]  # checksum

        return {'pm2.5': pm2_5, 'pm10': pm10}
