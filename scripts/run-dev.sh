#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
source "$script_dir/codex-env.sh"

runtime_dir=${1:-"$repo_root/build/linux-runtime"}
if [[ $# -gt 0 ]]; then
  shift
fi

app_dir="$runtime_dir/app"
bin_dir="$runtime_dir/bin"
entry_script=${CODEX_ELECTRON_ENTRY:-"$repo_root/scripts/electron-entry.cjs"}

if [[ ! -d "$app_dir" ]]; then
  echo "Runtime app directory not found: $app_dir" >&2
  exit 1
fi
if [[ ! -f "$entry_script" ]]; then
  echo "Electron entry script not found: $entry_script" >&2
  exit 1
fi

electron_bin=${ELECTRON_BIN:-}
if [[ -z "$electron_bin" ]]; then
  for candidate in \
    "$repo_root/build/native-rebuild/node_modules/electron/dist/electron" \
    /usr/bin/electron40 \
    /usr/bin/electron; do
    if [[ -x "$candidate" ]]; then
      electron_bin="$candidate"
      break
    fi
  done
fi

if [[ -z "$electron_bin" ]]; then
  echo "Unable to locate Electron. Set ELECTRON_BIN." >&2
  exit 1
fi

codex_validate_electron "$electron_bin" 143 || {
  echo "Use this script without overriding ELECTRON_BIN, or point ELECTRON_BIN to Electron 40." >&2
  exit 1
}

codex_setup_env "$app_dir" "$bin_dir"
codex_exec "$electron_bin" "$entry_script" "$@"
