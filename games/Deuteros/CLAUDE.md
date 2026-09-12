# Deuteros — game internals & reverse-engineering notes

Working notes for debugging the WHDLoad slave `deuteros.asm`. Built up while
adding savedisk support (Sept 2026). Unless stated otherwise, addresses are
**runtime addresses**; the main exe is loaded to `$13000`.

## Versions and originals

| Version | Notes | Bootblock CRC (`$2c00`..`$5800` of Disk.1) | Main exe (Disk.1 offset `$6e000` -> `$13000`) |
|---|---|---|---|
| v1 | original, uses OS (trackdisk/input.device) | `$d84b` | `$6ca00` bytes |
| v2 | crack of v3, OS-less loader in bootblock | `$8ab8` | `$6bcfc` bytes |
| v3 | SPS original, same code as v2 (VER=2 too) | `$e6dd` | `$6bcfc` bytes |
| v4 | like v1, code shifted by -$e | `$a1cb` | `$6ca00` bytes |

- Original images and per-version test dirs on the Amiga: `wart:de/deuteros/data-v1..v4`
  (`Disk.1`, `Disk.2`, `Disk.3` savedisk, SAVEFILES dumps). Same images as
  `~/Downloads/Amiga/games-floppy-D-E/Deuteros.lha` (MD5-identical).
- ReSource disassemblies of the main exe: `cr:deuteros/v1/1-6e000-6ca00-13000.asm` and
  `cr:deuteros/v2 cracked v3/1-6e000-6bcfc-13000.asm` (1.5-1.7 MB; read with
  `Search`/`gawk "NR>=a && NR<=b"` via amiga_shell). Labels `lbC0NNNNN` are
  **file offsets**, i.e. runtime = label + `$13000`.
- WHDLoad dumps on the Amiga: `temp:.whdl/.whdl_register`, `.whdl_log` (append logs,
  search "Deuteros.Slave" for the last session).

## Address conventions in the slave

- `_plm1/_plm23/_plm4` are applied with `a1=$13000`, so **PL_ offsets are exe file
  offsets** and equal the ReSource labels (`PL_PS $25116` patches `$38116`).
- `_pl1/_pl23/_pl4` are bootblock patch lists, base `$12800` (v1/v4) or `$12500` (v23;
  the slave moves the v23 bootblock down by `$300`).
- Loading is 1:1: memory `$13000+x` = `Disk.1[$6e000+x]` (verified via MD5 of the
  SAVEFILES dumps). v4 main code = v1 code shifted by `-$e`; v2 differs more.

## Disk access

### v1/v4 (OS)
- All disk I/O via `trackdisk.device` `DoIO` (`ETD_READ $8002`, `ETD_WRITE $8003`,
  `ETD_UPDATE $8004`, `TD_FORMAT 11`, `TD_MOTOR 9`, `CMD_CLEAR 5`). Hooked by `_doio`.
- Keyboard via `input.device` handler installed once at start (`$1ed80`), no DoIO
  per key.
- v1 disk helpers (file offsets): `_diskload $d8c0`, write `lbC00D812`, write+update
  `lbC00D856/$d888`, format track `lbC00D966` (TD_FORMAT), motor off `lbC00D7F0`
  (ends with `moveq #0,d7`, so single-track read/write errors are swallowed).

### v2/v3 (bootblock loader)
- Bootblock at `$12500` builds a jump table at `$7fddc` (code at `$13000`):
  `$7fddc`=format `$126b6`, `$7fde0`=write `$1267e`, `$7fde4`=read `$1263c`,
  `$7fde8`=motor off `$125f0`, `$7fdec`=motor on `$125d2`, rest drive select/step.
- Convention for read/write: `d0`=length (bytes), `d1`=address, `d7`=start track,
  returns `d0`=error (0 ok, 2 write protected, 3 no disk), `d1-a6` preserved.
  The game always writes whole tracks. Format takes no parameters (80 tracks).
- Slave patches: `$13c` read -> `_diskload`, `$17e` write -> `_diskwrite`,
  `$1b6` format -> `_diskformat` (pretends success).
- Main exe wrappers: `diskload` (`$d63c`), write `lbC00D64A`, format `lbC00D674`.
- **Keyboard in v2 is polled via `keyboard.device` `KBD_READMATRIX` (cmd 10) through
  `DoIO` every loop** (`$1ef08`, matrix at `$1f02c`, ring buffer `$1eed0`). The `_doio`
  hook must pass non-trackdisk devices straight to the OS (checked via
  `IO_DEVICE`/`LN_NAME` = "trac"), otherwise keys die once ACTDISK=3.
