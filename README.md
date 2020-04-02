# Pedalboard
A simple collection of chainable effects for the Norns sound computer.

## Pedals
Compressor/Overdrive
Reverb
Chorus/Flanger .../Phaser?
Distortion/Bitcrusher
Delay (ping pong mode, etc) (hold K2 and tap k3 for tap tempo)
Tremelo
EQ?
Tuner?

## UI & Controls
E1 always changes page

### Page 1: Board
Left-to-right list of slots for pedals
E2 changes focused slot
E3 changes pedal in focused slot (including "no pedal")
E3 doesnt take effect til K3 confirms
Last slot is always "add new" (using K3 to confirm)
K2 jumps to pedal page
K2 + E2 re-orders pedals
K2 + E3 changes wet/dry for focused pedal
K2 + K3 toggles bypass for focused pedal

### Page N: Pedal
UI is dual-dials widget from the UI demo (controlled by E2 & E3)
K2 cycles left thru knob pairs, looping at the left edge
K3 cycles right thru knob pairs, looping at the right edge
Each pedal has knobs specific to its effect
Every pedal has the following knobs as its last 4:
Bypass (as a knob -- any left motion toggles off, any right motion toggles on)
Wet/dry
In gain
Out gain

#### A System of Simple and Fine Control
Pedal name at top
Then simple set of knobs
For fine control: extra stuff below (when scrolled to, header stays visible, now with horizontal separator)
How do simple & fine interact? Via a "catch up" algorithm
Each simple knob is really a combo of fine settings. If fine settings don't line up with where knob says it is, then they move by more than the knob moves until they catch up (and thereafter behave normally)

## Notes:
Look at some other apps to seed FX code via SC engines

Also look at actual pedals:
* Strymon BigSky Reverb
* Ibanez TS9 Tubescreamer
* BOSS DS-1 Distortion
* Electro-Harmonix Big Muff Pi Fuzz
* Electro-Harmonix Memory Boy Delay
* BOSS CE-2W Chorus
* Fender Tre-Verb Tremolo
