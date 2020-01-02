{{
MultiCogSerialDebug.spin : V1.1
Derived from SerialMirror V07.05.10
  All printing (also from multiple COGs) is done using cprintf. Each cprintf call is a message.
  The more parameter in cprintf lets you prohibit that the message is interleaved with
  text from another COG. To keep output clear, end each (compound) message with a \r or \r\n.
  Receiving should be done by a single COG that can dispatch received messages

  Example on using cprintf while prohibiting interleaving
  debug.cprintf(string("Spin Stamp Application version "),0,true) 'start of compound message
  debug.cprintf(string("%d."),major,true)
  debug.cprintf(string("%d."),minor,true)
  debug.cprintf(string("%d\r"),build,false)                       'last of compound message
  Set more to false for a simple message or to end a compound message.

SerialMirror.spin : V07.05.10

Derived from: Full-Duplex Serial Driver v1.1
              (C) 2006 Parallax, Inc.


It has been extended in the following ways:
1) Make allowance for different buffer sizes. I've set the default buffer to
   64 bytes as this is large enough to contain a complete incoming/outgoing
   message for my protocol.
2) Check for a stop bit!! If a stop bit is not present then the received byte
   is dropped. No flags of any sort are set. It's up to a higher level of the
   protocol to check the message for integrity.
3) Variables have been moved to DAT space.
   The significance of this is not obvious at first, but what it means is that
   every instance of this object shares the same variable space. Why do this?
   If you have multiple nested objects, then serial comms can be added to all
   of them. ONLY the top object must call the start method. The nested objects
   then have full comms access. A simple example is:
   ┌────────────────────────────────────────────────────────────────────┐
   │  APP_SerialMirror.spin                                             │
   ├────────────────────────────────────────────────────────────────────┤
   │CON                                                                 │
   │  _clkmode      = xtal1 + pll16x                                    │
   │  _xinfreq      = 5_000_000                                         │
   │                                                                    │
   │  BaudRate      = 38400         'Baud                               │
   │  RxPin         = 31            'For RS232                          │
   │  TxPin         = 30            'For RS232                          │
   │  CommsMode     = %0000         'See SerialMirror.spin for meaning  │
   │                                                                    │
   │OBJ                                                                 │
   │  Debug : "SerialMirror"                                            │
   │  Test : "TestObject"                                               │
   │                                                                    │
   │PUB Start                                                           │
   │  Debug.start(RxPin, TxPin, CommsMode, BaudRate)                    │
   │  Test.SayHello                                                     │
   └────────────────────────────────────────────────────────────────────┘
   ┌────────────────────────────────────────────────────────────────────┐
   │  TestObject.spin                                                   │
   ├────────────────────────────────────────────────────────────────────┤
   │OBJ                                                                 │
   │  Debug : "SerialMirror"                                            │
   │                                                                    │
   │PUB SayHello                                                        │
   │  Debug.str(string("Hello",13,10))                                  │
   └────────────────────────────────────────────────────────────────────┘
4) This object is NOT suitable for driving multiple serial ports.
   If you want multiple serial ports each with single object access, then
   use FullDuplexSerial.
   If you want serial comms through the same port from multiple objects,
   then use THIS object.
   If you want multiple serial ports each with multi-object usage, then copy
   and rename this files for the number of unique serial ports.
5) Added GetNumber which will receive a number (positive or negative) from
   the serial port in either decimal, binary or hexadecimal notation.
6) Added extra comments to the assembler section - for the newbies. I've been
   doing this propeller stuff for a month now, so I guess that makes me an
   old hand.
7) Added CrLf which does just that - purely a conveniance function for me.
}}


CON
  'BEWARE BEWARE : buffer_length can be any one of:
  '   2, 4, 8, 16, 32, 64, 128 or 256
  '   BUT, if you change it, you MUST also make sure that the rx_buffer and
  '   tx_buffer variables are adjusted in the DAT space. This is because there
  '   is no way to declare an array in DAT space, so the length must be
  '   manually defined.
  buffer_length = 64
  buffer_mask   = buffer_length - 1


OBJ
  fmt: "Format"


DAT
  cog         long  0               'cog flag/id

  rx_head     long  0               '9 contiguous longs
  rx_tail     long  0
  tx_head     long  0
  tx_tail     long  0
  rx_pin      long  0
  tx_pin      long  0
  rxtx_mode   long  0
  bit_ticks   long  0
  buffer_ptr  long  0

  'Set these buffers to the buffer_length constant in bytes.
  'longs are used as a shortcut - 1 long == 4 bytes.
  rx_buffer   long  0, 0, 0, 0, 0, 0, 0, 0      '32 bytes
              long  0, 0, 0, 0, 0, 0, 0, 0      '64 bytes
  tx_buffer   long  0, 0, 0, 0, 0, 0, 0, 0      '32 bytes
              long  0, 0, 0, 0, 0, 0, 0, 0      '64 bytes

  lockCOG     byte  255                         'cogid of cog that locked
  semID       byte  0                           'lock to allow multiple COGs to use the serial driver

  printfbuf   byte  0[64]                       'buffer for printf method


