# Lin Wu's Challenge — game internals & reverse-engineering notes

Working notes for the WHDLoad install (imager `linwuschallenge.islave.asm`, slave
`linwuschallenge.asm`). Collected Sept 2026. Addresses are **runtime addresses**
unless stated otherwise.

## Versions and originals

| Version | Image | Notes | `CP` | `MAP` | `HIGH` |
|---|---|---|---|---|---|
| v1 | `data:originals/games/LinWusChallenge/v1/LinWu-d1.wwp` | original with disk protection | 3958 bytes (protection code) | 22925 bytes | default table ("AAE" $5000 first) |
| v2 | `data:originals/games/LinWusChallenge/v2/LinWu-d1-2.wwp` | password system, no disk protection | 22 bytes stub | 20301 bytes | played ("LION" $9111 first) |
| v3 | english release, installed on the Amiga in `wart:li/LinWusChallenge/data-v3` | password system, no `CP` on the disk at all, `STARTUP` 4840, `GAME` 15858 | - | 20297 bytes | |

- All other 36 files are identical in both versions, including `loader` (tracks 78-79).
- v3 (2026-09-19, english): 37 files, no `CP`; `STARTUP`, `GAME` and `MAP` differ, all
  other files are identical to v1/v2. Differences found so far:
  - `STARTUP` (4840, 10 bytes shorter): identical structure, all addresses from the
    beginning shifted by -$a -> motor off `$36ce`, motor on `$370c`, keyboard install
    `$3898`, INTENA immediate `$3904`. The string table still contains "CP" but nothing
    references it, so `CP` is never loaded.
  - `GAME` (15858): identical up to at least `$41cb4`, so all keyboard offsets and both
    trainer patches are the same. The STARTUP checksum at `$41cb4` is still computed but
    the `bne` after it was removed (`$41cb8` is `movem.l (a7)+,d0-d7/a0-a6`), so the
    protection is gone - `PL_NOP $1cb8,4` must *not* be applied to v3.
  - `MAP` (20297, 4 bytes shorter): like v2 (password system at `$402b0`, no disk check);
    identical up to `$40248`, everything after shifted by -4 (motor on `$41688`, seek
    `$416a2`, motor off `$41bd0`, motor on `$41c0a`, opponent table `$441b6`).
- The data directories on the Amiga: v1/v2 are packed with ProPack (RNC\1 header, the user
  packed everything that was not PowerPacker crunched), v3 is unpacked. `xfddecrunch`
  unpacks them; WHDLoad decrunches transparently, the slave identifies the files by their
  *unpacked* length.
- v2 is most likely an official later release (the encrypted booter is unchanged, a
  password system was added), not a crack — not proven.
- The directories `v1` and `v2` contain only the wwp images (extracted files and the
  track dumps formerly lying next to them are gone).
- Install/test dir on the Amiga: `wart:li/LinWusChallenge` with `data-v1`, `data-v2`,
  `data-v3` and one icon per version.
- Own work files on the Amiga in `cr:LinWusChallenge`: `track.000/078/079.dosf`,
  `track.078.dosf.asm` (ReSource disassembly of the loader), `lib.00c0.bin` (decrypted
  file system library, 5044 bytes, `$c0-$1473`, MD5 `33e4fb7e5b492685a2ee278820fbfa5c`),
  `declib.rexx` (creates `lib.00c0.bin` from `track.078/079.dosf`).

## Disk layout

| Tracks (RawDIC numbering) | Contents |
|---|---|
| 0 | DOS bootblock, loads tracks 78-79 (`$2c00` bytes) to `$70000` and jumps there |
| 1 | directory, custom format |
| 2-63 | file data, custom format |
| 64-77 | unformatted |
| 78-79 | DOS tracks, loader (`loader`) |
| 80-81 | DOS tracks, small OFS filesystem (root block 880 on track 80), probably the VirusProtector, not used by the game |
| 82-159 | unformatted |

Bootblock (`DOS\0`, checksum `$985e2743`): `IO_COMMAND=CMD_READ, IO_LENGTH=$2c00,
IO_DATA=$70000, IO_OFFSET=$6b400`, `DoIO`, `jmp $70000`. Text in the booter: "AXXESS SAYS
: PLEASE DON'T CRACK THIS COOL GAME ... THIS FUNNY SYNC BOOTER WAS WRITTEN BY OLAF
HOEHMANN (AAE)".

### Custom format (as implemented by the library at `$c0`)

