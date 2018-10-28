{{
''***********************************************
''*  Program 6.1. Pulse-width modulation (PWM)
''*  Test Program.
''*  Author: Jon Titus 12-05-2014 Rev. 1
''*  Copyright 2014
''*  Released under Apache 2 license
''*  Two LEDs alternate bright-dim-bright cycles
''***********************************************
}}

CON _clkmode = xtal1 + pll16x           'Set MCU clock operation
    _xinfreq = 5_000_000                'Set for 5 MHz crystal

    data = 10
    chipselect  = 8
    clock  = 9

    mcp_cs = 12
    mcp_clock = 13
    mcp_mosi = 14
    mcp_miso = 15

    tx = 30
    rx = 31
    baud = 1000000
    channel_changes_per_second = 20

OBJ
  rtc    : "rtc6715"
  serial : "FullDuplexSerial"
  mcp    : "mcp3008"

PUB go | frequency, av
  rtc.init(chipselect, clock, data)
  serial.Start (rx, tx, 0, baud)
  mcp.init(mcp_cs, mcp_clock, mcp_mosi, mcp_miso)
  repeat
    repeat frequency from 0 to 39
        rtc.set_frequency(frequency)
        waitcnt(clkfreq/channel_changes_per_second + cnt)
        av := mcp.read_channel(0)
        serial.dec(av)
        if frequency < 39
          serial.Tx (58)
    serial.tx (13)
    serial.tx (10)
