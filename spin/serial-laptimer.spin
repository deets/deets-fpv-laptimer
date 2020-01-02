{{
Serial Line Laptimer using RX5808/RTC6715

(c) Diez Roggisch
}}

' f_Hz = FRQA / 2**32 * clkfreq
' -> f_hz / 80_000_000 * 2**32
CON _clkmode = xtal1 + pll16x           'Set MCU clock operation
  _clkfreq = 80_000_000
  TX_PIN  = 30
  RX_PIN  = 31
  MODE = 1 ' ch0 enabled, no diff
  DATA_PIN = 23
  CLK_PIN = 25
  CS_PIN = 27
  RTC_CLK = 22
  RTC_DATA = 24
  RTC_CS = 26
OBJ
  serial: "FullDuplexSerial"
  mcp3008: "MCP3008"
  rtc6715: "RTC6715"

PUB main | debugSemID, ch0, freq
  serial.Start(RX_PIN, TX_PIN, 0, 115200)
  mcp3008.start(DATA_PIN, CLK_PIN, CS_PIN, MODE) '

  ' setup CS for the one connected RTC6715
  dira[RTC_CS]~~   ' output
  outa[RTC_CS]~~
  rtc6715.init(RTC_CLK, RTC_DATA)
  freq := 0
  repeat
    repeat freq from 0 to 39
      rtc6715.set_frequency(RTC_CS, freq)
      ' wait to stabilise, at least 50ms!
      waitcnt(cnt + _clkfreq / 20) ' 0.3s
      ch0 := mcp3008.in(0)
      serial.str(string("channel "))
      serial.dec(freq)
      serial.str(string(" rssi: "))
      serial.dec(ch0)
      serial.tx(13)
      serial.tx(10)
    serial.str(string("----------"))
    serial.tx(13)
    serial.tx(10)
    waitcnt(cnt + _clkfreq / 2) ' 0.3s