- MFM: sync `$2245` once, then `$5fc` decoded longs, each long stored as odd-bits long
  followed by even-bits long (`((a&$55555555)<<1)|(b&$55555555)`), then 2 zero longs.
  The library reads `$1810` words (DSKLEN `$9810`) and writes a gap of `$aaaaaaaa`
  (`$da0` longs) + sync + data (DSKLEN `$db40`).
- Data tracks: 23 sectors of `$10a` bytes:
  - `$000` word sector number 0-22
  - `$002` word next block
  - `$004` long checksum = sum of the 64 data longs
  - `$008` word unused (leftover of the format fill pattern `'OFS-'`)
  - `$00a` 256 bytes data
- Block number = track * 23 + sector (3680 blocks = 160 tracks).
- Directory track 1:
  - `$004` long checksum = sum of `$3f7` longs starting at `$008`
  - `$008` word number of files (max `$dc`)
  - `$00a` entries of 20 bytes: name (10 bytes, not always 0-terminated), long length in
    bytes, word first block, word unused
  - `$1200` block allocation bitmap (`$1cc` bytes, bit set = used, bit = `blk&7` of byte
    `blk>>3`); not covered by the checksum
- File chains end with next block 0. The v1/v2 directory contains a broken file `GANE`
  whose chain runs into unformatted track 64 (the imager skips it with a message).

## Directory (v1)

39 entries, all names uppercase. Load addresses from `STARTUP`/`MAP` calls.

| File | Length | Packed | Unpacked | Load address / use |
|---|---|---|---|---|
| STARTUP | 4850 | no | | `$3000`, main program started by the booter |
| 1 | 4880 | no | | variant of STARTUP, not loaded |
| AAE | 2236 | PP20 | 7044 | `$50000`, code (`STARTUP` calls `$50000`, `$50004`, `$50008`) |
| LINVARA | 49692 | PP20 | 73426 | `$5c200` |
| LASERSOFT | 17000 | PP20 | 66852 | `$30000`, intro, sets vectors `$80`/`$6c` |
| CP | 3958 | no | | `$40000`, protection, `jsr $40000` |
| LINTHEME | 61144 | PP20 | 88866 | `$2a300` |
| MAP | 22925 | no | | `$40000`, map/title program, loads/saves `HIGH` |
| MAP_TITLE | 8332 | PP20 | 29760 | `$46bb0` |
| MAP_FACES | 14496 | PP20 | 24640 | `$557f0` |
| MAP_CHAR | 300 | PP20 | 640 | `$5be70` |
| MAP_MAP | 20452 | PP20 | 81920 | `$5c000` |
| MAP_COMP | 468 | PP20 | 1024 | `$46bb0` |
| GAME | 15850 | no | | `$40000`, game program, sets vector `$6c` |
| GAMEBRICKS | 21192 | PP20 | 46080 | `$44d40` |
| GAMETEXT | 3804 | PP20 | 23856 | `$50280` |
| GAMESCORE | 2024 | PP20 | 4480 | `$56200` |
| GAMEHELP | 1496 | PP20 | 11264 | `$57380` |
| HIGH | 160 | no | | highscores, 10 entries of 16 bytes (word score, 10 chars name, padding) |
| LINGAME, LINSCORE | 1052, 2644 | PP20 | 9280, 16448 | probably music (data starts with "lingame1", "linscore") |
| LIN*, HIGHHATS, MARIMBAII, STARPEACE, THEEGGIV | | PP20 | | instruments/samples |

`STARTUP` also references "TITLEMUSE" and "SHOW_PRG", but never loads them (not on disk).
`STARTUP` and `1` install vectors `$68` and `$6c` themselves.

## Loader tracks 78-79 (`loader`, runtime `$70000`)

Stages (verified in vAmiga with Kickstart 1.3):

1. `$70000`: `trap #0` -> supervisor, SSP `$80000`, clears `$0-$70000`, all vectors
   `$0-$bc` -> `$be`, copper list at `$70144` (writes ADKCON `$8001`, `$8f84`, `$7fff`, ...
   between colors), `lea ($400).l,sp`, enables VERTB, then runs a fake decrypt loop
   (`$78000` -> copper list) until the VERTB interrupt enters `ints` (`$70990`).
2. `ints`: clears memory again, `(0)` = `clist_code` (`$70b68`), copies `_60000`
   (file offset `$91c`, `$401` longs) to `$60000`, waits for line `$ff`, trace vector
   `$24` = `_trace` (`$70a8a`), clears ADKCON and waits until ADKCONR = 1, then
   `move.w #$a700,sr` + `nop`.
