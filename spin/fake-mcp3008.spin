VAR
   LONG stack[100]
   WORD value

PUB start(pin, nadir, peak)
  value := nadir
  cognew(work(pin, nadir, peak), @stack)

PUB in(cs)
  return value

PRI work(pin, nadir, peak) | raise, fall, v
  v := nadir
  raise := 2
  fall := 1
  dira[pin]~
  repeat
     if ina[pin]
       v += raise
     else
       v -= fall
     v <#= peak
     v #>= nadir
     value := v' ~> 16
     waitcnt(cnt + clkfreq / 100)
