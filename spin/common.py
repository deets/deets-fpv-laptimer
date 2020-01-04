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
