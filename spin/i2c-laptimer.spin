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
  ADDRESS = $33
  NODE_API_LEVEL = 21

  MPC_DATA_PIN = 23
  MPC_CLK_PIN = 25
  MPC_CS_PIN = 27
  RTC_CLK = 22
  RTC_DATA = 24
  RTC_COUNT = 1

  ' The program modes
  MODE_IDLE = 0
  MODE_SCAN = 1
  MODE_LAPTIME = 2

DAT
  RTC_CS byte 20, 18
OBJ
  i2c: "i2c"
  mcp3008: "MCP3008"
  rtc6715: "RTC6715"

PUB main | mode, input, pause
  i2c.Start(SCL_PIN, SCA_PIN, ADDRESS)
  mcp3008.start(MPC_DATA_PIN, MPC_CLK_PIN, MPC_CS_PIN, (|< RTC_COUNT) - 1 )
  i2c.put(0, ADDRESS)
  i2c.put(1, NODE_API_LEVEL)
  repeat
