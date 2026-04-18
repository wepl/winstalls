# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of **WHDLoad install sources** — 68000 assembly-language packages that allow classic Amiga games and applications to run from hard disk. Each subdirectory under `games/`, `apps/`, `ctros/`, and `misc/` is a self-contained installer.

## Build Commands

Run from any game/app directory or the top-level:

```sh
make          # Build the Slave executable (default)
make img      # Build the RawDIC ISlave (disk imager)
make dest     # Copy Slave/ReadMe to install directory for testing
make inst     # Build full install package
make arc      # Build distributable .lha archive
make rel      # Upload archive to release location (requires ssh config)
make clean    # Remove all generated artifacts
make get      # Download existing package from WHDLoad website
```

**Dependencies**: GNU Make, `vasm` (Motorola syntax, cross-platform assembler), `lha`, optional `basm` (legacy Amiga assembler with debug symbols).

Debug mode: set `DBG=1` on the make command line.

## Architecture

### Build system

- `Makemacros` — central macro hub included by every subdirectory Makefile; defines all compilation rules, install package creation, archive generation, and timestamp restoration
- `Maketools` — platform detection (Amiga vs. Linux/macOS via Vamos); sets `ASM`, `CP`, `LHA`, `DATE`, etc. appropriately
- Each game `Makefile` is minimal — usually just sets a few variables (`SLAVE`, `INSTFILES`, `DEST`) and includes `Makemacros`

### Slave sources (`.asm` files)

Every Slave source follows a standard structure:
1. Include `whdload.i` (main WHDLoad framework interface, `include/whdload.i`)
2. `#define` feature flags (`BOOTDOS`, `HDINIT`, `IOCACHE`, `SEGTRACKER`, etc.)
3. Declare memory sizes (`CHIPMEMSIZE`, `FASTMEMSIZE`)
4. Implement optional callbacks for disk/keyboard/DOS emulation
5. Apply game-specific patches

### Install packages (`inst/` subdirectory)

- `install.prep` — template variables and functions processed by `bin/mkinstall` to generate the Amiga Installer script
- `inst/Install` (top-level) — master 43 KB installer template; individual `install.prep` files inject game-specific content
- Icon metadata files: `.inf`, `.romicon`, `.newicon`, `.colexot`

### Key directories

| Path | Purpose |
|------|---------|
| `include/whdload/` | WHDLoad framework assembly includes (kick ROMs, file system emulation) |
| `include/whdload.i` | Main WHDLoad interface (38 KB) |
| `sources/` | Shared assembly utility modules |
| `bin/` | Perl/shell build helpers (`mkinstall`, `mkinfo`, `updutime`) |
| `inst/` | Master install template and icon resources |
| `misc/` | Reusable assembly modules (68060 emulation, joystick, IRQ rerouting, etc.) |

### Cross-platform note

`Maketools` transparently switches between native Amiga tools and host-side equivalents (vasm, standard POSIX commands). The same Makefiles work on both platforms without modification.
