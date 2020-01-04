#!/usr/bin/env python3.7
# -*- mode: python -*-
import os
import sys
import subprocess

from common import OPENSPIN, PROPMAN


def main():
    main_spin = sys.argv[1]
    main_eeprom = os.path.splitext(main_spin)[0] + ".eeprom"
    subprocess.run(
        [OPENSPIN, main_spin, "-e"],
        check=True
    )
    assert os.path.exists(main_eeprom)
    subprocess.run(
        [PROPMAN, "-w", main_eeprom],
        check=True
    )


if __name__ == '__main__':
    main()
