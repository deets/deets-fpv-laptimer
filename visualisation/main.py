from functools import partial
from random import random
import threading
import copy
import serial

from bokeh.models import ColumnDataSource
from bokeh.plotting import curdoc, figure
from bokeh.layouts import column

from tornado import gen


def read_data(doc, source, port="/dev/ttyUSB0", baudrate=1000_000):
    conn = serial.Serial(
        port=port,
        baudrate=baudrate,
    )
    while True:
        line = conn.readline().decode("ascii")
        values = line.split(":")
        min_ = 1024
        if len(values) == 40:
            values = [int(v) for v in values]
            min_ = min(min_, min(values))
            readings = [v - min_ for v in values]
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
        left=list(range(0, 80, 2)),
        right=list(range(1, 81, 2)),
        bottom=[0] * 40,
        readings=list([20] for _ in range(1, 41))
    )

    source = ColumnDataSource(
            data=data,
    )
    channel_figure = figure(width=600, height=400)
    channel_figure.quad(
        left="left",
        right="right",
        bottom="bottom",
        top="readings",
        source=source,
    )
    layout = column(children=[channel_figure], sizing_mode='stretch_both')
    doc.add_root(layout)

    t = threading.Thread(target=read_data, args=(doc, source))
    t.daemon = True
    t.start()


main()
