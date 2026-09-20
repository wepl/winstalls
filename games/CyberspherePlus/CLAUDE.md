# Cybersphere Plus — game internals & reverse-engineering notes

Working notes for the WHDLoad install (slave `cybersphereplus.asm`). Collected Sept 2026.
Addresses are **offsets into hunk 0 of the game executable** unless stated otherwise —
i.e. exactly the numbers a `PL_` patch command takes.

Same engine as `games/Cybersphere`; that directory's `CLAUDE.md` has the fuller write-up
of the cheat logic. Everything below `$1A314` is structurally identical, the relevant
addresses are shifted by **-$10**.

## Files and where things live

| What | Where |
|---|---|
| Game executable | `data/CyberspherePlus`, 513080 bytes, plain LoadSeg hunk file (not crunched) |
| Data file | `data/CybPlusData.dat`, 2808 bytes |
| Install/test dir on the Amiga | `wart:cr/CyberspherePlus` — **`data/` is packed as `data.lha`**, unlike Cybersphere |
| ReSource disassembly on the Amiga | `cr:CyberspherePlus/CyberspherePlus.asm` (1.6 MB), project `CyberspherePlus.rs` |
| Release archive | `cr:CyberspherePlus.lha` |

The slave identifies the version by CRC16 of the first 300 bytes = `$e489`.

To inspect the executable, extract it first (lha's destination directory must already
exist, and `cd` must be its own line in an `amiga_shell` call):

```
makedir T:csp
cd T:csp
lha -N x wart:cr/CyberspherePlus/data.lha CyberspherePlus
```

### Hunk layout of `data/CyberspherePlus`

Header: 4 hunks, `first=0`, `last=3`.

| Hunk | Size (longs) | Size (bytes) | End offset | Type |
|---|---|---|---|---|
| 0 | `$68CA` | `$1A328` | `$1A328` | CODE |
| 1 | `$242A` | `$90A8` | `$233D0` | DATA |
| 2 | `$BCD5` | `$2F354` | `$52724` | DATA |
| 3 | `$A4B4` | `$29130` | — | DATA, MEMF_CHIP (`$4000A4B4`) |

ReSource lays the sections out contiguously, so its absolute addresses equal the hunk-0
offset for everything below `$1A328`.

**Hunk 0 data starts at file offset `$2C`.** Check a patch offset with
`dd if=T:csp/CyberspherePlus of=T:slice.bin bs=1 skip=<$2C+offset> count=16`.

## Cheat mode ("CALGARY")

Identical to Cybersphere: type `CALGARY` on the title screen, a chime confirms, then you
can start in any of the five sectors and skip levels with `Q`. Typing it again disables it.

### Address map vs. Cybersphere

| What | Cybersphere | **Cybersphere Plus** |
|---|---|---|
| title-screen key loop | `$9B22` | `$9B12` |
| **cheat flag** (word) | `$686A` | **`$685A`** |
| keycode table (10 bytes) | `$686C` | `$685C` |
| match counter (word) | `$6876` | `$6866` |
| in-game key handler reads flag at | `$073C` | `$072C` (loop at `$06D6`, block at `$0716`) |
| sector select reads flag at | `$8378` | `$8368` (routine at `$8342`) |
| `getkey` | `$1A0` | `$1A0` |
| sound routine | `$2C06` | `$2BF6` |
| level-jump helper | `$3660` | `$3650` |

Keycode table at `$685C` is byte-for-byte the same:
`33 20 28 24 20 13 15 0A 0A 0A` = `C A L G A R Y` + padding.

Verified against the original file: at file offset `$2C + $685A` the bytes are `00 00`,
immediately followed by `33 20 28 24 20 13 15`.

### Flow (same shape as Cybersphere)

```
$9B12  jsr  ($1A0)               ; getkey
       cmpi.b #$33,d0            ; 'C' -> counter := 1
       move.w #1,($6866)
$9B36  lea  ($685C,pc),a0
       cmp.b (a0,d1.w),d0
       addi.w #1,($6866)
       cmpi.w #7,($6866)
       eori.w #1,($685A)         ; <-- toggle the cheat flag
       ...                       ; sound $13 = on, $14 = off, via bsr $2BF6
```

The flag has exactly two readers — the in-game key handler (`Q` = skip level, keys
`1`–`0` = level jump) and the sector-select routine (skips the lock logic). It is
`dw 0` in initialised data and is never cleared at runtime.

### The patch

`PL_W $685a,1`, guarded with `PL_IFC1`, exposed as
`slv_config "C1:B:Enable cheat mode"`. `slv_Version` bumped 16 -> 17 because
`ws_config` is a Version-17+ field. `CALGARY` on the title screen still toggles the
cheat back *off* when the option is enabled.

`$9a` in hunk 0 is the VBR read routine, RTS'd by the slave (`PL_R $9a`).
