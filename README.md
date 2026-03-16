# codex-arch

Unofficial Arch Linux packaging scaffold that turns the macOS `Codex.dmg` into a working Electron desktop app on Arch-based distros (EndeavourOS, Manjaro, etc.).

## What it does

- Extracts the Electron app from `Codex.dmg` via `app.asar`
- Rebuilds `better-sqlite3` and `node-pty` native modules for Linux
- Stages a Linux runtime directory launchable with Electron 40
- Packages everything into an installable Arch package via `makepkg`
- Provides a desktop launcher with Plasma/KDE integration

## What it does not do

- Recreate OpenAI's original source tree
- Produce an officially supported Linux release
- Remove the need for a Linux `codex` CLI backend binary

## Prerequisites

- Arch-based Linux (tested on EndeavourOS/Plasma)
- `nodejs`, `npm`, `p7zip`, `python`, `make`, `gcc`
- `asar` on `PATH` (`npm install -g @electron/asar`)
- `ripgrep` (system package)
- A copy of `Codex.dmg` from the macOS release

## Quick start

Place `Codex.dmg` in the repo root, then:

```bash
# Import, stage, rebuild, and package in one step
bash scripts/update-from-dmg.sh Codex.dmg

# Install the built package
sudo pacman -U ./codex-desktop-bin-*-x86_64.pkg.tar.zst
```

Or step by step:

```bash
bash scripts/import-codex-dmg.sh           # Extract app from DMG
bash scripts/stage-linux-runtime.sh         # Stage Linux runtime
bash scripts/rebuild-linux-natives.sh       # Rebuild native modules
bash scripts/run-dev.sh                     # Launch with Electron 40
```

## Providing the Codex CLI binary

The desktop app needs a Linux `codex` backend. Three options:

```bash
# Option 1: Fetch the vendor payload from npm
bash scripts/fetch-codex-vendor.sh 0.114.0

# Option 2: Point to an existing install
CODEX_CLI_PATH="$(command -v codex)" bash scripts/run-dev.sh

# Option 3: Copy a local binary into the staging area
CODEX_LINUX_BIN="$(command -v codex)" bash scripts/stage-linux-runtime.sh
```

## Building the Arch package

```bash
makepkg -f
sudo pacman -U ./codex-desktop-bin-$(sed -n 's/^pkgver=//p' PKGBUILD)-1-x86_64.pkg.tar.zst
```

The package installs:
- `/usr/bin/codex-desktop` launcher
- `/usr/lib/codex-desktop/` app payload, bundled Electron, and vendor binaries
- Desktop entry and icon for Plasma/KDE/GNOME menus

## Updating to a new release

```bash
bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

This re-imports the bundle, syncs `pkgver` in [PKGBUILD](PKGBUILD), refreshes the vendor payload, and rebuilds the Arch package. Add `SMOKE_TEST=1` to launch the app briefly before packaging.

If the new release needs a different CLI version:

```bash
CODEX_CLI_VERSION=0.115.0 bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

## Environment variables

| Variable | Purpose |
|----------|---------|
| `CODEX_CLI_PATH` | Path to a Linux `codex` binary |
| `CODEX_LINUX_BIN` | Alternative to `CODEX_CLI_PATH` for the staging step |
| `CODEX_CLI_VERSION` | Version to fetch from npm (e.g. `0.114.0`) |
| `ELECTRON_BIN` | Override the Electron binary path |
| `CODEX_OZONE_PLATFORM` | Set to `wayland` to use native Wayland instead of X11 |
| `SMOKE_TEST` | Set to `1` to run a brief launch test during updates |
| `RG_BIN` | Override the `ripgrep` binary staged into the runtime |

## Wayland / Plasma notes

The launcher defaults to `--ozone-platform=x11` on Wayland sessions for stability. To test native Wayland:

```bash
CODEX_OZONE_PLATFORM=wayland codex-desktop
```

## Key paths

| Path | Description |
|------|-------------|
| [`scripts/`](scripts/) | Import, staging, rebuild, and launcher scripts |
| [`scripts/codex-env.sh`](scripts/codex-env.sh) | Shared environment setup sourced by all launchers |
| [`packaging/codex-desktop`](packaging/codex-desktop) | Installed launcher wrapper |
| [`packaging/codex-desktop.desktop`](packaging/codex-desktop.desktop) | Desktop entry file |
| [`PKGBUILD`](PKGBUILD) | Arch package build template |
| [`NOTES.md`](NOTES.md) | Maintenance runbook |

## Runtime details

- The bundle expects Electron `40.x` (`NODE_MODULE_VERSION 143`). Do not use a generic `/usr/bin/electron` if it reports a different ABI.
- System `ripgrep` works fine; a bundled `rg` is optional.
- Sparkle auto-update is already disabled on non-macOS platforms.

## License

This is an unofficial community packaging effort. The Codex desktop app is proprietary software by OpenAI. This repo contains only the packaging scaffold, not the app itself.
