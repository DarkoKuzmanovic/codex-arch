# Codex Linux Port Scaffold

This repo now contains a reproducible scaffold for turning the shipped macOS `Codex.dmg` into an unofficial Arch/EndeavourOS-friendly Electron app directory.

What this repo does:

- Extracts the Electron app from `Codex.dmg`
- Recovers the packaged JavaScript bundle from `app.asar`
- Stages a Linux runtime directory that can be launched with Electron 40
- Rebuilds the Linux native modules that the macOS bundle cannot use directly
- Optionally stages Linux `codex` and `rg` binaries next to the app

What this repo does not do:

- Recreate OpenAI's original source tree
- Produce an officially supported Linux release
- Avoid the need for a Linux `codex` backend binary

## Runtime Facts Recovered From The Bundle

- The app is Electron-based.
- The packaged app version is `26.311.21342`.
- The bundle expects Electron `40.x`.
- On Linux, the desktop app can use `CODEX_CLI_PATH` to locate the backend `codex` binary.
- If `CODEX_CLI_PATH` is unset, the app falls back to bundled `codex` locations.
- The app adds a bundled `rg` directory to `PATH` when present, but system `ripgrep` also works.
- Sparkle auto-update is already disabled on non-macOS platforms.

## Recommended Flow

1. Import the DMG into a Linux-friendly working tree.
2. Stage a runtime directory.
3. Rebuild `better-sqlite3` and `node-pty` for Linux.
4. Provide a Linux `codex` binary with `CODEX_CLI_PATH` or stage one into `build/linux-runtime/bin/codex`.
5. Launch the app with Electron 40.

## Commands

Import the DMG:

```bash
bash scripts/import-codex-dmg.sh
```

Stage the Linux runtime:

```bash
bash scripts/stage-linux-runtime.sh
```

Rebuild native modules for Linux:

```bash
bash scripts/rebuild-linux-natives.sh build/linux-runtime/app
```

Run locally:

```bash
bash scripts/run-dev.sh
```

If you already have a Linux Codex CLI installed:

```bash
CODEX_CLI_PATH="$(command -v codex)" ELECTRON_BIN=/usr/bin/electron40 bash scripts/run-dev.sh
```

If you want the staging step to copy local binaries into the runtime:

```bash
CODEX_LINUX_BIN="$(command -v codex)" RG_BIN="$(command -v rg)" bash scripts/stage-linux-runtime.sh
```

Fetch or refresh the Linux Codex vendor payload:

```bash
bash scripts/fetch-codex-vendor.sh 0.114.0
```

Update the port when a new `Codex.dmg` release lands:

```bash
bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

Do not launch the extracted app with a generic `electron` package such as `/usr/bin/electron` if it reports `NODE_MODULE_VERSION 140`.
This bundle expects Electron `40.x` and `NODE_MODULE_VERSION 143`, so the supported launcher path is `bash scripts/run-dev.sh` or a wrapper that targets `electron40`.

## Arch Notes

- The wrapper in [packaging/codex-desktop](/home/quzma/source/codex-arch/packaging/codex-desktop) prefers a bundled Electron 40 runtime and falls back to `/usr/bin/electron40` if needed.
- The package wrapper now validates the Electron ABI before launch and uses the same entry script as the working dev runtime.
- On Wayland sessions, the launcher defaults to `ELECTRON_OZONE_PLATFORM_HINT=x11` for more stable Plasma behavior. Override with `CODEX_OZONE_PLATFORM=wayland` if you want to test native Wayland again.
- The template [PKGBUILD](/home/quzma/source/codex-arch/PKGBUILD) assumes a local, unofficial package build from the checked-out repo and current `Codex.dmg`.
- The package installs a `codex-desktop` launcher, desktop entry, and application icon for Plasma/KDE menus.
- `scripts/rebuild-linux-natives.sh` downloads npm packages during the rebuild step. That is acceptable for a local packaging workflow, but not a polished reproducible distro package yet.
- You still need `asar` on `PATH` for the import step.

Build and install locally:

```bash
makepkg -f
sudo pacman -U ./codex-desktop-bin-$(sed -n 's/^pkgver=//p' PKGBUILD)-1-x86_64.pkg.tar.zst
```

## Update Workflow

You do not need to re-port the app from scratch for each release.
The expected maintenance model is to rerun the packaging pipeline against the new `Codex.dmg`.

Recommended update command:

```bash
bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

What that script does:

- Copies the new DMG into the repo as `Codex.dmg`
- Imports the new app bundle and extracts its packaged metadata
- Syncs `pkgver` in [PKGBUILD](/home/quzma/source/codex-arch/PKGBUILD)
- Refreshes `build/codex-vendor`
- Restages `build/linux-runtime`
- Builds a fresh Arch package with `makepkg -f`

If you want the script to launch the staged runtime briefly before packaging, enable the smoke test:

```bash
SMOKE_TEST=1 bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

Two practical notes:

- The Linux Codex CLI vendor version is not exposed clearly by the desktop DMG today, so the updater reuses the currently staged CLI version by default.
- If an upstream release requires a different CLI build, rerun the updater with an explicit override such as `CODEX_CLI_VERSION=0.115.0 bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg`.

## Key Paths

- Imported app tree: `build/imported/app`
- Staged Linux runtime: `build/linux-runtime`
- Wrapper script: [packaging/codex-desktop](/home/quzma/source/codex-arch/packaging/codex-desktop)
- Desktop file: [packaging/codex-desktop.desktop](/home/quzma/source/codex-arch/packaging/codex-desktop.desktop)
- Maintenance notes: [NOTES.md](/home/quzma/source/codex-arch/NOTES.md)
