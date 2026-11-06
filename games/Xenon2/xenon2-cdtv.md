# Xenon 2 CDTV: Findings

As of 25.10.2026. Collected while introducing `resload_Audio`
(CD-DA replacement).

## Sources
- Disassembly: `cr:xenon2/cdtv/X2.asm`, also `X2.rs`, `Fix`, `Fix.rs`,
  `killaga` and `Xenon2` (33 byte script)
- Installed game: `wart:x-y/xenon2/`
  - `data-da/Track02.mp3` .. `Track13.mp3`: 12 files, about 95 MB
  - next to it `data-cdtv.lha`
- Addresses: Slave address = disassembly label + $400
  (e.g. Slave `$3a924` = `lbC03A524`)
- The library calls in the disassembly appear only as raw LVOs:
  - -$1BC OpenDevice
  - -$1C8 DoIO
  - -$1CE SendIO
  - -$1D4 CheckIO
  - -$1DA WaitIO
  - -$1E0 AbortIO

## cdtv.device in the game

### Opening (Slave $3aa4a-$3aae8, in `lbC03A612`)
This area is skipped by the Slave via `PL_S`. It does:
- `OpenLibrary("dos.library")`
- `AllocSignal(-1)` and `FindTask(0)`
- builds the MsgPort `lbL03A4BE` manually
- `OpenDevice("cdtv.device",0)` twice:
  - IOReq A `lbL03A45E` for play
  - IOReq B `lbL03A48E` for the volume

### Data
| Label | Meaning |
|---|---|
| `lbL03A4F2` (Slave $3a8f2) | current track; -1 = nothing is playing |
| `lbW03A4F0` | countdown for the loop poll, starts at $32 |

IORequest fields used: $1C io_Command, $24 io_Length, $28 io_Data,
$2C io_Offset.

### Commands used
There are only two. TOC, SUBQ, ISPLAYING, PAUSE, STOPPLAY and FADE are not used.

**Play: `lbC03A524` (Slave $3a924)**
- Input: d0.w = CD track. The routine itself does `and.l #$ffff,d0`.
- Calls the stop routine first.
- Stores the track in `lbL03A4F2`.
- Sends `CDTV_PLAYTRACK` ($2B) via SendIO:
  - io_Offset = track
  - io_Length = track+1, probably the exclusive end (unverified)
  - io_Data = 0

**Stop: `lbC03A4F6` (Slave $3a8f6)**
- `tst.l lbL03A4F2` / `bmi`, then AbortIO and WaitIO on IOReq A.
- Sets `lbL03A4F2` to -1.
- `lbC03A5B4` is just a `bsr` to this routine.

**Volume: `lbC03A5BA` (Slave $3a9ba)**
- `CDTV_MUTE` ($38) via DoIO on IOReq B, with io_Offset = $7FFF and
  io_Length = 2. The meaning of io_Length is unverified.
- Always called directly after play and always with $7FFF.
- The variant with io_Offset = 0 (mute) at disassembly $3a5e8 has no
  label and is never jumped to, so it is dead code.

**Loop: `lbC03A55C` (Slave $3a95c)**
- Called from the level 3 interrupt chain (VBlank) at `lbC034CB8`.
- Every 50 frames it does a `CheckIO` on IOReq A. If the request has
  finished, it sends PLAYTRACK for the same track again.
- As long as `lbL03A4F2` is negative it does nothing.

## Tracks
- CD track = track number on screen + 1, because track 1 is the data
  track.
- Tracks 2-13 are used. They are hardcoded, the TOC is never read.
- The track titles are in `MEGABLASTXENO.MSG`.

