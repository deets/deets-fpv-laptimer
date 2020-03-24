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
    mov      miso_mask, #1        nr, wz ' force wz to 0
    muxz     outa, miso_mask             ' set miso low
    muxnz    dira, miso_mask             ' and turn it output
:cs_loop
    waitpne  cs_mask, cs_mask
    mov      buffer, incoming
    mov      incoming, #0
    mov      bitcount, #32
:bit_loop
    shl      buffer, #1       wc
    muxc     outa, miso_mask
    waitpeq  clk_mask, clk_mask    ' clk high
    test     mosi_mask, ina   wc
    rcl      incoming, #1
    waitpne  clk_mask, clk_mask    ' clk low
    sub      bitcount, #1       wz
if_nz jmp     #:bit_loop
    waitpeq  cs_mask, cs_mask
    mov      buffer, #1                wz
    muxz     outa, miso_mask
    jmp      #:cs_loop

cs_mask  long $1           ' A0 .. A3
clk_mask long $2
mosi_mask long $4
miso_mask long $8
data     long $aa00ff00

buffer   long 0
incoming long 0
bitcount long 0
