#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

import_dir=${1:-"$repo_root/build/imported"}
runtime_dir=${2:-"$repo_root/build/linux-runtime"}

app_source="$import_dir/app"

if [[ ! -d "$app_source" ]]; then
  echo "Imported app directory not found: $app_source" >&2
  exit 1
fi

rm -rf "$runtime_dir"
mkdir -p "$runtime_dir"

cp -R "$app_source" "$runtime_dir/app"

if [[ -f "$import_dir/icons/electron.icns" ]]; then
  mkdir -p "$runtime_dir/icons"
  cp "$import_dir/icons/electron.icns" "$runtime_dir/icons/electron.icns"
fi

mkdir -p "$runtime_dir/bin"

codex_source=${CODEX_LINUX_BIN:-${CODEX_CLI_PATH:-}}
if [[ -z "$codex_source" ]]; then
  for candidate in \
    "$repo_root/build/codex-vendor/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex/codex"; do
    if [[ -x "$candidate" ]]; then
      codex_source="$candidate"
      break
    fi
  done
fi
if [[ -n "$codex_source" ]]; then
  install -m 755 "$codex_source" "$runtime_dir/bin/codex"
fi

vendor_source=${CODEX_VENDOR_DIR:-}
if [[ -z "$vendor_source" ]]; then
  fallback_vendor="$repo_root/build/codex-vendor/node_modules/@openai/codex-linux-x64/vendor"
  if [[ -d "$fallback_vendor" ]]; then
    vendor_source="$fallback_vendor"
  fi
fi
if [[ -n "$vendor_source" && -d "$vendor_source" ]]; then
  mkdir -p "$runtime_dir/vendor"
  cp -a "$vendor_source"/. "$runtime_dir/vendor/"
fi

rg_source=${RG_BIN:-}
if [[ -z "$rg_source" ]]; then
  vendor_rg="$repo_root/build/codex-vendor/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/path/rg"
  if [[ -x "$vendor_rg" ]]; then
    rg_source="$vendor_rg"
  fi
fi
if [[ -z "$rg_source" ]] && command -v rg >/dev/null 2>&1; then
  rg_source=$(command -v rg)
fi
if [[ -n "$rg_source" ]]; then
  install -m 755 "$rg_source" "$runtime_dir/bin/rg"
fi

echo "Staged Linux runtime at $runtime_dir"
if [[ ! -x "$runtime_dir/bin/codex" ]]; then
  echo "No Linux codex binary staged. Use CODEX_CLI_PATH or CODEX_LINUX_BIN." >&2
fi