3. **Trace decoder** `_trace`: for each traced instruction the next instruction is
   decoded in place: `(pc) += d2`, `(2,pc) += d3`, `(4,pc) += ~d3` with
   - `d2 = ADKCONR + chk + sp.w + $aae1`, `d3 = (ADKCONR ^ chk ^ SR) & $fff0`
   - `chk` = 32-word checksum over `_trace` (`add.w (a6)+,d6; eor.w d4,d6`, d4 `$1f`..0),
     the last word is `code1dest` which was patched to `$5345` before -> `chk = $a5e2`
   - actual values: ADKCONR = `$f85` (copper already did `$8f84`), handler sp = `$3f4`
     (SSP `$3fa`, not `$80000`), `d2 = $643c`. Only works on 68000 (6 byte frame).
   - `code1dest`: `subq.w #1,d5; beq` limits tracing to 65535 steps.
4. Decoded code (the `eori/not/neg (a0)` block at `$70a58` is a decoy, never executed):
   ```
   $70a3c  move.b  #$aa,$bfd401        ; CIA-B TALO
   $70a44  lea     $c0.l,a0
   $70a4a  move.b  #$e1,$bfd501        ; CIA-B TAHI
   $70a52  jmp     $60000.l            ; long $4ef90006 is the key below
   $60000  move.w  #$2000,sr           ; trace off
   $60004  movea.l #$8a68759f,a3       ; still decoded (trace fires after SR change)
   $6000a  movea.l #$80000,sp          ; plaintext from here
   ```
5. `$6000a`: DMACON `$83f0`, BPLCON0 `$200`, copies `$1101` longs from `$70c3a` to `$c0`
   and decrypts: `eor.l #$4ef90006,(a0)+; eor.w d1,(-4,a0)` with d1 `$1100`..0
   (i.e. key ^ (counter<<16)). Real data ends at `$1473` (source up to `$71fed`).
   Then `jmp` via `(0)` to `clist_code`.
6. `clist_code` (`$70b68`): fades a small copper list, then `startup`: ADKCON `$7fff`,
   `clr.l 0`, `a6=($c0)`, init (`jsr -$1e(a6)` with a0=`$71000` MFM buffer, a1=`$75000`
   track buffer, d0=`$2245` sync, d1=0 unit), load `STARTUP` to `$3000` (`jsr -6(a6)`),
   `jmp $3000` (SSP `$80000`, SR `$2000`).

## File system library at `$c0`

`($c0)` = `$e8` (library base). Jump table `$c4-$e7`, each entry `move.w #fn,d7; bra`
to a dispatcher that saves `d3-d7/a1-a6`.

| Offset | d7 | Function | Parameters |
|---|---|---|---|
| -6 | `$65` | load file | a0 = name (uppercased), d0 = address; PP20 files are decrunched |
| -$c | `$66` | save file | a0 = name, d0 = address, d1 = length (existing file is deleted first) |
| -$12 | `$67` | delete file | a0 = name |
| -$18 | `$68` | nop | |
| -$1e | `$69` | init | a0 = MFM buffer, a1 = track buffer, d0 = sync, d1 = unit |
| -$24 | `$6a` | read and check directory | |

Return: d0 = error code (0 = OK), d1 = file length from directory (packed length),
a0 = error text. Errors show a "DISK ERROR !!!! CODE-xx" screen and reset (`jmp $fc0002`).
Error texts: OK, DISK IS WRITE PROTECTED, NO DISK IN DRIVE, READ ERROR, WRITE ERROR,
FILINGSYSTEM NOT INITIALIZED, DISK IS FULL, DIRECTORY IS FULL, OFFSET GREATER THAN
FILELENGTH, FILELENGTH GIVEN TO GREAT, DISK NOT READY, CHECKSUM ERROR, CHECKSUM ERROR IN
ROOT, FILE NOT FOUND.

PP20 decrunch (library `LAB_00b6`): decrunches to `address+$180`, then copies the data
down to `address` (so memory up to `address+unpacked+$180` is used). Standard
PowerPacker algorithm, efficiency table at `+4`, last long = unpacked length<<8 | skip bits.

The game only uses **-6 load** (`STARTUP`, `MAP`) and **-$c save** (`HIGH` in `MAP`,
160 bytes). Before each call `STARTUP`/`MAP` toggle drive select/motor bits on CIA-B PRB.

## Protection (v1)

- `CP` (loaded to `$40000`, called by `STARTUP`) must leave `($84)=0` and `($88)=$500`.
  v2 `CP` is exactly `move.l #0,$84; move.l #$500,$88; rts`. v1 `CP` code not analysed.
