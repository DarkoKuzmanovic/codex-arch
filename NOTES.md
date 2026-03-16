# Linux Port Notes

This file is the short maintenance runbook for the unofficial Arch/EndeavourOS Codex port.

## Current Assumptions

- The desktop bundle is imported from `Codex.dmg`.
- The Linux package is built locally with `makepkg -f`.
- The package ships its own Electron 40 runtime.
- On Plasma/Wayland, the launcher defaults to X11 via `--ozone-platform=x11`.
- The Linux Codex CLI vendor payload is staged from `build/codex-vendor`.

## Release Update Checklist

When OpenAI ships a new `Codex.dmg`, run:

```bash
bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
pkexec pacman -U /home/quzma/source/codex-arch/codex-desktop-bin-$(sed -n 's/^pkgver=//p' /home/quzma/source/codex-arch/PKGBUILD)-1-x86_64.pkg.tar.zst
```

If the desktop release needs a different CLI build:

```bash
CODEX_CLI_VERSION=0.115.0 bash scripts/update-from-dmg.sh /path/to/new/Codex.dmg
```

## Verification

After a rebuild or reinstall, check:

- `codex-desktop` launches without the Electron ABI mismatch dialog.
- The app reaches the main UI and initializes the local app-server.
- Plasma groups the running window under the launcher icon.
- The titlebar/taskbar icon matches `Codex Desktop`.
- The packaged launcher does not emit the old Wayland color-management errors.

## Plasma Notes

- The desktop file is `codex-desktop.desktop`.
- KWin currently reports the running window as:
  - `resourceClass = Codex`
  - `resourceName = codex`
  - `desktopFile = codex-desktop`
- If the taskbar pin looks wrong after reinstalling, remove the old pinned icon, launch the app fresh from Application Launcher, and pin it again.
- If Plasma still uses stale launcher metadata, log out and back in once.

## Known Limitations

- The upstream DMG does not expose the matching Linux Codex CLI vendor version clearly.
- The updater script reuses the staged Linux CLI version by default.
- `scripts/rebuild-linux-natives.sh` still depends on npm downloads during rebuild.
