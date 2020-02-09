{{
I2C Line Laptimer using RX5808/RTC6715

(c) Diez Roggisch
}}

' f_Hz = FRQA / 2**32 * clkfreq
' -> f_hz / 80_000_000 * 2**32
CON _clkmode = xtal1 + pll16x           'Set MCU clock operation
  _clkfreq = 80_000_000
  SCA_PIN  = 21
  SCL_PIN  = 19
  ADDRESS = 8
  NODE_API_LEVEL = 21

  MPC_DATA_PIN = 23
  MPC_CLK_PIN = 25
  MPC_CS_PIN = 27
  RTC_CLK = 22
  RTC_DATA = 24
  RTC_COUNT = 1

  ' for debugging
  TX_PIN  = 30
  RX_PIN  = 31
  SERIAL_BPS = 115200

  RTC_CS = 20 ' for now just one RTC
  ADC_ADJUST_B = 93 ' see scripts/adc-spread-calc.py
  ADJ_ADJUST_A = 46942

  BIT_FILTER_DEPTH = 7

  OFFSET_LAP_COUNT = 7
  OFFSET_MS_SINCE_LAP = 8
  OFFSET_RSSI = 10
  OFFSET_PEAK = 11
  OFFSET_LAP_PEAK = 12
  OFFSET_LOOP_US = 13
  OFFSET_CROSSING_FLAGS = 15
  OFFSET_LAP_NADIR = 16
  OFFSET_NADIR = 17

  LAP_TRIGGER_PIN = 17

  START_FREQUENCY = 5658
VAR
  BYTE enter_at, exit_at, crossing, lapcount, lap_nadir, lap_peak
  WORD lap_timestamp
  LONG filtered_rssi

OBJ
  i2c: "i2c"
  serial: "FullDuplexSerial"
  'mcp3008: "MCP3008"
  mcp3008: "fake-mcp3008"
  rtc6715: "RTC6715"

PUB main | rssi, peak, nadir, timestamp
  peak := 0
  nadir := $ff

  crossing := 0
  enter_at := 140
  exit_at := 80
  lapcount := 0

  serial.Start(RX_PIN, TX_PIN, 0, SERIAL_BPS)
  rtc6715.init(RTC_CLK, RTC_DATA)
  i2c.Start(SCL_PIN, SCA_PIN, ADDRESS)
  'mcp3008.start(MPC_DATA_PIN, MPC_CLK_PIN, MPC_CS_PIN, (|< RTC_COUNT) - 1 )
  mcp3008.start(LAP_TRIGGER_PIN, 140, 316)
  rtc6715.set_frequency(RTC_CS, START_FREQUENCY)
  store_word(START_FREQUENCY, 3)

  ' 0 Address
  '
  ' 1 $25 (needed for node-api-level call
  ' 2 NODE_API_LEVEL
  '
  ' 3 READ_FREQUENCY / WRITE_FREQUENCY H
  ' 4 READ_FREQUENCY / WRITE_FREQUENCY L
  '
  ' 5 R/W ENTER_AT_LEVEL
  ' 6 R/W EXIT_AT_LEVEL
  '
  ' READ_LAP_STATS
  ' Total size: 22 - 7 + 1== 16, plus 1 checksum -> 17. That's
  ' what the RHInterface.py also signifies
  ' 7 lapcount
  ' 8 ms since last lap, H
  ' 9 ms since last lap, L
  ' 10 rssi
  ' 11 peak
  ' 12 lap peak
  ' 13 loop micros H
  ' 14 loop micros L
  ' 15 crossing & flags
  ' 16 lap nadir
  ' 17 nadir
  ' 18 extremum rssi
  ' 19 first time H
  ' 20 first time L
  ' 21 duration H
  ' 22 duration L

  i2c.put(0, ADDRESS)
  i2c.put(1, $25)
  i2c.put(2, NODE_API_LEVEL)

  i2c.put(5, enter_at) ' enter
  i2c.put(6, exit_at) ' exit

  repeat
    timestamp := cnt / (_clkfreq / 1000) ' timestamp in milliseconds
    rssi := mcp3008.in(0)
    rssi -= ADC_ADJUST_B
    rssi *= ADJ_ADJUST_A
    ' serial.dec(rssi >> 16)
    ' serial.tx($20)
    filtered_rssi += (rssi - filtered_rssi) ~> BIT_FILTER_DEPTH
    rssi := filtered_rssi >> 16
    ' serial.dec(filtered_rssi >> 16)
    ' nl
    compute_lap(timestamp, rssi)
    nadir <#= rssi
    peak #>= rssi
    lap_nadir <#= rssi
    lap_peak #>= rssi

    i2c.put(OFFSET_RSSI, rssi)
    i2c.put(OFFSET_PEAK, peak)
    i2c.put(OFFSET_NADIR, nadir)
    store_word(timestamp - lap_timestamp, OFFSET_MS_SINCE_LAP)

    if i2c.checkFlags <> 0
        process_registers

PRI nl
    serial.tx(13)
    serial.tx(10)

PRI process_registers | frequency
    if i2c.checkFlag(3) AND i2c.checkFlag(4) ' frequency was set
      frequency := (i2c.get(3) << 8) | i2c.get(4)
      rtc6715.set_frequency(RTC_CS, frequency)

    if i2c.checkFlag(5) ' enter at
      enter_at := i2c.get(5)
      ' serial.str(string("enter at:"))
      ' serial.dec(enter_at)
      ' nl
    if i2c.checkFlag(6) ' exit at
      exit_at := i2c.get(6)
      ' serial.str(string("exit at:"))
      ' serial.dec(exit_at)
      ' nl
    i2c.clearFlags

PRI store_word(data, a) | offset
    offset := i2c.register + a
    byte[offset + 1] := data & $ff
    byte[offset] := data >> 8

PRI compute_lap(timestamp, rssi)
    ' serial.dec(rssi)
    ' serial.tx($20)
    ' serial.dec(crossing)
    ' nl
    if crossing == 0 AND rssi => enter_at
       crossing := 1
       lap_timestamp := timestamp
       lap_nadir := rssi
       lap_peak := rssi
       ' serial.str(string("crossing"))
       ' nl
    if crossing == 1 AND rssi <= exit_at
       crossing := 0
       lapcount += 1
       i2c.put(OFFSET_LAP_COUNT, lapcount)
       store_word((timestamp - lap_timestamp) ~> 1, 21) ' length of crossing
       lap_timestamp := (timestamp + lap_timestamp) ~> 1
       store_word(lap_timestamp, 19) ' middle of crossing
       i2c.put(OFFSET_LAP_PEAK, lap_peak)
       i2c.put(OFFSET_LAP_NADIR, lap_nadir)
       ' serial.str(string("lap:"))
       ' serial.dec(lapcount)
       nl