- `MAP` checks `($88)>$13f` (loops otherwise, `$4027e`) and `($84)=0`.
- `MAP` v1 disk check routine `$41278` (called from `$40514` and `$4252c`):
  - trace handler `$41294` = `addi.l #2,(2,a7); rte` -> every real instruction is
    prefixed by a junk word `$23f9`, branch targets and return addresses also skip 2 bytes
  - lots of `bsr` into stubs at `$420d2-$42164` that only contain `rts` (noise); the code
    also rewrites stub words at `$42110`/`$42140`
  - checksum routine `$4129a` over `$e18` bytes of the protected block (anti tamper)
  - check: select DF0, step to track 0, step 37 cylinders (RawDIC track 74), read raw
    MFM with DSKSYNC `$4489`, DSKLEN `$9c40`, count `$ff` bytes in `$3000` bytes, needs
    more than `$150`; 10 retries, on failure disables interrupts and locks up (`$41fe2`)
- `MAP` v2 has none of this but a password system (texts "PASSWORD", "WRONG PASSWORD",
  "PASSWORD FOR THIS LEVEL IS ........"), see below.
- Cheat in both versions (v1 `$407ea`, v2 `$40c32`, checked after the name input): if the
  entered player name is "XTRAAE" followed by two digits (`cmpi.l #"XTRA",($1a,a0)`,
  `cmpi.w #"AE",($1e,a0)`), the words at `($12,a0)`, `($14,a0)` and `($16,a0)` of the game
  structure (v1 `($42974)`, v2 `($41f34)`; normally 1/0/2) are set to `$7000` and the two
  digits are taken as the start level (`(a0)` = `10*d1+d0`).

## Password system (v2 only)

- Input buffer `$40386`, 8 characters; each character is `'A'+nibble`, so the password is a
  32 bit value written with the letters A-P, most significant nibble first.
- Check `$4026e` (called from `$40ab8`): reads the 8 characters (`$4037c`:
  `move.b (a0)+,d0; subi.b #$41,d0; or.b d0,d1`, shifted left by 4 between the calls),
  stores the value at `$40304`, the level `low16 / 65` (`divu #$41`) at `$40308`, byte 3 at
  `$4030a` and byte 2 at `$4030c`. `$4034e` adds the four nibbles of the low word
  (`d2` = sum) and returns `d1` = `-sum` as a byte. Accepted if byte 3 == `-sum & $ff` and
  byte 2 == `sum`, then d0=0, else d0=-1 and "WRONG PASSWORD". On success `$40ae0` copies
  `$40308` into the level word (`($41f34)`) and sets `(12,a0)`=3.
- Generator `$4030e` (called from `$40752` for "PASSWORD FOR THIS LEVEL IS"):
  `value = (-sum & $ff)<<24 | sum<<16 | level*65`, where sum is the nibble sum of
  `level*65`.
- Levels run to 60 (`$40afc` `cmpi.w #$3b,d6` clamps 59/60 to 60). Passwords:

  | Lvl | Password | Lvl | Password | Lvl | Password | Lvl | Password |
  |---|---|---|---|---|---|---|---|
  | 1 | PLAFAAEB | 16 | PLAFAEBA | 31 | NNCDAHNP | 46 | NNCDALKO |
  | 2 | PGAKAAIC | 17 | PGAKAEFB | 32 | PGAKAICA | 47 | NICIALOP |
  | 3 | PBAPAAMD | 18 | PBAPAEJC | 33 | PBAPAIGB | 48 | PBAPAMDA |
  | 4 | PLAFABAE | 19 | OMBEAEND | 34 | OMBEAIKC | 49 | OMBEAMHB |
  | 5 | PGAKABEF | 20 | PGAKAFBE | 35 | OHBJAIOD | 50 | OHBJAMLC |
  | 6 | PBAPABIG | 21 | PBAPAFFF | 36 | PBAPAJCE | 51 | OCBOAMPD |
  | 7 | OMBEABMH | 22 | OMBEAFJG | 37 | OMBEAJGF | 52 | OMBEANDE |
  | 8 | PGAKACAI | 23 | OHBJAFNH | 38 | OHBJAJKG | 53 | OHBJANHF |
  | 9 | PBAPACEJ | 24 | PBAPAGBI | 39 | OCBOAJOH | 54 | OCBOANLG |
  | 10 | OMBEACIK | 25 | OMBEAGFJ | 40 | OMBEAKCI | 55 | NNCDANPH |
  | 11 | OHBJACML | 26 | OHBJAGJK | 41 | OHBJAKGJ | 56 | OHBJAODI |
  | 12 | PBAPADAM | 27 | OCBOAGNL | 42 | OCBOAKKK | 57 | OCBOAOHJ |
  | 13 | OMBEADEN | 28 | OMBEAHBM | 43 | NNCDAKOL | 58 | NNCDAOLK |
  | 14 | OHBJADIO | 29 | OHBJAHFN | 44 | OHBJALCM | 59 | NICIAOPL |
  | 15 | OCBOADMP | 30 | OCBOAHJO | 45 | OCBOALGN | 60 | OCBOAPDM |

  (level 0 = "AAAAAAAA"). Because the level is `low16 / 65`, 65 different low words work per
  level; the table lists the canonical ones the game itself displays.
