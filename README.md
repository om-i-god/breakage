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
| **ambient** | soft long 808, small cymbal, ride and shaker, wood and piano plinks, lots of reverb | halftime, four, broken dub |
| **rave** | driven hardcore boom kick, 909 snare, crisp hats, cowbell and squelch | rave, break, four |
| **jungle** | deep sub, a bright tuned jungle snare, rides, bongos and claves | jungle, break |
| **industrial** | clanging metal kick, ring-mod metal snare, crushed hats, struck pipes | halftime, break, four |
| **acoustic** | a solenoid-struck acoustic kit: felt kick, wired snare, cymbal, log drum, prepared piano, pipes | broken, halftime, break, jungle |
| **minipops** | a 70s preset rhythm box: round soft kick, dull snare, hissy cymbal, claves, guiro, bongos, congas, tambourine | bossa, rhumba, cha-cha, samba, beguine, rock |
| **techno** | 909 kick, rimshots in a 3-3-2, crisp hats, ride, claves and pipes | minimal, four |
| **dubstep** | a long sub kick, a huge layered snare on 3, wobble bass stabs | halfstep, halftime |
| **breakcore** | a distorted gabber kick under a rattling bright break snare, error ticks | breakcore, break, jungle |
| **glitch** | clicks and cuts: a sine-pop kick, one-bit snare, sine-click hats, music box, squeaks, digital errors | glitch, broken |
| **toy** | a toy drum machine: plastic kick, rattly snare, music box, squeaks | march, rock, four |
| **boombap** | a dusty saturated kick, crunchy lo-fi snare, dull hats, vinyl crackle and pops, heavy swing | boombap, broken |
| **tribal** | a big frame drum, hand slaps, talking drum, logs, congas, shakers and toms | tribal, halftime |
| **garage** | knock kick, 909 snare, rimshots, shaker, heavily shuffled hats | garage, broken |
| **footwork** | short 808s in threes, claps, rapid toms, vox chops | footwork, break |
| **trap** | a long tuned 808 that sags as it rings, claps on 3, hat rolls, cowbell | trap |
| **disco** | a live-feel kit: tight kick, fat snare, sizzling open hats, tambourine, congas | disco, four |
| **motorik** | 80s electronic drums (sweeping kick, snare and syntoms) on a steady krautrock beat | motorik, four |

grooves: **four** (four on the floor, offbeat hats), **dub** (kick on 1 with syncopation, rim on the off-beats), **acid** (four with running accented 16ths), **electro** (syncopated kick, snare on 2 and 4), **broken** (2-step / broken beat with ghost snares), **break** (a breakbeat skeleton), **jungle** (a rolling break: sparse kick, snare on 2 and 4 with ghosts between, running 16ths), **halftime** (kick on 1, snare on 3, slow hats), **rave** (four on the floor under a breakbeat snare). the rhythm-box presets write their hand percussion too: **bossa** (clave on the rim, congas), **rhumba** (son clave, conga tumbao), **cha-cha** (guiro on the downbeats, cowbell, the cha-cha-cha on the rim), **samba** (surdo kick on every beat, running tambourine), **beguine** (a lilting kick, bongos) and **rock** (the slow-rock preset). chaos scatters the preset percussion into the kit's own phasing lanes. and the rest: **minimal** (four with a 3-3-2 rim), **halfstep** (kick on 1 and a push, snare on 3), **breakcore** (kicks everywhere under the amen), **glitch** (euclidean scatters, new each phrase), **march** (oom-pah with a music box), **boombap** (swung, crackle on the one), **tribal** (talking drum, logs and congas written out), **garage** (2-step), **footwork** (kicks in threes, vox chops), **trap** (the snare on 3 and written hat rolls), **disco** (open hats on the offbeats, tambourine 16ths), **motorik** (straight 8ths, syntoms into the bar). as chaos rises past the middle, any kit leans toward the break skeleton.

**groove** (PARAMS, or the groove page) forces one of these on any kit: drill snares on a bossa, the minipops box playing jungle. **kit** gives the choice back to the kit.

