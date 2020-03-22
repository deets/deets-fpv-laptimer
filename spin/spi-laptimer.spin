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
   mov      sig_mask,     #1        wz ' setting wz to 0 while
   shl      sig_mask,     #4           ' hardcoded A4
   muxnz    outa,   sig_mask           ' set a4 high
   muxnz    dira,   sig_mask           ' and turn it output
:cs_loop
   waitpne  cs_mask, cs_mask
   muxz    outa,   sig_mask
   waitpeq  cs_mask, cs_mask
   muxnz     outa,   sig_mask
   jmp      #:cs_loop

cs_mask long $1           ' A0 is CS
sig_mask  res 1