PUB start(rxpin, txpin, mode, baudrate, semaphore) : okay
{{
  Must only be called from main program
  Start serial driver - starts a cog
  returns false if no cog available

  mode bit 0 = invert rx
  mode bit 1 = invert tx
  mode bit 2 = open-drain/source tx
  mode bit 3 = ignore tx echo on rx
}}
  stop
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  semID := semaphore
  okay := cog := cognew(@entry, @rx_head) + 1


PUB stop
{{
  Must only be called from main program
  Stop serial driver - frees a cog
}}
  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 9)


PUB rxflush
{{
  Flush receive buffer
}}
  repeat while rxcheck => 0


PUB rxcheck : rxbyte
{{
  Check if byte received (never waits)
  returns -1 if no byte received, $00..$FF if byte
}}
  rxbyte--
  if rx_tail <> rx_head
    rxbyte := byte[@rx_buffer][rx_tail]
    rx_tail := (rx_tail + 1) & buffer_mask


PUB rxtime(ms) : rxbyte | t
{{
  Wait ms milliseconds for a byte to be received
  returns -1 if no byte received, $00..$FF if byte
}}
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms


PUB rx : rxbyte
{{
  Receive byte (may wait for byte)
  returns $00..$FF
}}
  repeat while (rxbyte := rxcheck) < 0


PRI tx(txbyte)
{{
  Send byte (may wait for room in buffer)
}}
  'Wait till there's space in the Tx buffer
  repeat until (tx_tail <> (tx_head + 1) & buffer_mask)
  byte[@tx_buffer][tx_head] := txbyte
  tx_head := (tx_head + 1) & buffer_mask
  if rxtx_mode & %1000
    rx


PRI str(stringptr)
{{
  Send string
}}
  repeat strsize(stringptr)
    tx(byte[stringptr++])


PUB cprintf(format,arg,more)
{{
  Send formatted string from COG
  For format specifiers, see Format object
}}
  if lockCOG <> cogid
    repeat until not lockset(semID)
    fmt.sprintf(@printfbuf,string("[COG%1d]:"),cogid)
    str(@printfbuf)
  lockCOG := cogid  'remember the cog that locked so [COGx] is not printed again for a compound message
  fmt.sprintf(@printfbuf,format,arg)
  str(@printfbuf)
  if !more
    lockCOG := 255
    lockclr(semID)


PUB GetNumber : value | base, digit, cmd, negative
{{
  Get a number from the serial port. The number may start with a "-" if its
  negative. This may be followed by digits for a decimal number, "%" then
  0..1's for a binary number and "$" then digits or "A".."F" (or "a".."f")
  for a hexidecimal number. The first illegal character terminates number
  entry.
}}
  negative := 1
  value := 0
  base := 10
  cmd := rx
  if cmd == "-"
    negative := -1
    cmd := rx
  if cmd == "%"
    base := 2
  elseif cmd == "$"
    base := 16
  else
    value := lookdown(cmd : "0".."9") - 1
  if value < 0
    abort
  repeat
    cmd := rx
    if base == 10
      digit := lookdown(cmd : "0".."9") - 1
    elseif base == 2
      digit := lookdown(cmd : "0".."1") - 1
    elseif base == 16
      digit := lookdown(cmd : "0".."9", "A".."F", "a".."f") - 1
    if digit => 16              'Compensate for the lower case letters
      digit -= 6
    if digit < 0                'All done?
      return value * negative
    value := value * base + digit


DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get buffer_ptr ...
                        rdlong  rxbuff,t1             '... for the receiver
                        mov     txbuff,rxbuff         '... and the transmitter
                        add     txbuff,#buffer_length

                        test    rxtxmode,#%100  wz    'if_nz = open drain Tx
                        test    rxtxmode,#%010  wc    'if_c = inverted output
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     rxcode,#0             'for Gear debugger
                        mov     txcode,#transmit      'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode         'run a chunk of transmit code, then return

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1              'half a bit tick
                        add     rxcnt,cnt             '+ the current clock

:bit                    add     rxcnt,bitticks        'ready for the middle of the bit period

:wait                   jmpret  rxcode,txcode         'run a chuck of transmit code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin into carry
                        rcr     rxdata,#1             'shift carry into receiver
                        djnz    rxbits,#:bit          'go get another bit till done

                        test    rxtxmode,#%001  wz    'find out if rx is inverted
        if_z_ne_c       jmp     #receive              'abort if no stop bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
        if_nz           xor     rxdata,#$FF           'if rx inverted, invert byte

                        rdlong  t2,par                'rx_head
                        add     t2,rxbuff             'plus the buffer offset
                        wrbyte  rxdata,t2             'write the byte
                        sub     t2,rxbuff
                        add     t2,#1                 'update rx_head
                        and     t2,#buffer_mask
                        wrlong  t2,par                'and save

                        jmp     #receive              'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode         'run a chunk of receive code, then return

                        mov     t1,par                'check for head <> tail
                        add     t1,#2 << 2            'tx_head
                        rdlong  t2,t1
                        add     t1,#1 << 2            'tx_tail
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff             'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#buffer_mask
                        wrlong  t3,t1

                        or      txdata,#$100          'or in a stop bit
                        shl     txdata,#2
                        or      txdata,#1             'or in a idle line state and a start bit
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   jmpret  txcode,rxcode         'run a chunk of receive code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1
