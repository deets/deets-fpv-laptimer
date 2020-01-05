# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.

import os

from setuptools import setup, find_packages

# Meta information
version = open("VERSION").read().strip()
dirname = os.path.dirname(__file__)
author = open("AUTHOR").read().strip()

# Save version and author to __meta__.py
path = os.path.join(dirname, "src", "laptimer", "__meta__.py")
data = f"""# Automatically created. Please do not edit.
__version__ = u"{version}"
__author__ = u"{author}"
"""

with open(path, "wb") as outf:
    outf.write(data.encode())

setup(
    # Basic info
    name="deets-fpv-laptimer",
    version=version,
    author=author,
    author_email="deets@web.de",
    url="https://github.com/deets/deets-fpv-laptimer",
    description="A FPV drone racing laptimer",
    #long_description=open("README.rst").read(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX",
        "Programming Language :: Python",
    ],

    # Packages and depencies
    package_dir={"": "src"},
    packages=find_packages("src"),
    install_requires=[
        "tornado",
        "rx",
    ],
    extras_require={
        "dev": [
        ],
    },

    # Data files
    package_data={
        # "python_boilerplate": [
        #     "templates/*.*",
        #     "templates/license/*.*",
        #     "templates/docs/*.*",
        #     "templates/package/*.*"
        # ],
    },

    # Scripts
    entry_points={
        "console_scripts": [
            "deets-fpv-laptimer = laptimer:main",
            "deets-fpv-recorder = laptimer:recorder_main",
        ],
    },

    # Other configurations
    zip_safe=False,
    platforms="any",
)