**voices.** each kit picks a model for every voice, and **SOUND** can swap any of them for another kit's, on any kit: kick (sub, 909, 808, knock, gabber, rave, acoustic, metal, minipops, dubstep, click, toy, dusty, tribal, 808 long, simmons), snare (909, drill, 808, noise, acoustic, jungle, metal, minipops, dubstep, click, toy, dusty, frame, disco, simmons), hats (analog, metallic, crisp, acoustic, lofi, minipops, dusty, click, disco), perc (conga, bongo, cowbell, clave, acid, metal, log, plink, guiro, tambourine, music box, squeak, talking drum, wobble, crackle, vox, syntom) and glitch ticks (click, blip, crush, ring, chirp, zap, error, pop). set a model back to **kit** to follow the kit again.

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
- any: **pops** (a rhythm box fill-in of clave, guiro, bongo and conga; the presets love it), **cascade** (a run down through the kit's own percussion)

**micro-edits.** with chaos up, most bars get one beat reworked: **repeat** (the beat replays the one before), **shuffle** (its four 16ths reordered), **skip** (silent but the kick), **roll**, or the glitch insert on that beat (**stutter**, **reverse**, **tape stop**).

**the break.** load any loop in **BREAK > break file**. breakage works out how many beats it is (or set it), plays it in time at the norns tempo (varispeed: a faster tempo pitches it up, like a jungle break), and cuts it into 16ths. at zero chaos it plays straight; with chaos the slice map swaps, repeats, reverses and repitches slices, and ratchets them. **break** sets how it sits: **with the kit**, **replaces snare + hats**, **replaces the kit**, or off.

**dub.** a tempo-synced ping-pong tape echo takes the rims, snares, claps, toms, perc, ticks and the break, more of each as **dub** rises; some 8-bar edges throw it. a reverb sits behind everything; the kick stays dry.

---

## with gradient

1. put both norns on the same clock: **SYSTEM > CLOCK**, source **link** on both (same network), or MIDI clock from one to the other.
2. on gradient: **PARAMS > CC OUT**, pick the MIDI device that reaches the breakage norns, channel 16, and set **energy cc 20, dub cc 21, phrase pulse cc 23, kickless cc 24, key root cc 25, mode cc 26, chord root cc 27**. for a shared start, also set **SYNC OUT** to the same device.
3. on breakage: **PARAMS > FOLLOW > midi in from**, pick that device. the defaults match the numbers above.
4. turn gradient's own drums down (**GRADIENT > kick / hats / clap / perc → never**, or the LEVELS) so breakage carries them, or keep gradient's kick and pump and let breakage play above them.

while gradient's CCs arrive, the screen shows `<> gradient`: breakage plays at gradient's energy, goes kickless when gradient does, takes its dub amount for the drum echo, and lines its phrases up with gradient's, so fills land on gradient's phrase edges (the phrase length is learned from the pulses). **start / stop** follow gradient's SYNC OUT. if gradient goes quiet for four bars, breakage carries on solo from where the energy was, without a jump.

**in gradient's key.** with **follow its key** on (FOLLOW), gradient's key and mode land in breakage's own **SOUND > key** and **scale**, and every pitched drum plays in them: the kick moves to the nearest root, snares and rims to the nearest 5th, cowbell and clave to a key note near their own pitch, and toms, congas, bongos, logs, pipes, plinks and glitch ticks are snapped into the scale. on **key + chords** the toms, perc and ticks centre on gradient's current chord root, so the drum runs move with its changes. when gradient modulates, the drums go with it on the next bar; when it goes quiet they stay in the last key. **SOUND > tune drums to key** off keeps the kits' own kick and snare tuning. without the key ccs, **root from notes on** (FOLLOW) takes the key from notes arriving on a channel (e.g. gradient's bass out), or set **key** and **scale** by hand.

the key ccs need gradient with the `breakage-key` changes (CC OUT > key root / mode / chord root cc).

the kickless CC and the every-bar CCs need gradient with the `breakage-follow` changes.

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
| **hold K1** + E1 / E2 / E3 | visual theme / page / view |
| **hold K1** + K3 / K2 | mutate / strip (down to the break, perc and glitch ticks; again to bring the kit back) |

