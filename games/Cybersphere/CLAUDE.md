# Cybersphere — game internals & reverse-engineering notes

Working notes for the WHDLoad install (slave `cybersphere.asm`). Collected Sept 2026.
Addresses are **offsets into hunk 0 of the game executable** unless stated otherwise —
i.e. exactly the numbers a `PL_` patch command takes.

Near-identical sibling: `games/CyberspherePlus` — same engine, same cheat, addresses
shifted by -$10 in the relevant area. See its `CLAUDE.md`.

## Files and where things live

| What | Where |
|---|---|
| Game executable | `data/Cybersphere`, 500200 bytes, plain LoadSeg hunk file (not crunched) |
| Data file | `data/CybersphereData.dat`, 2808 bytes |
| Install/test dir on the Amiga | `wart:cr/Cybersphere` (`data/` unpacked, not an archive) |
| ReSource disassembly on the Amiga | `cr:Cybersphere/Cybersphere.asm` (1.5 MB), project `Cybersphere.rs` |
| Release archive | `cr:Cybersphere.lha` |

The slave identifies the version by CRC16 of the first 300 bytes = `$c2e1`.

### Hunk layout of `data/Cybersphere`

Header: 4 hunks, `first=0`, `last=3`.

| Hunk | Size (longs) | Size (bytes) | End offset | Type |
|---|---|---|---|---|
| 0 | `$68C5` | `$1A314` | `$1A314` | CODE |
| 1 | `$179B` | `$5E6C` | `$20180` | DATA |
| 2 | `$BCD5` | `$2F354` | `$4F4D4` | DATA |
| 3 | `$A4B4` | `$29130` | — | DATA, MEMF_CHIP (`$4000A4B4`) |

ReSource lays the sections out contiguously, so its absolute addresses equal the hunk-0
offset for everything below `$1A314` — which covers all code discussed here.

**Hunk 0 data starts at file offset `$2C`.** Useful for checking a patch offset with
`dd if=data/Cybersphere of=T:slice.bin bs=1 skip=<$2C+offset> count=16` on the Amiga
(`type <file> hex` has no offset option; `dd` from GG is in the path).

## Cheat mode ("CALGARY")

Documented cheat: type `CALGARY` on the title screen, a chime confirms, then you can
start in any of the five sectors and skip levels with `Q`. Typing it again disables it.

### The check — title-screen key loop at `$9B22`

```
$9B22  jsr  (getkey)             ; $1A0, returns raw keycode in d0
       cmpi.b #$33,d0            ; 'C'  -> restart sequence, counter := 1
       move.w #1,($6876)
$9B46  lea  ($686C,pc),a0        ; keycode table
       move.w ($6876,pc),d1
       cmp.b (a0,d1.w),d0
       bne  $9B92                ; mismatch -> counter := 0
       addi.w #1,($6876)
       cmpi.w #7,($6876)
       bmi  $9B98
       eori.w #1,($686A)         ; <-- toggle the cheat flag
       beq  $9B86
       move.w #$13,d0            ; sound "cheat on"
       bsr  $2C06
       ...
$9B86  move.w #$14,d0            ; sound "cheat off"
```

| Address | Size | Meaning |
|---|---|---|
| `$686A` | word | **cheat flag**, 0 = off, 1 = on. `dw 0` in the file, never cleared at runtime |
| `$686C` | 10 bytes | keycode table `33 20 28 24 20 13 15 0A 0A 0A` = `C A L G A R Y` (raw keycodes) + padding |
| `$6876` | word | match counter |

The `'C'` case is handled separately (counter := 1), so index 0 of the table is only
there for symmetry; matching really starts at index 1.

### What the flag does — only two readers

**`$073C`, in-game key handler** (inside the loop at `$06E6`):

```
$0726  cmpi.b #$19,d0    ; 'P'     -> pause
       cmpi.b #$40,d0    ; space   -> pause
       tst.w  ($686A)    ; cheat off -> skip the rest
       beq    $07BE
       cmpi.b #$10,d0    ; 'Q'     -> skip level (sets $4C1E := 4, calls $3660)
       ...
$0762  andi.w #$FF,d0    ; raw keycodes $01..$0A = keys '1'..'0'
       cmpi.w #1,d0  / cmpi.w #11,d0
       ...                ; extra gates: $A5F8 == 0, $4C26 < 3, $4C06 == 0 (1-player)
       move.w d0,($1800) ; target level
       move.w #3,($4C1E)
       bsr    $3660
```

**`$8378`, sector-select screen** (routine at `$8352`):

```
$8352  ...
       move.l ($833E,pc),($8344)   ; copy the four "sector done" flags
       move.w ($8342,pc),($8348)
       tst.w  ($4C06) / bne $83D8  ; 2-player: no locking
       tst.w  ($686A) / bne $83D8  ; cheat:    no locking
       ; else count completed sectors and set $8347 / $8348 to 1 = locked
```

So with the flag set, `$8347`/`$8348` stay as copied and all sectors are selectable.

### The patch

`PL_W $686a,1` is all it takes — the flag lives in initialised data and nothing writes
to it except the `eori.w` above. Guarded with `PL_IFC1` in the slave, exposed as
`slv_config "C1:B:Enable cheat mode"`. Because it is the same flag, `CALGARY` on the
title screen still toggles the cheat back *off* when the option is enabled.

`slv_config` requires `slv_Version >= 17`; the version was bumped from 16 to 17 for
this (`ws_config` is a Version-17+ field in `whdload.i`). `PL_IFC1` is marked
"version 17.2" in `whdload.i` — `games/IK+` does the same with `ws_Version = 17`.

## Misc

- `getkey` at `$1A0`: reads the byte at `keycode1`, clears it with INTF_COPER masked,
  returns the raw keycode in `d0`. Negative/zero means "no key".
- Sound effects are played via `bsr $2C06` with the effect number in `d0.w`:
  `$13` = cheat on, `$14` = cheat off, `$5`/`$7` used by the level-select keys.
- `$9a` in hunk 0 is the VBR read routine, RTS'd by the slave (`PL_R $9a`) so WHDLoad's
  VBR = 0 emulation is used.
