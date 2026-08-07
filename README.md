# bytes

Small random/miscellaneous things I've done.

This repo is used on my personal site at https://barrettotte.github.io/bytes/

## Maintenance

| Command | Description |
| --- | --- |
| `make sync` | Install Python dependencies with uv |
| `make generate` | Regenerate all README indexes |
| `make check` | Validate metadata and check for stale indexes |
| `make hooks` | Install pre-commit hook |
| `make models` | Generate missing or stale GLBs from STL sources |
| `make models-check` | Validate generated GLBs |

STLs are the editable sources. Opt an item into web GLB generation with `models: true` or a `models.include`/`models.exclude` mapping in its README frontmatter; the pre-commit hook mirrors configured models under `web-models/`.

## Items

<!-- bytes:index:start -->
| Item | Date | Description |
| --- | --- | --- |
| [Desk Extender](./3d-printing/desk-extender/) | 2026-08-04 | A simple desk extender to fill the gap between furniture. |
| [AC Redirect](./3d-printing/ac-redirect/) | 2026-08-02 | Redirecting my AC unit exhaust at a different angle so I can keep a cat bed on my window sill. |
| [Bed Remote Holder](./3d-printing/bed-remote-holder/) | 2025-07-20 | Holds two remotes on my bed frame |
| [CNC Controller Holder](./3d-printing/cnc-designs/cnc-controller-holder/) | 2024-03-04 | A mount for my CNC router's controller |
| [Laptop Holder](./3d-printing/desk-designs/mac-holder/) | 2024-01-30 | A laptop holder under my monitor risers |
| [Whiteboard Holder v2](./3d-printing/desk-designs/whiteboard-holder-v2/) | 2024-01-25 | Whiteboard holder for my monitor riser |
| [Vtuber Joke](./misc/vtuber/) | 2024-01-05 | Simple vtuber as a joke |
| [Zenith 1980](./electronics/tv/zenith-1980/) | 2023-12-31 | 1980 Zenith AC/DC black and white TV stuff |
| [Sony Trinitron](./electronics/tv/sony-trinitron/) | 2023-12-23 | Sony Trinitron stuff |
| [TV Foot CRT](./3d-printing/tv-foot-crt/) | 2023-12-22 | Some new feet for my TV that I put on top of an old CRT |
| [Leyden Jar](./electronics/leyden-jar/) | 2023-11-16 | Two Leyden jars |
| [Electrophorus](./electronics/electrophorus/) | 2023-11-09 | Basic electrophorus |
| [USB Microscope Stand](./3d-printing/usb-microscope-stand/) | 2023-10-31 | A new stand for my USB microscope |
| [Desk Small Tray](./3d-printing/desk-designs/small-tray/) | 2023-09-29 | Small tray for holding small components on desk |
| [Flip 5 Stand](./3d-printing/desk-designs/flip-5-stand/) | 2023-09-20 | A phone stand for my Samsung Galaxy Z Flip5 |
| [Electroscope](./electronics/electroscope/) | 2023-09-14 | Beer bottle electroscope |
| [Laundry Bin Handle](./3d-printing/laundry-handle/) | 2023-08-22 | Replacement handle for my laundry basket |
| [RTL SDR Cable Support](./3d-printing/rtl-sdr-support/) | 2023-08-20 | Little support thing to hold up the RTL SDR when connected to Nooelec Ham It Up |
| [Part Organizer Dividers](./3d-printing/tray-divider/) | 2023-08-09 | Dividers for my part organizers |
| [Exhaust Duct Support](./3d-printing/resin-designs/duct-holder/) | 2023-08-07 | Duct holder to prevent vent duct from sagging |
| [Elegoo Saturn 2 Exhaust Venting](./3d-printing/resin-designs/saturn-2-venting/) | 2023-08-02 | Venting for my Elegoo Saturn 2 resin printer |
| [Nitrile Glove Holder/Dispenser](./3d-printing/resin-designs/glove-dispenser/) | 2023-08-01 | Nitrile glove holder/dispenser above resin printer |
| [Desk Phone Mount](./3d-printing/desk-designs/desk-phone-mount/) | 2023-07-28 | A mount for my Samsung Note 8 |
| [Monitor Power Brick Holders](./3d-printing/desk-designs/monitor-power-tower/) | 2023-07-13 | Stackable holders to keep monitor power bricks more organized |
| [Server Rack Top Extension](./3d-printing/server-top-holders/) | 2022-10-11 | Holders so I could stack another computer on top of my server rack |
| [Small Whiteboard Holder](./3d-printing/desk-designs/whiteboard-holder-small/) | 2022-09-21 | Small whiteboard holder |
| [Simple Vacuum Tube Amplifier](./electronics/vacuum-tube-amplifier/) | 2022-08-28 | Simple vacuum tube amplifier |
| [Ender 3 Octoprint](./3d-printing/ender3-octoprint/) | 2022-05-26 | My Ender 3 Octoprint setup |
| [Standing Desk Control Cover](./3d-printing/desk-designs/jarvis-controller-cover/) | 2021-10-08 | A cover to prevent accidentally raising my standing desk |
| [DB2 SQL Dynamic Insert JSON](./code/db2-sql-gen-insert/) | 2021-06-15 | Generate a dynamic insert JSON statement for a table in DB2 SQL |
| [DB2 SQL Generate Groovy Object](./code/db2-sql-gen-groovy/) | 2021-06-01 | Generate a POGO (Plain Old Groovy Object) from a table in DB2 SQL |
| [Projectile Motion in Pygame](./code/pygame-projectile/) | 2020-09-07 | Quick and dirty prototype of projectile motion with Pygame |
| [ColdFusion Neural Network](./code/cf-neural-net/) | 2019-10-01 | A neural network experiment implemented in ColdFusion |
| [My First Program (C++)](./code/first-program.cpp) | 2011-09-06 | My first program |
<!-- bytes:index:end -->