| page | E1 | E2 | E3 |
|---|---|---|---|
| play | energy | **chaos** | dub |
| sound | kick tune | kick decay | snare tune |
| voices | kick model | snare model | hat model |
| groove | groove | perc model | glitch tick model |
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
| 4 | kits, 15 to a page (key 16 flips to the next page; the page follows the kit). a pending kit blinks |
| 5 | parts `K S C H R P T G B`: brightness = how loud; press to mute |
| 6 | break pads: the 16 slices under the current bar; press to fire one |
| 7 | the bar's 16ths with the playhead; the micro-edit's beat lit |
| 8 | 1 drop · 2 fill · 3 mutate · 4 strip · 5 throw · 7 break down · 8 build · 10 stutter · 11 tape stop · 12 reverse · 16 play / stop |

## screen

each kit has its own picture with two views (**VISUALS > view**, or hold K1 + E3), drawn from the drums as they hit:

| kit | view one | view two |
|---|---|---|
| **dub** | a sound-system yard at night: stacks breathing on the kick, every rim and snare dropping rings on the floor that echo back fainter at the echo time | inside a tape echo: hits written onto a loop of tape, coming back round the playback heads, the spring tank twanging |
| **house** | a club at full tilt: moving heads sweeping through haze, a mirror ball, the crowd dropping on the kick, blinders on the claps | a drum machine's front panel: the pattern on a 16-step grid, pads lighting per voice |
| **acid** | a phosphor scope: a resonant wave squelching with the acid perc, cutoff opening with energy | the bass box from above: step lamps, the keys lighting, glides arcing between them |
| **analord** | a rack of gear: VU needles with real ballistics, a lamp row, patch cables swinging | a modular wall: little scopes drawing each voice's wave, a sequencer lamp running |
| **syro** | a machine readout: every voice a lane of scrolling history, ratchets as bursts, readouts that flicker with what changes | a radar: each voice a ring, hits marked where they fall in the bar, the sweep arm the playhead |
| **broken** | a pane of glass over a night city, cracking on the snares and healing on phrase edges | a shattered mirror, its shards knocked about on the snares |
| **drill** | a bit boring down through layers of rock, winding up with the ratchets | a spinning wireframe solid that blows apart on ratchets and springs back |
| **gabber** | presses slamming on the kick, sparks, steam, a gauge in the red | a speaker cone up close, the wave squaring off on the kick |
| **ambient** | still water at dusk: the sun swelling on the kick, rings where the snare drops | aurora curtains over a ridge and a lake |
| **rave** | a warehouse: laser fans out of the booth, the crowd's hands up on the snares | a tunnel of spinning wireframe polygons |
| **jungle** | a tower block in the rain, the pirate aerial pulsing on the snares, windows climbing with the break | a canopy at night: vines, rain, fireflies flashing with the break slices |
| **industrial** | a concrete corridor of fluorescent tubes browning out on the kick, a CRT of static at the end | grinding gears advancing a tooth a step, sparks on the snares |
| **acoustic** | a robot drum rig: solenoid arms striking each drum, buzzing on ratchets | inside a grand piano: strings ringing, bolts on some, hammers striking |
| **minipops** | the rhythm box: the playing preset's button lit, voice lamps glowing, the grille breathing | a 70s living room: the organ with the box on top, a lava lamp, the TV glowing |
| **techno** | a motorway at night: cats' eyes on the 16ths, rimshots flashing the lanes, the kick surging the road | a city from high above: signals sweeping the grid, light trails on the hats |
| **dubstep** | a storm drain: the sub rippling black water, the snare lighting the tunnel and echoing down it, wobbles pulsing the far glow | a storm over the city: lightning on the snare, thunder on the kick, rain on the hats |
| **breakcore** | a wall of CRTs flipping channels on every hit, cracking and blacking out with chaos | a tower of blocks knocked apart by the snares and rebuilt on phrase edges |
| **glitch** | a circuit board: pulses racing down traces to each voice's chip, errors corrupting them | a datamoshed picture smearing and healing |
| **toy** | an open music box: pins plucking the comb, a dancer turning, winding down when kickless | a shelf of wind-up toys: drummer soldier, cymbal monkey, a spinning top, a little train |
| **boombap** | a turntable from above: crackle as dust in the grooves, the needle skipping with chaos | a bedroom studio: sampler pads lighting, a head nodding to the kick, rain on the window |
| **tribal** | a bonfire: dancers circling, drummers striking, sparks on the hits | a stone circle under the stars, each stone lit by its voice |
| **garage** | the top deck of a night bus: shopfronts streaming past, rain flaring on the snares | a car dashboard: the stereo's EQ dancing, wipers on the snares |
| **footwork** | a battle circle from above: footprints glowing on the kicks, spins on the toms, the crowd hyped by vox chops | sneakers in close-up, stomping and leaving light on the floor |
| **trap** | a car park under a sodium lamp: the 808 squatting the car and rippling the puddles, hat rolls running the chrome | a skyline: hat rolls racing along lit windows, searchlights on the snares |
| **disco** | a light-up floor: a pattern per voice, a mirror ball, dancers lit from below | colour-wheel beams over a glitter curtain, a string section swelling |
| **motorik** | an autobahn toward a banded sun: lane marks on the beat, pylons lighting on the syntoms | four mannequins at their consoles, one per voice |

