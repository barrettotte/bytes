# ender3-octoprint

My Ender 3 Octoprint setup.

I made this too long ago and unfortunately didn't document anything.

![lack-tower.jpg](./lack-tower.jpg)

## Block Diagram

![block-diagram.jpg](./block-diagram.jpg)

## Octoprint

https://octoprint.org/download/

### Plugins:

- PSU Control
  - General > GPIO Device = `/dev/gpiochip0`
  - Switching > Switching Method = GPIO, On/Off GPIO Pin = 16
- PSU Control - RPi.GPIO
  - General > GPIO Mode = BOARD
  - Switching > Pin = 16
  - Sensing > Pin = 0

After installing latest Octoprint (1.11.2), I had to install plugin to resolve SD card firmware issues.
Rather than reinstalling my Ender 3's firmware (I'm lazy and hoping I can get a new 3D printer soon), I'm going to do a workaround:
- https://community.octoprint.org/t/octoprint-shows-my-printers-sd-card-as-uninitialized-on-my-creality-printer/35284
- plugin: https://gist.github.com/foosel/9ca02e8a3ea0cb748f4b220981eab12d/raw/convert_TF_SD.py

### GCODE

Add GCODE to execute at end of print

```txt
; Ender 3 Custom End G-code
; From: https://gist.github.com/faparicior/98f7a28c80ac7b6b20ffa771af103c56

G4                           ; Wait
M220 S100                    ; Reset Speed factor override percentage to default (100%)
M221 S100                    ; Reset Extrude factor override percentage to default (100%)
G91                          ; Set coordinates to relative
G1 F1800 E-3                 ; Retract filament 3 mm to prevent oozing
G1 F3000 Z20                 ; Move Z Axis up 20 mm to allow filament ooze freely
G90                          ; Set coordinates to absolute
G1 X0 Y{machine_depth} F1000 ; Move Heat Bed to the front for easy print removal
M106 S0                      ; Turn off cooling fan
M104 S0                      ; Turn off extruder
M140 S0                      ; Turn off bed
M107                         ; Turn off Fan
M84                          ; Disable stepper motors
```

## Lack Enclosure

I used someone's 3D prints to attempt to make a 3 level Ikea lack tower.
I never managed to get plexiglass to finish the enclosure, but its been so long I'm going to keep it as is.

## Bed Level Tests

- https://www.thingiverse.com/thing:4616136/files