- The password has no other effect: on success only the level word and the mode
  `(12,a0)` = 3 (normal start is 2) are set, there is no cheat or special code. There is
  also no range check - codes up to level 1008 (`$ffff/65`) are accepted, but the board
  selection clamps everything from 59 on to level 60 (`$40afc` and `$4066c`).
- The only other "code" in the game is the XTRAAE name cheat, see "Protection (v1)".
- Level structure: the opponent is selected with `d7 = (level-2)/3` as index into the table
  at `$441ba` (`$40b0e`/`$40b14` and `$4067e`/`$40684`), 20 entries of 16 bytes, so
  **3 games per opponent**, 20 opponents, levels 2-61 (the clamp `cmpi.w #$3b,d6` maps 59+
  to 60). Entry layout: 4 words (map positions, `(0)` and `($10)` are the path chain), long
  at `+8` = description text, long at `+$c` = name record (printed at `$406f4`
  `movea.l (12,a0,d7.w),a0`).
- The game displays the opponent name and the password only if `($e,a0)` (game number
  within the opponent) is 0 (`$40706`/`$40736` `tst.w (14,a0)` / `bne`), i.e. once per
  opponent. All other level passwords are accepted as well, they are just never shown.
- Opponents in play order (name record read from the table), first level and its password:

  | # | Opponent | Country | Lvl | Password | # | Opponent | Country | Lvl | Password |
  |---|---|---|---|---|---|---|---|---|---|
  | 1 | A. SORBAS | GREECE | 2 | PGAKAAIC | 11 | CHRIS VAN DEGE | NETHERLANDS | 32 | PGAKAICA |
  | 2 | KARL SON | SWEDEN | 5 | PGAKABEF | 12 | SAM GOLD | AUSTRALIA | 35 | OHBJAIOD |
  | 3 | SIR TOBY | ENGLAND | 8 | PGAKACAI | 13 | TONY MAY | SWITZERLAND | 38 | OHBJAJKG |
  | 4 | AL SADAT | ISRAEL | 11 | OHBJACML | 14 | K. SPAROV | U.S.S.R. | 41 | OHBJAKGJ |
  | 5 | ANNIE NOX | U.S.A. | 14 | OHBJADIO | 15 | SEPP WIEN | AUSTRIA | 44 | OHBJALCM |
  | 6 | JANE CAP | CANADA | 17 | PGAKAEFB | 16 | WIN POO | KOREA | 47 | NICIALOP |
  | 7 | JOE MIRO | SPAIN | 20 | PGAKAFBE | 17 | KY TANG | TAIWAN | 50 | OHBJAMLC |
  | 8 | JOS STEIN | NORWAY | 23 | OHBJAFNH | 18 | MIH CHOW | JAPAN | 53 | OHBJANHF |
  | 9 | EVE BELL | FRANCE | 26 | OHBJAGJK | 19 | LIN WU | CHINA | 56 | OHBJAODI |
  | 10 | G. NORHOD | FINLAND | 29 | OHBJAHFN | 20 | COMPUTER | GERMANY | 59 | NICIAOPL |

  Name records (v2): `$422a8`, `$41f88`, `$43c02`, `$42452`, `$425fc`, `$42e2e`, `$42ff6`,
  `$431ba`, `$42978`, `$42c98`, `$427d2`, `$4384c`, `$43d92`, `$4332e`, `$43a16`, `$43f42`,
  `$434f6`, `$436bc`, `$42150`, `$440d0` (6 bytes header, then name and country).

## Protection (both versions): CIA-B timer A

- The trace-decoded loader code writes CIA-B TALO=`$aa`, TAHI=`$e1` (`$70a3c`/`$70a4a`).
- `GAME` reads TAHI via `$f0500+$b0d000` (= `$bfd500`) and compares with `$e1`:
  - `$40a62` (`LAB_0021`): on mismatch jumps into the score display routine and skips the rest
  - `$40c42` (`LAB_0032`, called twice per turn from `$40dda`/`$40de4`): on mismatch
    branches to `$40ab2`, which restores the VBL vector and ends the round
  - `$414a0` (`LAB_006A`): on mismatch skips a sound (AUD3)
