#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
"""
According to the documentation, the RTC6715 RSSI
value ranges from 0.5 to about 1.1 volt.

As we use a 10 Bit ADC from 0-3.3V, and for RotorHazard
only need 8 bit, we can spread the range.
"""

LOW = 0.3  # according to the datasheet 0.5, but experiments show this is better
HIGH = 1.45  # according to the datasheet 1.1, but experiments show this is better
VOLTAGE = 3.3
STEPS = 2**10

step = VOLTAGE / STEPS
b = int(LOW / step)
# the number of discrete
# steps we can expect between
# LOW and HIGH
# the scaling factor to map the range
# to our allowed 0..255
a = 255 / int((HIGH - LOW) / step)

if a < 1.0:
    # we can operate only with integers,
    # so we use fixed point arithmetig.
    # Multiplying by a * 2**16 and then shifiting 16 bits right
    # should do the trick
    a = int(a * 2**16)

print(b, a)
