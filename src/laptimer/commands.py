# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
import sys
import argparse

from .common import channel_type
from .propnode import PropellerNodeController


def setup_parser_common():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", default="/dev/ttyUSB0")
    parser.add_argument("--bps", type=int, default=115200)
    return parser


def setup_parser_tuning(parser):
    """
    Add the arguments required for tuning the node
    """
    parser.add_argument(
        "--channel",
        type=channel_type,
        action="append",
    )


def recorder_main():
    parser = setup_parser_common()
    setup_parser_tuning(parser)
    args = parser.parse_args()

    node = PropellerNodeController(
        args.port,
        args.bps,
    )
    if len(node) != len(args.channel):
        print(
            "Wrong number of channels, "
            f" needs to be {len(node)}!"
        )

    for rtc, channel in enumerate(args.channel):
        node.tune(rtc, channel)

    node.mode = "laptimer"
    try:
        while True:
            sys.stdout.buffer.write(node.readline())
    except KeyboardInterrupt:
        pass