- The slave sets both bytes before starting (added 2026-09-15, after the access fault below).

## Protection (both versions): STARTUP checksum in GAME

- `GAME` `$41c92` (level end loop at `$41c5a`): checksum `add.w (a0)+,d1; eor.w d0,d1` over
  `$380` words from `$3000` (`STARTUP` `$3000-$36ff`, address hidden as `$1800+$1800`), must be
  `$16e0`. On mismatch `$41cce` patches the following `jmp` to `$c0` and jumps there with a
  `movem d0-d7/a0-a6` frame on the stack -> crash (address error at an `rts`, e.g. `$40b12`).
- Hit 2026-09-15 after `PL_R $6d8` in `STARTUP` (inside the range) when the 2nd level was
  completed. Fix: `PL_NOP $1cb8,4` in `_pl_game`. Other `STARTUP` patches (`$716`, `$8a2`,
  `$90e`) are outside the range. No such checksum pattern found in `MAP` v1/v2.
  Verified by the user: level 2 completes again.

## Score

- `GAME` `$40934` adds points: `d0` = BCD word, player 1 via `$4094e` into `$43dbc` (temp
  `$43dbe`), player 2 via `$409aa` into `$43dc0` (temp `$43dc2`), 2x `abcd` (4 digits).
  Callers `$400f6`, `$40104`, `$40822` (d0=0, redraw), `$4038e` (`($43dc8)+1`).
- At exit (`$40af0`) the scores are copied to `(4,a0)`/`(6,a0)` of the `STARTUP` structure
  (`$377c`), `MAP` handles the highscore entry.
- Test trainer (Custom1, 2026-09-15, removed again after highscore saving was verified):
  `PL_PS $94e`/`$9aa` -> `lsl.w #4,d0; lea $43dbe/$43dc2,a0; move.w d0,(a0)` (BCD x10).

## Time limit

Two independent counters, both served by the `GAME` VBL handler `$4199c`:

**Displayed level time `$43dc4`** (this is the one the player sees, 4 BCD digits):
- The handler counts 5 frames in `$43dcc` (`$41a5a` `addi.w #1`, `$41a5e` `cmpi.w #5,(a0)`,
  immediate word at **`$41a60`**); every 5th frame, if `$43dc4` is non zero, it calls
  `$40a06` with d0=1.
- `$40a06`: `$43dc6` = d0, then `sbcd -(a1),-(a0)` twice at **`$40a14`** (a1 = `$43dc8`,
  a0 = `$43dc6`) subtracts the BCD word `$43dc6` from the BCD word `$43dc4`, then draws the
  four digits via `$41ace` at char positions `$36`/`$39`/`$3c`/`$3f`. So the time ticks down
  at 10 Hz. `$40052` calls it with d0=0 (initial display, no subtraction).
- Time out: `$4077e` (called from `$40122`, `$40224`, `$402e0`) tests `$43dc4`; when it is 0
  it drops the return address, shows message 6 (`$41ba4`) and jumps to `$40ad4` (game over).
- Initial value: `$41c2e` (level build, called at `$40060`) sets the budget `$43de4` to
  `$2da` and adds `$32` per tile pair (`$41e4c`) plus `$14`×`$43d7e` (`$41e66`); at the end
  `$41d74` converts it to BCD into `$43dc4`. So the time depends on the level size.

**Per turn counter `$43dc8`** (single character, drawn by `$41b6e` at `$7c658`):
- `$43dca` counts `$78` frames (`$419e6`), then `$43dc8` is decremented (`$419fa`) and
  displayed. On zero (`$41a08`), if `$43dd8`==2 (two players) the players toggle and the
  counter is reloaded with 4, frames with `$77`. Init with 4 at `$40080`, `$403e8`, `$40d6e`;
  `$4038e` grants `($43dc8)+1` as bonus points.
- This is *not* the visible countdown; patching it had no effect (tested 2026-09-18).

Trainers (2026-09-18; config labels must not contain `:`, WHDLoad rejects the string):
- Custom1 "Double time limit": `PL_W $1a60,10` (5 frames per tick -> 10, so the displayed
  time runs at half speed)
- Custom2 "No time limit": `PL_NOP $a14,4` (both `sbcd` removed, the display stays at the
  initial value and the time out check at `$4077e` never triggers)
- Both verified by the user with v1 and v2 (2026-09-18).
- With a trainer enabled nothing is saved: `_start` reads `WHDLTAG_CUSTOM1_GET`/
  `WHDLTAG_CUSTOM2_GET` via `resload_Control` into `_custom1`/`_custom2`, and `_save`
  returns success without calling `resload_SaveFile` if one of them is set (`HIGH` is the
  only file the game ever saves).

