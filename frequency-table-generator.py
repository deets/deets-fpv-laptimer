#!/usr/bin/env python3

CHANNELS = {
    "A": [5865, 5845, 5825, 5805, 5785, 5765, 5745, 5725], # Band A
    "B": [5733, 5752, 5771, 5790, 5809, 5828, 5847, 5866], # Band B
    "E": [5705, 5685, 5665, 5645, 5885, 5905, 5925, 5945], # Band E
    "F": [5740, 5760, 5780, 5800, 5820, 5840, 5860, 5880], # Band F / Airwave
    "R": [5658, 5695, 5732, 5769, 5806, 5843, 5880, 5917], # Race Band
}


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
        print(name, frequency, hex(v), bin(v))
        vs.append(v)
    print(", ".join(hex(v) for v in vs))


if __name__ == '__main__':
    main()
