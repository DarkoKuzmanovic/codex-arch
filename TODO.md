# TODO

## Sprint 1 — Reduce duplication and improve DX

- [ ] Extract shared `require_cmd()` and `script_dir`/`repo_root` boilerplate into `scripts/common.sh`, sourced by all scripts
- [ ] Add `--help` / `-h` support to all scripts with brief usage messages

## Sprint 2 — Build reliability

- [ ] Add `asar --version` minimum version check in `import-codex-dmg.sh`
- [x] Add SHA256 verification of `Codex.dmg` before import (optional `CODEX_DMG_SHA256` env var)
- [ ] Cache native rebuild output — skip `rebuild-linux-natives.sh` if `.node` files already match target versions

## Sprint 3 — Package cleanup

- [ ] Strip macOS-only artifacts from staged runtime (`darwin-arm64` binaries, `sparkle.node`) to reduce package size
