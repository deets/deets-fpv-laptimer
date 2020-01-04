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
  MPC_DATA_PIN = 23
  MPC_CLK_PIN = 25
  MPC_CS_PIN = 27
  RTC_CLK = 22
  RTC_DATA = 24
  RTC_COUNT = 2

  ' The program modes
  MODE_IDLE = 0
  MODE_SCAN = 1
  MODE_LAPTIME = 2

DAT
  RTC_CS byte 26, 20
OBJ
  serial: "FullDuplexSerial"
  mcp3008: "MCP3008"
  rtc6715: "RTC6715"

PUB main | mode, input
  serial.Start(RX_PIN, TX_PIN, 0, SERIAL_BPS)
  mcp3008.start(MPC_DATA_PIN, MPC_CLK_PIN, MPC_CS_PIN, (|< RTC_COUNT) - 1 )
  rtc_init

  mode := MODE_IDLE
  repeat
    input := serial.rxcheck
    if input <> -1
      case input
        "s": mode:= MODE_SCAN
        "l": mode := MODE_LAPTIME
        "i": mode := MODE_IDLE
             serial.tx("i")
             nl
        "c": serial.tx("c")
             serial.dec(RTC_COUNT)
             serial.tx(":")
             case mode
                MODE_IDLE: serial.tx("i")
                MODE_SCAN: serial.tx("s")
                MODE_LAPTIME: serial.tx("l")
             nl
        "t": tune
    case mode
      MODE_IDLE: waitcnt(cnt + _clkfreq / 1000) ' just wait an ms
      MODE_SCAN: scan
      MODE_LAPTIME: laptime

PRI tune | rtc, channel
   rtc := serial.rx
   rtc -= "0" ' adjust for simpler entry via a terminal
   channel := serial.rx
   channel -= "0" ' adjust for simpler entry via a terminal
   if rtc => 0 and rtc < RTC_COUNT
     if channel => 0 and channel < 40
       rtc6715.set_frequency(RTC_CS[rtc], channel)
       serial.str(string("t"))
       serial.dec(rtc)
       serial.str(string(":"))
       serial.dec(channel)
     else
       serial.str(string("eINVALID TUNING PARAMETER CHANNEL"))
       serial.dec(channel)
   else
     serial.str(string("eINVALID TUNING PARAMETER RTC "))
     serial.dec(rtc)
   nl

PRI laptime | rssi[RTC_COUNT], cs, h
  h := cnt
  repeat cs from 0 to RTC_COUNT - 1
    rssi[cs] := mcp3008.in(cs)
  serial.tx("l")
  serial.hex(h, 8)
  serial.tx(":")
  repeat cs from 0 to RTC_COUNT - 1
     h := rssi[cs]
     serial.hex(h, 6)
     serial.tx(":")
  nl

PRI scan | freq, channel_reading, cs, hfreq
  freq := 0
  repeat freq from 0 to 39
    repeat cs from 0 to RTC_COUNT - 1
      hfreq := (freq + 40 / RTC_COUNT * cs) // 40
      rtc6715.set_frequency(RTC_CS[cs], hfreq)

    ' wait to stabilise, at least 50ms!
    waitcnt(cnt + _clkfreq / (1000 / 50))
    serial.tx("s")
    serial.dec(RTC_COUNT)
    serial.tx(":")
    repeat cs from 0 to RTC_COUNT - 1
      hfreq := (freq + 40 / RTC_COUNT * cs) // 40
      serial.dec(hfreq)
      channel_reading := mcp3008.in(cs)
      serial.str(string(":"))
      serial.dec(channel_reading)
      serial.str(string(":"))
    nl

PRI rtc_init | cs
  ' setup CS for the one connected RTC6715
  repeat cs from 0 to RTC_COUNT - 1
    dira[RTC_CS[cs]]~~   ' output
    outa[RTC_CS[cs]]~~   ' high

  rtc6715.init(RTC_CLK, RTC_DATA)

PRI nl
    serial.tx(13)
    serial.tx(10)
