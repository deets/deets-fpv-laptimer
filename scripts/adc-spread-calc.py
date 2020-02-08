#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
"""
According to the documentation, the RTC6715 RSSI
value ranges from 0.5 to about 1.1 volt.

As we use a 10 Bit ADC from 0-3.3V, and for RotorHazard
only need 8 bit, we can spread the range.
"""

LOW = 0.38  # according to the datasheet 0.5, but experiments show this is better
HIGH = 1.15
VOLTAGE = 3.3
STEPS = 2**10

step = VOLTAGE / STEPS
b = int(LOW / step)
# the number of discrete
# steps we can expect between
# LOW and HIGH
# If this is below 255, we don't have to do anything
a = (HIGH - LOW) / step

print(b, a)
