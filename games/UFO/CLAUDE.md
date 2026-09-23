# UFO Enemy Unknown — game internals & reverse-engineering notes

Working notes for the WHDLoad install. Collected Sept 2026.
Addresses are **offsets into the code hunk of the game executable** unless stated
otherwise — i.e. exactly the numbers a `PL_` patch command takes, and exactly the
addresses of the `lbC0.....` labels in the ReSource disassemblies.

Two independent builds, two slaves, both built by one `Makefile` (`NOSLAVERULE = 1`,
`slaves` as default target, one explicit rule per source):

| Slave | Source | Version | Kickstart | Executables |
|---|---|---|---|---|
| `UFO.Slave` | `ufo.asm` | OCS 1.1 | 1.3 (`kick13.s`) | OCS build, `data/GEO` + `data/Tactical` |
| `UFO_AGA.Slave` | `ufo_aga.asm` | AGA/CD³² 1.2 | 3.1 (`kick31.s`) | AGA/CD³² build, different codebase |

The OCS slave runs the two executables itself in `_bootdos` (`geo` → `tactical` → `geo` …),
identifies each by CRC16 of the first 300 bytes (`$8ded` geo, `$8cf3` tactical) and patches
them with `resload_PatchSeg`.

## Files and where things live

| What | Where |
|---|---|
| Dev/test install on the Amiga (`make dest`) | `wart:u/ufo`, data in `data-ocs`, `data-aga`, `data-cd32` |
| Savegame for mantis 6623 (OCS) | `wart:u/ufo/data-ocs/game_2` (the files attached to the ticket) |
| Installed package | `WArt:UFO`, data in `data/` |
| ReSource disassemblies, OCS | `cr:ufo/ocs/GEO.asm`, `cr:ufo/ocs/Tactical.asm` (projects `*.rs`) |
| ReSource disassemblies, AGA | `cr:ufo/aga/GEO.dec.asm`, `cr:ufo/aga/Tactical.dec.asm` |
| CD³² disassemblies | `cr:ufo/cd32/` |
| WHDLoad dumps | `Temp:.whdl/` (`.whdl_register`, `.whdl_dump`, `.whdl_memory`, `.whdl_expmem`) |

The install package is generated from `../../inst/Install` + `inst/install.prep`; the
pre-generated `inst/Install` from package 1.1 was deleted. `install.prep` selects between
three file-copy variants — version 0 = OCS, 1 = AGA, 2 = CD³², where 1 and 2 set
`#prefix-slave` to `UFO_AGA`. `locale.library` is copied by the installer script but is not
covered by any `#...-file=` variable, so the `Makefile` pulls it in via `INSTFILES`.

## Working on the Amiga

`.whdl_register` is append-only, newest dump last (`tail -80`). GG tools (`grep`, `sed`,
`awk`, `head`, `tail`, `dd`, `md5sum`, `perl`) are in the path; `grep -n` prints no line
numbers and has no `-A`/`-B`, use `awk "/pattern/{print NR}"` plus `sed -n "a,bp"` instead,
and pass awk programs via a file for anything containing tabs or `$`.

`WI:` (= the repo on the Mac) points at `iMac:` which is usually **not** mounted, and
`Mount iMac:` fails — there is no MountList entry. Getting a fresh slave over therefore
needs the mount, or `make dest` run on the Amiga. Pushing a binary with the agent's own
write tool works per se (all 256 byte values survive), but a single ~8 KB base64 blob got
one extra character inserted on the way into the tool call, so transfer in small chunks and
always verify with `md5sum`.

### Mapping a dump address to a disassembly label

That `Prg 'tactical' Off $xxxxx` line only appears when the slave is built with
`SEGTRACKER` — the flag is off in the released slaves, so switch it on in `ufo.asm` while
debugging and comment it out again before the release (it costs about 640 bytes).

The register dump then gives `Prg 'tactical' Off $xxxxx` for the PC. Subtract that offset
from the PC to get the load base, then every `lbC0<addr>` label is `base + addr`. Verified twice
for the 22-Sep-2026 dump: base `$FC7E038`, `$FCBA7E2` = `lbC03C7AA`, existing patch
`$3e796` = `lbC03E796` (`move.w #INTF_INTEN,($DFF09A).l`).

**Data labels do not follow that rule** — `lbW0.....`/`lbL0.....` sit in a later hunk which
LoadSeg places independently; measured delta for the 22-Sep-2026 dump was `-$28`. Only
code offsets are safe to use for `PL_` patches.

To check bytes at a code offset against the crashed image:
`dd if=Temp:.whdl/.whdl_expmem bs=1 skip=<(base-ExpMemStart)+offset> count=16 of=T:probe.bin`
(`ExpMem` start is printed in the dump header), then read `T:probe.bin` base64-encoded.

## `tactical`, OCS build — alien turn progress bar

The "hidden movement" bar is driven by these words (labels from `cr:ufo/ocs/Tactical.asm`):

| Label | Meaning |
|---|---|
| `lbW043DA6` | total number of alien moves for the turn |
| `lbW043DA8` | moves already done |
| `lbW043DA4` | current percentage, clamped to 100 |
| `lbW043DA2` | last drawn percentage, `$FFFF` after init |
| `lbW043778` | pass counter, the unit list is walked twice per turn |

Unit table: `lbL049798`, 80 entries of 12 bytes. A unit counts as a movable alien when
`(9,a5) == 1` and bit 6 of `(10,a5)` is set.

- `lbC004670`ff — turn init: clears both counters, counts the movable aliens into
  `lbW043DA6`, then doubles it at `lbC004798` (`add.w d0,d0`) because of the two passes.
- `lbC0047B8`/`lbC0047C0` — the per-unit loop, `addq.w #1,(lbW043DA8)` per processed alien;
  every unit that does not qualify branches straight to `lbC004968`.
- `lbC004968` — `lbW043DA4 = 100 * lbW043DA8 / lbW043DA6`, clamped to 100, then redrawn at
  `lbC0049AC`ff if it differs from `lbW043DA2` (bar drawn with width `percentage - 1`, so a
  percentage of 0 would draw with -1).

### Division by zero, mantis 6623 (fixed in OCS 1.1)

Last mission, all aliens killed except the brain, end turn → `Exception "Integer Divide by
Zero"`. No unit satisfies the counting condition (the brain evidently does not), so
`lbW043DA6` stays 0 and `lbC004968` divides 0 by 0. Confirmed in the crash image of
22-Sep-2026: `lbW043DA2 = $FFFF` (bar never drawn this turn), `lbW043DA4 = 0`,
`lbW043DA6 = 0`, `lbW043DA8 = 0`, and `D0 = D1 = 0` in the register dump.

The crash PC is inside the C runtime's signed 32-bit division helper (`lbC03C778` =
`__ldiv`, unsigned core `lbC03C7AA`, faulting `divu.w` at `lbC03C7C8`); the caller is the
`jsr (lbC03C778).l` at **`$498e`**, return address `$4994`.

Fix in `ufo.asm`: `PL_PS $498e,_percent` replaces that 6-byte `jsr` (`4EB9 xxxxxxxx`,
verified in the dump) and does the division in the slave, returning 100 when the divisor is
0 — 0 would make the bar draw with width -1.

Verified with `data-ocs/game_2` (load, end the turn immediately): no divide by zero any
more.

The AGA build is not affected — its equivalent code (`lbC02EBD2`ff in
`cr:ufo/aga/Tactical.dec.asm`) does `addq.l #1,d6` before `divu.l d6,d2`, so the divisor is
never 0.