| Situation | Call site | Track |
|---|---|---|
| Title / attract (`lbC03B506`) | X2.asm line 80126 | `lbB03EE26[0]`, default 2 |
| After language loading / joypad selection (`lbC03C3D8`) | line 81051 | `lbB03EE26[0]` |
| Game start, level start, after death, next level | lines 79283, 79298, 79621, 79663, 79706 | `lbB03EE26[level]`<br>L1=3, L2=5, L3=2, L4=3, L5=5 |
| Music selection, preview on line change | lines 82710-82717 | table entry, last one in `lbW03394C` |
| Picture sequence (`lbC050506`/`lbC05055C`/`lbC050600`) | lines 101545, 101561 | `lbL05047E[picture]`<br>8,8,9,9,10,10,11,11,12,13,13 |

- **Music selection:** The titles line cycles through tracks 2-13, the level
  lines through 2-7. The wrap-around code is at `lbC03E1C4`-`lbC03E286`.
- **Music on/off:** In the game menu `lbB000602` is toggled (`not.b` at
  `lbC03C7E4`).
  - If the flag is cleared, the level music starts are skipped.
  - When the game starts with music switched off, the game immediately stops
    the track it has just started (at `lbC03A9DA`).

**Where playing is stopped** (always via `lbC03A5B4`, mostly preceded by
`tst.l lbL03A4F2` / `bmi`):
- before each load from `CD0:`: `LEVELn` (line 71530, `lbC03CE60`), `INTRO`
  (line 82502) and `picdata` (`lbC050B32`)
- on initialization (`lbC03A612`), at the top of the main loop (`lbC03A926`)
  and on the player's death (`lbC03ADD2`)
- at the end of the credits scroller (line 80567), in `lbC03BB84` and when
  leaving the music selection (`lbC03E2C4`)

Play and stop are only called from the main program, never from an
interrupt. Only the loop poll comes from the interrupt.

## Implementation in the Slave (xenon2.asm, only IFD CDTV)
- ws_Version 21 (for `resload_Audio`), `ws_MemConfig` added, version 1.8 CDTV.
  The floppy Slave stays at ws_Version 17.
- `PL_P $3a924,_cd_play`:
  - Stores the track in $3a8f2.
  - Calls `resload_Audio(WHDLAUDC_PLAY, track, WHDLAUDF_LOOP)`. PLAY stops
    a playing track itself.
- `PL_P $3a8f6,_cd_stop`:
  - If $3a8f2 is negative, the routine does nothing.
  - Otherwise it calls `resload_Audio(WHDLAUDC_STOP)` and sets $3a8f2 to -1.
- `PL_R $3a95c`: The loop poll in the VBI is dropped, looping is done via
  `WHDLAUDF_LOOP`.
- `PL_R $3a9ba`: The volume is not handled, because the game only ever sets
  the maximum. It could be mapped to `WHDLAUDC_VOLUME`, for Xenon 2 that
  makes no difference.
- `PL_S $3aa4a,$3aae8-$3aa4a`: Opening the OS resources and the device
  stays skipped.

## Input (fire / B button)
Read in the VBI `lbC034BB2` (Slave $34fb2):
- `lbB034B64` (Slave $34f64): joystick state of the current frame, bit 7 =
  fire, bits 0-3 = directions; `lbB034B65` ($34f65) = state of the previous
  frame
- `lbB000606` ($a06): state for the game, only updated on change
- `lbB000607` ($a07): "fire newly pressed", set by the VBI, polled and
  cleared by all menus. Only the VBI, the attract demo (`lbC033226`) and
  the in-game autofire (`lbC039630`, game loop and demo only) set it.
- `lbB000605` ($a05): B button = $40. Originally polled every 20 frames
  without waiting for release, so holding B triggers repeatedly.
- Original edge check: set $a07 if fire is pressed and $a06 shows fire
  released. The game clears $a06 itself (menus after a direction, game
  start, death), so any joystick change while holding fire triggers again.
- Menus with confirmation (CHOOSE menu `lbC03D890`, shop `lbC03F2A2`):
  first fire shows/speaks the description (`lbC040DEC`), second fire on the
  same item executes it.
