# Codex Linux Port Design

## Goal

Recover enough of the macOS Codex desktop bundle to run it on Arch-based Linux with a maintainable, repeatable workflow.

## Constraints

- The only input artifact is `Codex.dmg`.
- The shipped bundle is Electron, but it contains macOS ARM64 native binaries.
- The packaged JavaScript is recoverable from `app.asar`.
- Linux still needs rebuilt native addons for `better-sqlite3` and `node-pty`.
- The desktop app needs a Linux `codex` backend binary.

## Recommended Architecture

Use the recovered Electron app directory as the canonical Linux app payload, not the macOS `.app` layout.

The port flow is:

1. Extract `app.asar` and `app.asar.unpacked` from the DMG.
2. Convert the recovered app into a normal Electron app directory.
3. Rebuild native addons for Linux against Electron `40.x`.
4. Launch with system `electron40` through a wrapper that sets `CODEX_CLI_PATH` and `PATH`.

## Why This Approach

- It is reproducible from the DMG.
- It avoids patching a minified macOS bundle in place.
- It separates import, native rebuild, and packaging.
- It matches how Arch packages many Electron applications: a system Electron binary plus an app directory payload.

## Known Gaps

- The workflow still depends on a Linux `codex` binary.
- The native rebuild currently downloads npm packages.
- The app icon is still macOS-native `.icns`.
- The PKGBUILD is a local packaging template, not a polished AUR-ready package.

