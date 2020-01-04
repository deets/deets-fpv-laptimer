# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
import struct
import serial
import time

from .common import CHANNEL_NAMES


class PropellerNodeController:

    def __init__(self, port, baud):
        self._conn = serial.Serial(
            port=port,
            baudrate=baud,
        )
        self._mode = None
        self.mode = "idle"
        self._number_of_vtx, _ = self.configuration()

    @property
    def mode(self):
        return self._mode

    @mode.setter
    def mode(self, value):
        if value != self._mode:
            self._conn.write(
                dict(
                    idle=b"i",
                    scanner=b"s",
                    laptimer=b"l",
                )[value]
            )
            self._mode = value

    def readline(self):
        # the protocol is line-based but for
        # the laptime info - that's as compact as possible
        return self._conn.readline()

    def idle(self):
        self._conn.write(b"i")

    def configuration(self):
        self._conn.write(b"c")
        while True:
            try:
                line = self.readline().decode("ascii")
                if line.startswith("c"):
                    break
            except UnicodeDecodeError:
                # can happen if there is residual binary
                # data
                pass

        number_of_vtx, mode = line.strip().split(":")
        return int(number_of_vtx[1:]), mode

    def tune(self, rtc, channel):
        channel_number = CHANNEL_NAMES.index(channel)
        cmd = struct.pack(
            "BB",
            rtc + ord("0"),
            channel_number + ord("0"),
        )
        self._conn.write(b"t")
        time.sleep(.1)
        self._conn.write(cmd)
