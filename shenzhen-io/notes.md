# notes

Notes on MCxxxx while reading manual.

## Instructions

- `nop` - has no effect
- `mov R/I R` - copy value of first operand into second operand
- `jmp L` - jump to label
- `slp R/I` - sleep for number of time units specified by operand
- `slx P` - sleep until data is available to read on XBus pin in operand
- `add R/I` - add value of first operand to value of `acc` and store in `acc`
- `sub R/I` - subtract value of first operand to value of `acc` and store in `acc`
- `mul R/I` - multiply value of first operand by value of `acc` and store in `acc`
- `not` - if `acc` = 0, set `acc` to 100. Otherwise, `acc` = 0
- `dgt R/I` - isolate specified digit of value in `acc` and store in `acc`
- `dst R/I R/I` - set digit of `acc` specified in first operand to value of second operand
- `teq R/I R/I` - test if value of first operand (A) is equal to value of second operand (B)
- `tgt R/I R/I` - test if value of first operand (A) is greater than value of second operand (B)
- `tlt R/I R/I` - test if value of first operand (A) is less than value of second operand (B)
- `tcp R/I R/I` - compare value of first operand (A) to value of second operand (B)

### Operands

- R - register
- I - integer (-999 to 999)
- R/I - register or integer
- P - pin register
- L - label

## Datasheets

- MC4000 High Performance Microcontroller - pg 18
- MC6000 High Performance Microcontroller - pg 19
- DX300 Digital I/O Expander - pg 20
- 100P-14 Random-Access Memory Pg 22
- 200P-14 Read-Only Memory pg 23
- LC70GXX Simple I/O Logic Gate Family pg 24
- DT2415 Incremental Clock - pg 25
- C2S-RF901 Low Power RF Transceiver - pg 26
- FM/iX FM Blaster Sound Module - pg 27
- N4PB-8000 Push-Button Controller - pg 28
- MC4010 Math Co-Processor - pg 29
- D80C010-F Security Module - pg 30
- KUJI-EK1 Oracle Engine - pg 31
- PGA33X6 - pg 32
- Raven Dynamics NLP2 - pg 33

## Pins

Simple I/O - continuous signal levels from 0 to 100, inclusive. Unmarked.
Used for connecting microcontroller to simple input like button, switch, microphone, or
a simple output like an LED, a speaker, or a motor.

XBus - discrete data packets from -999 to 999, inclusive. XBus pins marked with yellow dot.
Used to transmit data between two microcontrollers or a microcontroller and complex I/O like a keypad or numeric display.

Simple I/O pins can be read or written at any time regardless of connected device state.
XBus is a synchronized protocol. Data only transferred when a reader is attempting to read and a writer is attempting
to write. If read/write is attempted without its partner operation on connected device, then the operation will block.

## Square Wave Generator

```asm
# on for 3, off for 3

mov 100 p1
slp 3
mov 0 p1
slp 3

# p1 generates square wave signal
```

## Language Reference

Program written on one member of MCxxxx family can be re-used on any other MCxxxx microcontroller with
little to no changes.

When in sleep state, consumes no power.

Example of syntax:

```asm
# comment
loop:
    teq acc 10
+   jmp end    ; conditional exec jump
    mov 50 x2
    add 1
    jmp loop
end:
    mov 0 acc
```

`+/-` will cause instruction to be enabled/disabled by preceding test instruction.
If disabled, will be skipped and will not consume power.
Conditional instructions start in disabled state and get enabled by preceding test instruction.

### Registers

Registers vary between MCxxxx models.

- `acc` - primary general purpose register for internal computation.
- `dat` - second register available on only some MCxxxx 

both `acc` and `dat` initialized to 0.

Pin registers `p0,p1,x0,x1,x2,x3` are used when reading from or writing to pins of MCxxxx microcontrollers.

`null` is a pseudo-register, reading from it will produce 0, writing has no effect.