every picture also moves with the sound itself: the engine reports its overall level, lows, mids and highs, and each theme gives each of those its own job (in dub the lows breathe the cones, the mids open the horn mouths and the floor rings, the highs glint in the fog), so the screen moves between the hits too. **audio reactivity** (VISUALS, 0–10) sets how hard: 0 runs the pictures on the drum events alone, 10 doubles it. ratchets read as repeats, chaos fractures and multiplies the picture, energy fills it, kickless stretches change the light, and the glitch insert tears it. **VISUALS > theme** follows the kit or stays fixed; **kick shake** jolts the picture on the kick.

top left: the kit (and the one coming). top right: `<> gradient` (with the key or chord root the drums are centred on) or the solo section, phrase position, `~` when kickless, `half` in a halftime bar. bottom: energy (`e`) and chaos (`x`) bars and the part lights.

---

## params

- **BREAKAGE:** kit, groove (kit or any groove), chaos, play mode (set / track / hold), phrase length, track length, track end, kit changes, kit sets dub/swing/drive, fills, kick (auto / always / never), hats (auto / always / never), glitch (off / on), freeze material, seed, rebuild from seed, new random material
- **FOLLOW:** follow gradient (auto / off), midi in from, cc channel, energy / dub / phrase pulse / kickless cc, follow its key (off / key / key + chords), key root / mode / chord root cc, follow its dub, follow start/stop, root from notes on
- **BREAK:** break file, break (off / with the kit / replaces snare + hats / replaces the kit), break length (auto, 2–32 beats), break pitch
- **MIX:** dub, echo time, swing, chaos crush, reverb send, drive, reverb size, echo wow, level, glitch depth
- **LEVELS:** kick, snare, clap, rim, hat, ride, perc, tom, tick, break
- **SOUND:** kick tune, kick decay, snare tune, hat tone, key, scale (gradient's twelve modes), tune drums to key, kick / snare / hat / perc / glitch tick model (kit or any model), snare decay, open hat decay, perc decay
- **VISUALS:** theme (follows the kit / fixed), fixed theme, overlay, speed, brightness, view (one / two), kick shake (off / soft / hard), audio reactivity (0–10)

## install

copy the folder to `~/dust/code/breakage/`. it ships its own engine (`lib/Engine_Breakage.sc`), so after the first install, and after any update that changes the engine, run **SYSTEM > RESTART** before loading the script. copy without `test/` (`rsync -a --exclude test`).

## dev

- `lua test/sim.lua [bars]` runs the script headless against stubbed norns APIs: every kit at three chaos levels, the break, fills, following a fake gradient (energy, phrase pulses, kickless, going quiet, start/stop), every control and grid key, track mode, and every theme. engine calls are checked against the command formats and tweak keys in the engine source. `V=1` logs the arc.
- `lua test/unit.lua test/unit_engine.lua test/unit_visuals.lua` checks the engine source for norns-only maths traps and runs every theme through silence, peaks, kickless and ratchet storms.
- `test/sc/run.sh [test/sc/sound.scd]` compiles the engine against a stub, plays every voice and prints each one's peak.

## license

MIT
