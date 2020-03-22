{{
SPI Laptimer using RX5808/RTC6715

(c) Diez Roggisch
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000

VAR
    long cog

PUB main
    start
    repeat

PRI start: okay
    okay := cognew(@spi_main, 0) + 1

PRI stop
    if cog
       cogstop(cog~ - 1)

DAT org

spi_main
   mov      miso_mask,     #1        wz ' setting wz to 0
   shl      miso_mask,     #3           ' hardcoded A3
   muxz     outa, miso_mask           ' set miso low
   muxnz    dira, miso_mask           ' and turn it output
:cs_loop
   waitpne  cs_mask, cs_mask
   mov      buffer, cnt
:bit_loop
   shr     buffer, #1       wc
   waitpeq  clk_mask, clk_mask
   muxc    outa, miso_mask
   waitpne  clk_mask, clk_mask
   and     ina, cs_mask              wz, nr   ' check for CS
   waitpeq  cs_mask, cs_mask
'if_z jmp  #:bit_loop
   ' MISO low
   mov     buffer, #1                wz
   muxz   outa, miso_mask
   jmp #:cs_loop

cs_mask long $1           ' A0
clk_mask long $2          ' A1
miso_mask  res 1
buffer   res 1