## Keyboard

- `STARTUP` `$3012` calls `$38a2`: installs level 2 handler `$38bc` into `$68`, INTENA `$c008`.
- Handler: reads SDR, reads ICR (not tested), acks PORTS, CRA=`$41`, **writes the raw byte
  back into SDR**, handshake delay `500x dbf` (far too short on fast CPUs), CRA=`$01`.
- `GAME`/`MAP` poll `$bfec01` directly in raw SDR format (not inverted/rotated, e.g. `$75` =
  Esc down, `$77` = Return down, `btst #0` = key down) and `clr.b $bfec01` after use; `GAME`
  `$4180a` and `MAP` `$40a92` read the byte for name input. SDR acts as one byte key buffer.
- SDR address field occurrences: `GAME` 45, `MAP` v1 17, `MAP` v2 17 (all code, verified by
  disassembly). `STARTUP` `$390c` `move.w #$7ff7,intena` clears INTEN. No other writes to `$68`,
  INTENA or CIA-A control registers in `STARTUP`/`GAME`/`MAP`/`AAE`/`LASERSOFT`/`LINVARA`
  (`LASERSOFT` sets `$80`/`$6c` only).

## GAME interrupt handling

- `GAME` entry `$40000` calls `$421da`: saves `($6c)` into the `jmp` at `$41a7a`, sets
  `($a0)=-1` and installs its level 3 handler `$4199c` (chains to the old vector).
- `$421fe` restores `($6c)`; called at `$40aca`, `$40aec`, `$40e14` (exit paths).
- `GAME` also polls CIA-A SDR directly for keys (`$bfec01`, e.g. `$75` = ESC -> exit).

## Access fault 2026-09-15 (v1, WHDLoad dump)

- `Access Fault` at PC `$420fa` (`MAP` loaded to `$40000`, inside the trace-obfuscated
  stubs), SR `$2704` without trace, reading `$4e7523f9`.
- Stack: interrupt frames with vector `$6c`, return `$419a4`, return `$3376` in `STARTUP`
  (right after `jsr -6(a6)` loading `MAP` at `$3372`, which follows `jsr $40000` of `GAME`).
- Memory: `($6c)=$4199c` = `GAME` VBL handler, `($a0)=$ffffffff`, `$41278` still unpatched
  (the load was in progress), CIA-B `ta=$ffff`.
- So when `GAME` returned to `STARTUP` the level 3 vector still pointed into `GAME`; the VBL
  interrupt ran into the new `MAP` data during/after loading. Most likely a consequence of the
  failing TAHI checks (inconsistent exit path); the exact path was not identified.
- Fix: slave sets CIA-B timer A like the loader. Verified 2026-09-15: access fault gone.

## Imager (`linwuschallenge.islave.asm`)

- Tracklist: 1 (`_decodedir`), 2-63 (`_decode`, checks sector number and checksum of all
  23 sectors), 78-79 standard.
- `_files` (DiskCode) reads the directory, follows the block chains and saves all files;
  files whose chain leaves tracks 2-63 are skipped with a message (`GANE`).
- Tracks 78-79 (`loader`) are not read and not saved, `CP` is not saved (both are
  provided by the slave). Last file written is `HIGH` (`inst/install.prep` last-file).
- RawDIC is always run manually by the user (with `Input=` wwp image).

## Slave (`linwuschallenge.asm`)

- Releases: **1.0** (19.09.2026, slave MD5 `17d3c2c30df2e6a90d9b256f2d8a87f2`) is published
  on whdload.de (`wget whdload.de/games/LinWusChallenge.lha` shows what is out there);
  everything after it goes into **1.1** (english release support).
- Version handling (2026-09-19): the patch list for `STARTUP` is chosen by its length
  (4840 = v3 -> `_pl_startup3`, else `_pl_startup`), the files loaded to `$40000` by their
  length: 15858 = `GAME` v3 -> `_pl_game`, 15850 = `GAME` v1/v2 -> `_pl_game12` (the
  checksum patch, ends with `PL_NEXT _pl_game`, so one `resload_Patch` call is enough),
  22925 -> `_pl_map1`, 20301 -> `_pl_map2`, 20297 -> `_pl_map3` (v3).
- No `loader`: `($c0)` points to `_libbase` inside the slave; jump table entries are 6
  bytes (`illegal`/`bra` + 0 padding): -6 `_load`, -$c `_save`, rest illegal.
