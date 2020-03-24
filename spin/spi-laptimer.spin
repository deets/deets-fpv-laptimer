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
'    mov      miso_mask,     #1   wz ' setting wz to 0
'    shl      miso_mask,     #3           ' hardcoded A3
'    muxnz    outa, miso_mask           ' set miso high
'    muxnz    dira, miso_mask           ' and turn it output
' :clk_test_loop
'    waitpeq  clk_mask, clk_mask
'    muxz     outa, miso_mask           ' set miso low
'    waitpne  clk_mask, clk_mask
'    muxnz    outa, miso_mask           ' set miso low
'    jmp      #:clk_test_loop

    mov      miso_mask,     #1        nr, wz ' force wz to 0
    muxz     outa, miso_mask             ' set miso low
    muxnz    dira, miso_mask             ' and turn it output
:cs_loop
    waitpne  cs_mask, cs_mask
    mov      buffer, cnt
    mov      bitcount, #31
:bit_loop
    shr      buffer, #1       wc
    waitpeq  clk_mask, clk_mask
    muxc     outa, miso_mask
    waitpne  clk_mask, clk_mask
    sub      bitcount, #1       wz
if_nz jmp     #:bit_loop
    ' MISO low
    waitpeq  cs_mask, cs_mask
    mov      buffer, #1                wz
    muxz     outa, miso_mask
    jmp      #:cs_loop

cs_mask  long $1           ' A0
clk_mask long $2          ' A1
miso_mask long $8
data     long $aa00ff00

buffer   long 0
bitcount long 0