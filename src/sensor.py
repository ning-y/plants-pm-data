import os, serial

class Sensor:
    BITRATE = 9600
    BYTE_0 = 0xaa  # 'Message header'
    BYTE_1 = 0xc0  # 'Commander No.'
    BYTE_9 = 0xab  # 'Message tail'
    PORTS = [os.environ['SENSOR_PORT_{}'.format(i)] for i in range(1,5)]

    @classmethod
    def get_readings(cls):
        results = []
        for port in range(1, 5):
            try:
                results.append(cls.get_reading(port))
            except Exception as e:
                results.append(str(e))
        return results

    @classmethod
    def get_reading(cls, port_number):
        """
        Receives and interprets the UART message. Highly adapted from
        https://gist.github.com/marw/9bdd78b430c8ece8662ec403e04c75fe.
        Nova PM specifications from https://nettigo.pl/attachments/398.

        Parameters
        ----------
        port_number : int
            in [1, 4], inclusive
        """
        dev = serial.Serial(cls.PORTS[port_number-1], cls.BITRATE)
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
