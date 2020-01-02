#!/usr/bin/env python3.7
# -*- mode: python -*-
import os
import sys
import subprocess
import pathlib
import platform

if platform.system() == "Linux":
    OPENSPIN = pathlib.Path("/usr/bin/openspin")
    PROPMAN = pathlib.Path("/usr/bin/propman")
else:
    OPENSPIN = pathlib.Path("/Applications/PropellerIDE.app/Contents/MacOS/openspin")
    PROPMAN = pathlib.Path("/Applications/PropellerIDE.app/Contents/MacOS/propman")
assert OPENSPIN.exists(), OPENSPIN
assert PROPMAN.exists(), PROPMAN


def main():
    main_spin = sys.argv[1]
    main_binary = os.path.splitext(main_spin)[0] + ".binary"
    subprocess.run(
        [OPENSPIN, main_spin],
        check=True
    )
    assert os.path.exists(main_binary)
    subprocess.run(
        [PROPMAN, main_binary],
        check=True
    )


if __name__ == '__main__':
    main()
