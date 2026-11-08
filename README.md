# breakage

a drummer for norns. dub techno and analog house up to drill'n'bass, from one script: its own synthesized kit, an optional breakbeat chopper, and a conductor that plays whole sets by itself. run it on a second norns beside [gradient](https://github.com/om-i-god/gradient) and it locks to gradient's clock and follows its arc; on its own it runs its own arc.

---

## how it plays

**two axes.**
- **energy** (0 to 1): how much plays and how hard. parts enter as it rises (hats, perc, kick, ticks, snare, toms, break, shaker, clap, ride) and leave as it falls, each fading over about two bars, with the entry points jittered every phrase. the conductor owns it: its own arc when solo, gradient's when following. E1 nudges it, and the nudge relaxes back over about 16 bars.
- **chaos** (0 to 1): how far toward drill'n'bass. **chaos is yours alone; the conductor never moves it.** at the bottom you get steady four-on-the-floor or broken dub with swing and space. in the middle, ghost kicks and snares, displaced kicks, odd-length perc lanes and the occasional roll. at the top, ratchets up to 16 hits inside a 16th with rising pitch, a rearranged break, a micro-edit in most bars, halftime flips, a crushed bus and less swing. low energy with high chaos is sparse but twitchy: few hits, and those few stutter.

**kits.** a kit is a sound palette, the grooves it likes, its own dub / swing / drive, and its own picture on the screen. any kit can be pushed to full chaos and keeps its sounds on the way.

| kit | sound | grooves |
|---|---|---|
| **dub** | deep sub kick, rimshots into the echo, soft analog hats, congas | broken dub, four |
| **house** | 909 kick and clap, open hats, cowbell | four |
| **acid** | 909 kick, crisp hats, resonant squelch perc | acid, four |
| **analord** | 808 kick and snare, metallic hats | electro, broken |
| **syro** | short knock kick, analog snare, bongos, ticks | broken, electro |
| **broken** | dusty kick, 909 snare, shaker, wood | broken, break |
| **drill** | knock kick, tight pitched drill snare, crushed ticks | break |
| **gabber** | distorted gabber kick, noise snare, ring-mod ticks | four, break |

grooves: **four** (four on the floor, offbeat hats), **dub** (kick on 1 with syncopation, rim on the off-beats), **acid** (four with running accented 16ths), **electro** (syncopated kick, snare on 2 and 4), **broken** (2-step / broken beat with ghost snares), **break** (a breakbeat skeleton). as chaos rises past the middle, any kit leans toward the break skeleton.

kit changes land on the next bar with new material. **kit changes** (PARAMS) set to **on phrases** lets the conductor switch kits now and then; **kit sets dub/swing/drive** moves those three to the kit's home on each change.

**the arc (solo).** three play modes:
- **set (endless):** energy swells and drains over a long cycle with a random walk on top; the troughs are kickless drifts.
- **track:** intro, build, peak, breakdown (kickless), return, outro over the track length, then stop or roll on.
- **hold:** energy stays where you put it (E1 sets it directly).

**phrases and mutation.** a phrase (8, 16, 32 or 64 bars) holds the material; on each phrase edge the groove is kept, partly swapped, or rebuilt. **freeze material** stops that.

**fills.** the bar before a phrase edge almost always gets one, some 8-bar edges get a small one, and **K3** fires one on the next beat. the kind follows chaos:
- low: **toms** (a run down in key), **throw** (the echo thrown), **gap** (drums out for the last beat or two), **open** (open hats), **dip** (a filter dip)
- mid: **roll** (a snare roll that tightens and rises), **stutter**, **break roll** (a break slice rolled)
- high: **drill** (two beats of accelerating snare ratchets climbing in pitch), **reverse**, **tape stop**

**micro-edits.** with chaos up, most bars get one beat reworked: **repeat** (the beat replays the one before), **shuffle** (its four 16ths reordered), **skip** (silent but the kick), **roll**, or the glitch insert on that beat (**stutter**, **reverse**, **tape stop**).

**the break.** load any loop in **BREAK > break file**. breakage works out how many beats it is (or set it), plays it in time at the norns tempo (varispeed: a faster tempo pitches it up, like a jungle break), and cuts it into 16ths. at zero chaos it plays straight; with chaos the slice map swaps, repeats, reverses and repitches slices, and ratchets them. **break** sets how it sits: **with the kit**, **replaces snare + hats**, **replaces the kit**, or off.

**dub.** a tempo-synced ping-pong tape echo takes the rims, snares, claps, toms, perc, ticks and the break, more of each as **dub** rises; some 8-bar edges throw it. a reverb sits behind everything; the kick stays dry.

---

## with gradient

1. put both norns on the same clock: **SYSTEM > CLOCK**, source **link** on both (same network), or MIDI clock from one to the other.
2. on gradient: **PARAMS > CC OUT**, pick the MIDI device that reaches the breakage norns, channel 16, and set **energy cc 20, dub cc 21, phrase pulse cc 23, kickless cc 24**. for a shared start, also set **SYNC OUT** to the same device.
3. on breakage: **PARAMS > FOLLOW > midi in from**, pick that device. the defaults match the numbers above.
4. turn gradient's own drums down (**GRADIENT > kick / hats / clap / perc → never**, or the LEVELS) so breakage carries them, or keep gradient's kick and pump and let breakage play above them.

while gradient's CCs arrive, the screen shows `<> gradient`: breakage plays at gradient's energy, goes kickless when gradient does, takes its dub amount for the drum echo, and lines its phrases up with gradient's, so fills land on gradient's phrase edges (the phrase length is learned from the pulses). **start / stop** follow gradient's SYNC OUT. if gradient goes quiet for four bars, breakage carries on solo from where the energy was, without a jump.

**root from notes on** (FOLLOW) tunes the toms and perc to the notes arriving on a channel, e.g. gradient's bass out on channel 1; otherwise **SOUND > toms + perc key** sets it.

the kickless CC and the every-bar phrase pulse need gradient from `breakage-follow` onward.

---

## controls

| input | action |
|---|---|
| **E1 / E2 / E3** | the current page |
| **K2 tap** | drop: kick and hats out for the rest of this 8 bars and the next. tap again to bring them back |
| **K3 tap** | fill on the next beat |
| **K2 + K3** | play / stop (starts on the next bar) |
| **hold K2** + E2 / E3 | kit / fills (normal, busy, off) |
| **hold K3** + E2 / E3 | tempo / play mode |
| **hold K1** + E1 / E2 | visual theme / page |
| **hold K1** + K3 / K2 | mutate / strip (down to the break, perc and glitch ticks; again to bring the kit back) |

| page | E1 | E2 | E3 |
|---|---|---|---|
| play | energy | **chaos** | dub |
| sound | kick tune | kick decay | snare tune |
| space | swing | reverb send | chaos crush |
| break | break level | break pitch | break length |
| parts | energy | pick a part | its level; K2 mutes, K3 solos |

parts: `K S C H R P T G B` = kick, snare (and rim), clap, hats (and shaker), ride, perc, toms, glitch ticks, break.

every action is also a trigger in **PARAMS > PERFORM** for MIDI mapping: play, drop, fill, mutate, strip, throw, build, break down, stutter, tape stop, reverse, chop, next / prev kit.

## grid

| row | |
|---|---|
| 1 | phrase position; the last key lights when a fill is coming |
| 2 | energy: press to pull it there |
| 3 | chaos: press to set it |
| 4 | kits 1–8 (a pending kit blinks) |
| 5 | parts `K S C H R P T G B`: brightness = how loud; press to mute |
| 6 | break pads: the 16 slices under the current bar; press to fire one |
| 7 | the bar's 16ths with the playhead; the micro-edit's beat lit |
| 8 | 1 drop · 2 fill · 3 mutate · 4 strip · 5 throw · 7 break down · 8 build · 10 stutter · 11 tape stop · 12 reverse · 16 play / stop |

## screen

each kit has its own picture, drawn from the drums as they hit: **dub** a fogged sound-system yard with echo rings, **house** a warehouse floor rolling toward you, **acid** a resonant oscilloscope trace, **analord** VU needles and swinging patch cables, **syro** a scrolling dot-matrix of every voice, **broken** a pane that cracks on the snares, **drill** a spinning bit that winds up with the ratchets, **gabber** presses slamming on the kick. ratchets read as repeats, chaos fractures the picture, and the glitch insert tears it. **VISUALS > theme** follows the kit or stays fixed.

top left: the kit (and the one coming). top right: `<> gradient` or the solo section, phrase position, `~` when kickless, `half` in a halftime bar. bottom: energy (`e`) and chaos (`x`) bars and the part lights.

---

## params

- **BREAKAGE:** kit, chaos, play mode (set / track / hold), phrase length, track length, track end, kit changes, kit sets dub/swing/drive, fills, kick (auto / always / never), hats (auto / always / never), glitch (off / on), freeze material, seed, rebuild from seed, new random material
- **FOLLOW:** follow gradient (auto / off), midi in from, cc channel, energy / dub / phrase pulse / kickless cc, follow its dub, follow start/stop, root from notes on
- **BREAK:** break file, break (off / with the kit / replaces snare + hats / replaces the kit), break length (auto, 2–32 beats), break pitch
- **MIX:** dub, echo time, swing, chaos crush, reverb send, drive, reverb size, echo wow, level, glitch depth
- **LEVELS:** kick, snare, clap, rim, hat, ride, perc, tom, tick, break
- **SOUND:** kick tune, kick decay, snare tune, hat tone, toms + perc key
- **VISUALS:** theme (follows the kit / fixed), fixed theme, overlay, speed, brightness

## install

copy the folder to `~/dust/code/breakage/`. it ships its own engine (`lib/Engine_Breakage.sc`), so after the first install, and after any update that changes the engine, run **SYSTEM > RESTART** before loading the script. copy without `test/` (`rsync -a --exclude test`).

## dev

- `lua test/sim.lua [bars]` runs the script headless against stubbed norns APIs: every kit at three chaos levels, the break, fills, following a fake gradient (energy, phrase pulses, kickless, going quiet, start/stop), every control and grid key, track mode, and every theme. engine calls are checked against the command formats and tweak keys in the engine source. `V=1` logs the arc.
- `lua test/unit.lua test/unit_engine.lua test/unit_visuals.lua` checks the engine source for norns-only maths traps and runs every theme through silence, peaks, kickless and ratchet storms.
- `test/sc/run.sh [test/sc/sound.scd]` compiles the engine against a stub, plays every voice and prints each one's peak.

## license

MIT
