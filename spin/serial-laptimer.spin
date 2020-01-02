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
  SERIAL_BPS = 115200
  MPC_MODE = 1 ' ch0 enabled, no diff
  MPC_DATA_PIN = 23
  MPC_CLK_PIN = 25
  MPC_CS_PIN = 27
  RTC_CLK = 22
  RTC_DATA = 24
  RTC_CS = 26

  ' The program modes
  MODE_IDLE = 0
  MODE_SCAN = 1
  MODE_LAPTIME = 2

OBJ
  serial: "FullDuplexSerial"
  mcp3008: "MCP3008"
  rtc6715: "RTC6715"

PUB main | mode, input
  serial.Start(RX_PIN, TX_PIN, 0, SERIAL_BPS)
  mcp3008.start(MPC_DATA_PIN, MPC_CLK_PIN, MPC_CS_PIN, MPC_MODE)

  ' setup CS for the one connected RTC6715
  dira[RTC_CS]~~   ' output
  outa[RTC_CS]~~
  rtc6715.init(RTC_CLK, RTC_DATA)

  mode := MODE_IDLE
  repeat
    input := serial.rxcheck
    if input <> -1
      case input
        "s": mode:= MODE_SCAN
        "i": mode := MODE_IDLE

    case mode
      MODE_IDLE: waitcnt(cnt + _clkfreq / 1000) ' just wait an ms
      MODE_SCAN: scan


PRI scan | freq, ch0
  freq := 0
  repeat freq from 0 to 39
    rtc6715.set_frequency(RTC_CS, freq)
    ' wait to stabilise, at least 50ms!
    waitcnt(cnt + _clkfreq / (1000 / 50))
    ch0 := mcp3008.in(0)
    serial.str(string("channel "))
    serial.dec(freq)
    serial.str(string(" rssi: "))
    serial.dec(ch0)
    serial.tx(13)
    serial.tx(10)
