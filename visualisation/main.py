import threading
import queue
import re
import serial
import time
import rx.subject
import struct

from bokeh.models import ColumnDataSource
from bokeh.plotting import curdoc, figure
from bokeh.layouts import column, row
from bokeh.models import FactorRange, Range1d
from bokeh.models import Select

CHANNEL_NAMES = (
    "E4", "R1", "E3", "E2", "R2", "E1", "A8", "R3",
    "B1", "F1", "A7", "B2", "F2", "A6", "R4", "B3",
    "F3", "A5", "B4", "F4", "A4", "R5", "B5", "F5",
    "A3", "B6", "F6", "R6", "A2", "B7", "F7", "A1",
    "B8", "F8", "R7", "E5", "E6", "R8", "E7", "E8",
)

PORT = "/dev/ttyUSB0"
DEFAULT_BAUD = 115200
RSSI_HISTORY = 200

class NodeController:

    def __init__(self):
        self._conn = serial.Serial(
            port=PORT,
            baudrate=DEFAULT_BAUD,
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
        command = self._conn.read(1)
        if command == b'l':
            return command + self._conn.read(4 * (self._number_of_vtx + 1))
        else:
            return command + self._conn.readline()

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


class PropellerTimestampProcessor:

    CPUFREQ = 80_000_000

    def __init__(self):
        self._last_ts = None
        self.signal = rx.subject.Subject()

    def __call__(self, timestamp):
        if self._last_ts is not None:
            diff = timestamp - self._last_ts
            if diff < -2**31:
                diff += 2**32
            self.signal.on_next(diff / self.CPUFREQ)
        self._last_ts = timestamp


class Visualisation:

    def __init__(self, node):
        self._node = node
        self._timestamp_processor = PropellerTimestampProcessor()
        self._lines_q = queue.Queue()

        number_of_vtx = node.configuration()[0]
        self._laptime_format = "<I" + "I" * number_of_vtx

        doc = self._doc = curdoc()

        scanner_data = dict(
            channel_names=CHANNEL_NAMES,
            left=list(range(0, 80, 2)),
            right=list(range(1, 81, 2)),
            bottom=[0] * 40,
            readings=list([20] for _ in range(1, 41))
        )

        self._scanner_source = ColumnDataSource(
                data=scanner_data,
        )
        # the aspict ratio is maintained over
        # the scaling parameter.
        scanner_figure = figure(
            width=600,
            height=100,
            x_range=FactorRange(*CHANNEL_NAMES),
            y_range=Range1d(0, 1024),
        )
        scanner_figure.vbar(
            x="channel_names",
            top="readings", width=0.9,
            alpha=0.5,
            source=self._scanner_source,
        )

        mode_selector = Select(
            value="idle",
            options=["idle", "scanner", "laptimer"],
        )

        mode_selector.on_change(
            'value',
            lambda attr, old, new: setattr(node, "mode", new)
        )
        laptime_row, self._laptime_sources = self._setup_laptimer(number_of_vtx)
        time_diff_graph = self._setup_timediff_graph(self._timestamp_processor.signal)
        layout = column(
            children=[
                mode_selector,
                scanner_figure,
                laptime_row,
                time_diff_graph,
            ],
            sizing_mode="scale_width"
        )
        doc.add_root(layout)

    def start_background_reader(self):
        t = threading.Thread(target=self._background_task)
        t.daemon = True
        t.start()

    def _setup_timediff_graph(self, signal):
        p = figure(
            y_axis_label="time delta",
            width=600,
            height=50,
        )
        data = dict(
            x=[i for i in range(RSSI_HISTORY)],
            timedelta=[0] * RSSI_HISTORY
            )
        td_source = ColumnDataSource(
            data=data
        )
        p.circle(x='x', y="timedelta", source=td_source)

        def update_td(tdiff):
            timedelta = td_source.data['timedelta']
            timedelta = timedelta[1:]
            timedelta.append(tdiff * 1000) # convert to ms
            patch = dict(
                timedelta=[(slice(0, RSSI_HISTORY), timedelta)],
            )
            td_source.patch(patch)

        signal.subscribe(on_next=update_td)
        return p

    def _scanning(self, results):
        parts = results.decode("ascii").split(":")
        m = re.match(r"(\d+)", parts[0])
        if m:
            count = int(m.group(1))
            assert len(parts) == count * 2 + 2
            payload = parts[1:-1]
            readings = self._scanner_source.data["readings"]
            for channel, value in zip(payload[::2], payload[1::2]):
                channel, value = int(channel), int(value)
                readings[channel] = value

            # a patch actually consists of positions
            # and new values as list of tuples
            patch = dict(
                readings=[(slice(0, 40), readings)],
            )
            self._scanner_source.patch(patch)

    def _setup_laptimer(self, number_of_vtx):
        laptime_sources = []
        laptime_rows = []
        for i in range(number_of_vtx):
            p = figure(y_axis_label="rssi", y_range=Range1d(0, 1024))
            data = dict(
                x=[i for i in range(RSSI_HISTORY)],
                rssi=[100 * (i + 1)] * RSSI_HISTORY
            )
            lt_source = ColumnDataSource(
                data=data
            )
            p.circle(x='x', y="rssi", source=lt_source)
            laptime_sources.append(lt_source)
            tuner = Select(
                value=CHANNEL_NAMES[0],
                options=list(CHANNEL_NAMES)
                )
            tuner.on_change(
                'value',
                lambda attr, old, new, rtc=i: self._node.tune(rtc, new)
            )
            # ensure our default state is correct
            self._node.tune(i, CHANNEL_NAMES[0])
            vtx_column = column(children=[tuner, p], sizing_mode="scale_width")
            laptime_rows.append(vtx_column)

        return (
            row(children=laptime_rows, sizing_mode="stretch_both"),
            laptime_sources,
        )

    def _laptime(self, results):
        timestamp, *entries = struct.unpack(self._laptime_format, results)
        self._timestamp_processor(timestamp)

        for entry in entries:
            value = entry & 0x00ffffff
            number = (entry >> 24) & 0xff
            lt_source = self._laptime_sources[number]
            rssi = lt_source.data['rssi'][1:]
            rssi.append(value)
            patch = dict(rssi=[(slice(0, len(rssi)), rssi)])
            lt_source.patch(patch)

    def _background_task(self):
        while True:
            line = self._node.readline()
            self._lines_q.put(line)
            self._doc.add_next_tick_callback(self._process_lines)

    def _process_lines(self):
        # For some reason we get multiple callbacks
        # in the mainloop. So instead of relying on
        # one callback per line, we gather them
        # and process as many of them as we find.
        for _ in range(self._lines_q.qsize()):
            line = self._lines_q.get()
            command = bytes([line[0]])
            results = line[1:]
            callback = {
                b"s": self._scanning,
                b"l": self._laptime,
             }.get(command, lambda results: print("unknown:", command))
            callback(results)


def main():
    # This is important! Save curdoc() to make sure all threads
    # see the same document.
    node = NodeController()
    number_of_vtx, _ = node.configuration()

    visualisation = Visualisation(node)
    visualisation.start_background_reader()


main()
