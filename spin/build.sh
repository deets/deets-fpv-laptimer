#!/usr/bin/env python3.7
# -*- mode: python -*-
import os
import sys
import subprocess

from common import OPENSPIN, PROPMAN


def main():
    main_spin = sys.argv[1]
    main_binary = os.path.splitext(main_spin)[0] + ".binary"
    subprocess.run(
        [OPENSPIN, main_spin],
        check=True
    )
    # assert os.path.exists(main_binary)
    # subprocess.run(
    #     [PROPMAN, main_binary],
    #     check=True
    # )


if __name__ == '__main__':
    main()