- `_load`: `resload_LoadFile`, PP20 decrunch like the library (tested in Musashi against
  all 32 PP20 files), returns d0=0, d1=length, a0="OK", preserves d2-d7/a1-a6.
- `CP` is never loaded: `_load` copies `_cp` (v2 behaviour: `clr.l $84`,
  `move.l #$500,$88`, `rts`) to the load address.
- v1 `MAP` (22925 bytes, loaded to `$40000`) gets `PL_R $1278` (disk check).
- Start: INTENA/INTREQ/DMACON/ADKCON `$7fff`, DMACON `$83f0`, BPLCON0 `$200`, load
  `STARTUP` to `$3000`, `lea $80000,a7`, SR `$2000`, `jmp $3000`.
- Before starting: CIA-B TALO=`$aa`, TAHI=`$e1` (checked by `GAME`).
- Keyboard (2026-09-15): `whdload/keyboard.s` (`_SetupKeyboard` at start), `_key_check`
  converts the rawkey back to SDR format (`not(rol(rawkey))`) into `_keybuf`.
  `_pl_startup`: `PL_R $8a2` (no own handler), `PL_W $90e,$3ff7` (keep INTEN/PORTS).
  `_pl_game`/`_pl_map1`/`_pl_map2`: every `$00bfec01` address field -> `_keybuf` (`PL_L`),
  offsets generated by scanning the unpacked files. Files at `$40000` identified by length
  (`GAME` 15850, `MAP` 22925/20301).
- Snoop (2026-09-15): `STARTUP` `$36d8` (motor off/deselect) and `$3716` (motor on/select DF0,
  `bclr #7/#3,$bfd100`) wrap every library call; floppy access faults under Snoop ->
  `PL_R $6d8`, `PL_R $716`. Same pair in `MAP` around `HIGH` load/save: v1 `$42614` (off)/
  `$4264e` (on), v2 `$41bd4`/`$41c0e` -> `PL_R`. `MAP` v2 `$40838` also calls `$4168c`
  (motor on/select) and `$416a6` (step head until /TRK0, would loop without selected drive)
  at game start (replaces the v1 disk check) -> both `PL_R`. `MAP` v1 `$41200`/`$4121a` belong
  to the disabled disk check. `GAME` `$41924-$41999` (motor/select/seek) is dead code (only
  self-referenced), not patched.
- Globals in base memory (`STRUCTURE globals,$100`): `_resload` `$100`, `_keybuf` `$104`
  (area of the original library, unused by the game; keyboard.s references `_resload`
  absolute, so it lives there to keep the slave PC-relative).
- Flags `WHDLF_EmulTrap|WHDLF_NoError|WHDLF_ClearMem`, BaseMem `$80000`, PC-relative.
- WHDLoad dumps on the Amiga: `temp:.whdl/.whdl_register` (appended, search
  "LinWusChallenge.Slave"), `.whdl_memory` (chip memory, read ranges with ARexx `seek`).
- Status 2026-09-15: game runs, keyboard works well with the rework (confirmed by the user).

## Tools and methods that worked

- **vAmiga** 4.5 (`~/Desktop/vAmiga.app`) for cycle-exact 68000/copper timing: RetroShell
  server on TCP 8080, enabled by `ENABLE0=1` in `[SRV]` of `vAmiga.ini` (quit vAmiga before
  editing). Consoles `commander` (`mem load rom`, `df0 insert`, `amiga reset`) and
  `debugger` (`break at`, `g`, `s`, `r`, `m.w`, `d`, `?`). The loader analysis was done
  with 2.6.1 (script `.ini` with `server rshell start`, debug mode via `.`). Musashi (machine68k from amitools) and unicorn do not emulate
  trace exceptions / timing; unicorn caches translated code (breaks self-modifying code).
- **WWarp**: tracks 1-63 are raw single-revolution captures without sync; to extract
  them set sync and length on a copy: `wwarp x.wwp Y 1-63 2245`, `L 1-63 $3000`, `S n`.
- **Getting files from the Amiga to the Mac**: `type <file> HEX` in amiga_shell; large
  output is saved to a local tool-results file, parse offset/hex columns (35 chars wide).
  Verify with `md5sum` on the Amiga. Base64 via `amiga_write_file` works for small binaries.
- **ARexx pitfalls**: `d2c(v,4)` corrupts values >= `$80000000` (looked like broken
  sector headers), `c2b()` fails on inputs of a few hundred bytes, no `x2b()`.
- IRA on the Mac (`ira -M68000 -OLDSTYLE -BINARY -OFFSET=$... -PREPROC [-A]`); each run
  needs its own directory because the `.cnf` file name ignores the output name.
