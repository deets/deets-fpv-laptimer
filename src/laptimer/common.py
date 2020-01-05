# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.


CHANNELS = {
    "A": [5865, 5845, 5825, 5805, 5785, 5765, 5745, 5725],  # Band A
    "B": [5733, 5752, 5771, 5790, 5809, 5828, 5847, 5866],  # Band B
    "E": [5705, 5685, 5665, 5645, 5885, 5905, 5925, 5945],  # Band E
    "F": [5740, 5760, 5780, 5800, 5820, 5840, 5860, 5880],  # Band F / Airwave
    "R": [5658, 5695, 5732, 5769, 5806, 5843, 5880, 5917],  # Race Band
}


CHANNEL_NAMES = (
    "E4", "R1", "E3", "E2", "R2", "E1", "A8", "R3",
    "B1", "F1", "A7", "B2", "F2", "A6", "R4", "B3",
    "F3", "A5", "B4", "F4", "A4", "R5", "B5", "F5",
    "A3", "B6", "F6", "R6", "A2", "B7", "F7", "A1",
    "B8", "F8", "R7", "E5", "E6", "R8", "E7", "E8",
)


def verify_channel_names():
    generated = tuple(
        name for _, name in sorted(
            (frequency, f"{band}{index}")
            for band, frequencies in CHANNELS.items()
            for index, frequency in enumerate(frequencies, start=1)
        )
    )
    assert generated == CHANNEL_NAMES, generated

verify_channel_names()