- Overlays: v2 loads `$2880`-byte chunks to `$25398` (v1: `$1600` to `$256ce`,
  v4: `$256c0`). Bulk data `1-1b800-2f3f8-32f08` replaces v1's per-track loads.

## Savedisk (Disk.3)

- Disk id `$16C65710` at offset `$3fc` of track 0, read by `get_diskid`
  (reads `$400` from track 0). Data disk id `$8B632804`.
- Directory: `$100`/`$1600` bytes at track 50 (offset `$44c00`), entries
  "game 1".."game 5", `lbL024D82` (v2) / `lbL0251AA` (v1). 5 slots of 7 tracks
  (`$9392` bytes rounded up to `$9a00`) at tracks 60,80,100,120,140
  (`$52800,$6e000,$89800,$a5000,$c0800`), table `lbL024CA2` (v2) / `$250d0` (v1).
  Game state lives at `$13006..$1c398` (`$9392` bytes).
- `insert_save_disk` (v1 `$25116`, v4 `$25108`, v2 `$24cee`): `moveq #0,d0; tst.b;
  jsr get_diskid; cmp.l #$16C65710,d0; beq +; ...; moveq #1,d0` at routine+`$1a`.
  Slave: `PL_PS` + `_disk3` (`ACTDISK=3`, return address +`$14` -> `moveq #1,d0`).
- Save flow (v2 `lbC0250xx`): `insert_save_disk`, message `$14c` "press S", wait for
  `S`/`s` (`lbC024F50`), write state, write directory (`lbC024E7A`), then
  `insert_data_disk` -> slave `_disk2` (`ACTDISK=2`).
- Format dialog (v1 `$2567c`, v2 `$2527e`, menu jump table entry): asks F, then
  `lbC0257A0` formats 160 tracks via TD_FORMAT (v1) / bootblock format (v2), writes
  the id (`lbC00D9D2`/`lbC00D6B0`) and the directory. Slave `PL_R`s the dialog.
- `SIZE3` = current size of Disk.3; `_diskload`/`_doio` return zeros for reads beyond
  it (`.clr`), and skip `_patchfiles` (so no SAVEFILES dump appears for those reads).
  `_diskwrite` must grow `SIZE3` by offset+length (`resload_SaveFileOffset` returns
  only BOOL in d0 -- keep the length in another register). Its result need not be
  checked: `WHDLF_NoError` makes WHDLoad abort on any resload error, a missing
  `Disk.3` is not an error (`resload_GetFileSize` returns 0).

## Patch table (`_patchfiles`, keyed by disk,length,data,offset)

- v1/v4 `.base`: main first load; bootblock two-part reload after "reaching stars"
  (`1,$55400,$1e000,$79000`); intro `1,$4200,$20000,$5800` (access fault, `ret $2080c`);
  stars `2,$4200,$20000,$5800`; late `2,$1600,$256ce/$256c0,$25200`.
- v2/v3 `.base23` (offsets relative to `.base23`!): same reload (v2 bootblock `$12f28`
  loads `$b000`@track80 then `$55400`@track88, copying the game state
  `$66000->$13006` in between); stars patch site `$20842`, pointers `$2186a/$2186e`
  (v1: `$2085c`, `$2174c/$21750`); intro patch not needed for v2/v3.
- "reaching stars" file returns to the bootblock (`$12800`/`$12500`) which reloads
  main, so `.af1/.af23` must set `ACTDISK=1` first.
- `.late` fix (`$ff0000 -> $20000` pointer, after loading a game): v1 `$7bb7a`,
  v4 `$7bbd2` = start of the data block at `$7a1ee`/`$7a246` + `$198c`. Same block in
  v2 at `$79a40` -> candidate `$7b3cc` (unverified; trigger `2,$2880,$25398,$25200`
  unverified). The address is never referenced literally, it is runtime data.
- Random fix: `lea $ff0000,a4` at `$3f764` (v1) / `$3f756` (v4) / `$3f35a` (v2),
  patched to `$20000`. Sound fix: `rts` at `$3fc0e/$3fc00/$3f804` skipped (`PL_S`).