- Problem seen (6.11.2026): a long fire press in such a menu executed the
  item at once. Cause was the autofire switch of the joystick: an input log
  per frame showed fire pressed 3-4 frames / released 2-3 frames while
  held. Without autofire the game behaves correctly. A debounce fix
  (`_input`, press accepted only after N released frames) was tested and
  removed again, the original input code is unchanged.
- B button: a release-wait for B (replacing $35078-$350a4) was tested and
  removed again, the original 20 frame poll is unchanged.
- The highscore entry keeps `_waitautofire` (fire must stay released for
  50 frames) for the same autofire reason.

## "Select joypad mode" screen
After loading `CD0:SPEECHxx` and starting the title track (`lbC03C3D8`)
the game shows " SELECT JOYPAD MODE  AND PRESS BUTTON A " with a fade
(`lbC03C43C`-`lbC03C5A6`, table `lbW03C480`) and waits for fire. Nothing
is selected or stored, it only asks to set the switch on the CDTV
controller. `lbC03C564` then sets up the speech sample ($3F) and returns.

Slave: `PL_S $3c83c,$3c976-$3c83c` jumps from `lbC03C43C` directly to the
speech setup in `lbC03C564` (disassembly $3C576, after `addq`/`cmpi`/
`bne.w`).

## "Loading" screens
Before loading `CD0:LEVELn` (`lbC0334xx`, `lbC03CE60`) and `CD0:INTRO` the
game shows "LOADING PLEASE WAIT" / "LOADING LEVEL" (`lbC03C5E2`/`lbC03C5EA`
-> `lbC03C5F0`, hide `lbC03C61A`/`lbC03C622` -> `lbC03C628`) and sets the VBI
to `lbC034B7C`, which draws a starfield every 3 frames from `lbL084F80`.
The star data is initialized only in `lbC03B814` (called from the show
routine).

Slave: `PL_R` on the 4 show/hide entries ($3c9e2, $3c9ea, $3ca1a, $3ca22)
and `PL_S ...,10` on the 3 `move.l #lbC034B7C,$6C` in the loaders ($33910,
$3d284, $3d85e). Skipping only the screens gave "Integer Divide by Zero" at
$3be22 (`divs d2,d1` in the starfield, z = 0, star data not initialized).
The 4th `move.l #lbC034B7C,$6C` at game start (X2.asm line 81025) has its
own star init and is unchanged. Tested on the Amiga 6.11.2026: works.

## Stack
The game runs in supervisor mode the whole time (no SR changes). In
`lbC03A612` it saves sp to `lbL03394E` and sets `lea lbL084B9C,sp`
(Slave $3aa18), so the stack starts at $84f9c in chip memory and grows down
into the end of the buffer `lbL07F112` (used at X2.asm line 72332).

Slave: `ws_ExpMem` = $1000. `_start` sets sp = ExpMem + $1000 at the
beginning of the CDTV part, `PL_S $3aa18,6` skips the `lea` in the game.

## Tested
On the Amiga with an AmiGUS and `Audio=data-da` (evaluated via trace file):
- The plugin is loaded before the file cache. After the 97 game files
  (4.4 MB) all 12 tracks (about 100 MB) are preloaded. PreloadSize includes
  the audio tracks.
- In the game tracks are played and stopped, the stops work without a codec
  reset.
- ESC in the splash window during the file preload skips the audio preload.
  ESC during the audio preload stops between two tracks and the preload is
  marked as incomplete.
- On exit the card is freed, there is no memory leak.
- Whether the audio files are named `Track02.mp3` or `track02.mp3` does not
  matter, the search ignores case.

## Open
- Not yet checked in detail: music in title, levels, music selection and
  picture sequence, loop at the end of a track, music on/off in the game
  menu.
- `inst/install.prep` (CDTV) creates `data-da` and sets the disabled
  tooltype `;Audio=data-da`; the ReadMe explains copying the compressed
  tracks manually and that AmiGUS is required. Installer not yet run on
  the Amiga.
- Restart via MemConfig in the splash window while the tracks are preloaded.
