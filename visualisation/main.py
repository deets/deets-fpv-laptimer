import threading
import re
import serial

from bokeh.models import ColumnDataSource
from bokeh.plotting import curdoc, figure
from bokeh.layouts import column
from bokeh.models import FactorRange, Range1d

CHANNEL_NAMES = (
    "E4", "R1", "E3", "E2", "R2", "E1", "A8", "R3",
    "B1", "F1", "A7", "B2", "F2", "A6", "R4", "B3",
    "F3", "A5", "B4", "F4", "A4", "R5", "B5", "F5",
    "A3", "B6", "F6", "R6", "A2", "B7", "F7", "A1",
    "B8", "F8", "R7", "E5", "E6", "R8", "E7", "E8",
)

DEFAULT_BAUD = 230400


def read_data(doc, source, port="/dev/ttyUSB0", baudrate=DEFAULT_BAUD):
    conn = serial.Serial(
        port=port,
        baudrate=baudrate,
    )
    readings = [0] * 40
    while True:
        # Data looks like this:
        # s<count>:<channel0>:<reading0>:...:
        # note the trailing colon!
        line = conn.readline().decode("ascii")
        parts = line.split(":")
        m = re.match(r"s(\d+)", parts[0])
        if m:
            count = int(m.group(1))
            assert len(parts) == count * 2 + 2
            payload = parts[1:-1]
            for channel, value in zip(payload[::2], payload[1::2]):
                channel, value = int(channel), int(value)
                readings[channel] = value

            patch = dict(
                readings=[(slice(0, 40), readings)],
            )
            doc.add_next_tick_callback(
                lambda: source.patch(patch),
            )
        else:
            print("malformed data")


def main():
    # This is important! Save curdoc() to make sure all threads
    # see the same document.
    doc = curdoc()
    data = dict(
        channel_names=CHANNEL_NAMES,
        left=list(range(0, 80, 2)),
        right=list(range(1, 81, 2)),
        bottom=[0] * 40,
        readings=list([20] for _ in range(1, 41))
    )

    source = ColumnDataSource(
            data=data,
    )

    channel_figure = figure(
        width=600,
        height=400,
        x_range=FactorRange(*CHANNEL_NAMES),
        y_range=Range1d(0, 1024),
    )
    channel_figure.vbar(
        x="channel_names",
        top="readings", width=0.9,
        alpha=0.5,
        source=source,
    )
    layout = column(children=[channel_figure], sizing_mode='stretch_both')
    doc.add_root(layout)

    t = threading.Thread(target=read_data, args=(doc, source))
    t.daemon = True
    t.start()


main()
