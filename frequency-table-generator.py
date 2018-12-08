#!/usr/bin/env python3

CHANNELS = {
    "A": [5865, 5845, 5825, 5805, 5785, 5765, 5745, 5725],  # Band A
    "B": [5733, 5752, 5771, 5790, 5809, 5828, 5847, 5866],  # Band B
    "E": [5705, 5685, 5665, 5645, 5885, 5905, 5925, 5945],  # Band E
    "F": [5740, 5760, 5780, 5800, 5820, 5840, 5860, 5880],  # Band F / Airwave
    "R": [5658, 5695, 5732, 5769, 5806, 5843, 5880, 5917],  # Race Band
}

# These are according to TBS/Unify
HAM_CHANNELS = {
    5725, 5705, 5685, 5665, 5885, 5905,
    5880, 5658, 5695, 5732, 5880, 5917
}

FORBIDDEN_CHANNELS = {
    5645, 5925, 5945
}

AOMWAY_CHANNELS = (
    (5705, "A1"),
    (5685, "A2"),
    (5665, "A3"),
    (5645, "A4"),
    (5885, "A5"),
    (5905, "A6"),
    (5925, "A7"),
    (5945, "A8"),

    (5733, "B1"),
    (5752, "B2"),
    (5771, "B3"),
    (5790, "B4"),
    (5809, "B5"),
    (5828, "B6"),
    (5847, "B7"),
    (5866, "B8"),

    (5725, "C1"),
    (5745, "C2"),
    (5765, "C3"),
    (5785, "C4"),
    (5805, "C5"),
    (5825, "C6"),
    (5845, "C7"),
    (5865, "C8"),

    (5740, "D1"),
    (5760, "D2"),
    (5780, "D3"),
    (5800, "D4"),
    (5820, "D5"),
    (5840, "D6"),
    (5860, "D7"),
    (5880, "D8"),

    (5658, "E1"),
    (5695, "E2"),
    (5732, "E3"),
    (5769, "E4"),
    (5806, "E5"),
    (5843, "E6"),
    (5880, "E7"),
    (5917, "E8"),
)


def enumerate_channels():
    return sorted(
        (freq, "{}{}".format(band, i))
        for band, channels in CHANNELS.items()
        for i, freq in enumerate(channels, start=1)
    )


def calc_register(freq):
    # calculatute F_LO
    freq = freq - 479
    n = freq // 64
    a = (freq%64) // 2
    return a | n << 7


def main():
    vs = []
    for frequency, name in enumerate_channels():
        v = calc_register(frequency)
        print(name, frequency, hex(v), bin(v), "forbidden" if frequency in FORBIDDEN_CHANNELS else ("ham" if frequency in HAM_CHANNELS else "allowed"))
        vs.append(v)
    print(", ".join(hex(v) for v in vs))


if __name__ == '__main__':
    main()
