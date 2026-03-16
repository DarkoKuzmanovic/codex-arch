#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

requested_version=${1:-${CODEX_CLI_VERSION:-}}
out_dir=${2:-"$repo_root/build/codex-vendor"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd node
require_cmd npm

existing_vendor_pkg="$out_dir/node_modules/@openai/codex-linux-x64/package.json"

read_existing_version() {
  local package_json=$1
  if [[ -f "$package_json" ]]; then
    node - "$package_json" <<'NODE'
const fs = require("fs");
const packagePath = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const version = String(pkg.version ?? "").replace(/-linux-x64$/, "");
if (version) {
  process.stdout.write(version);
}
NODE
  fi
}

read_codex_binary_version() {
  local codex_bin=$1
  if [[ -x "$codex_bin" ]]; then
    "$codex_bin" --version 2>/dev/null | sed -n 's/^codex-cli //p' | head -n 1
  fi
}

resolved_version=$requested_version
if [[ -z "$resolved_version" ]]; then
  resolved_version=$(read_existing_version "$existing_vendor_pkg")
fi
if [[ -z "$resolved_version" ]]; then
  resolved_version=$(read_codex_binary_version "$repo_root/build/linux-runtime/bin/codex")
fi
if [[ -z "$resolved_version" ]]; then
  resolved_version=$(read_codex_binary_version "$(command -v codex 2>/dev/null || true)")
fi

if [[ -z "$resolved_version" ]]; then
  echo "Unable to infer a Linux Codex CLI version." >&2
  echo "Set CODEX_CLI_VERSION or pass a version argument, for example: 0.114.0" >&2
  exit 1
fi

current_version=$(read_existing_version "$existing_vendor_pkg")
if [[ "${FORCE_VENDOR_FETCH:-0}" != "1" && "$current_version" == "$resolved_version" ]]; then
  echo "Reusing existing Linux Codex vendor payload at version $resolved_version"
  exit 0
fi

package_spec="@openai/codex-linux-x64@npm:@openai/codex@${resolved_version}-linux-x64"

rm -rf "$out_dir"
mkdir -p "$out_dir"

pushd "$out_dir" >/dev/null
npm init -y >/dev/null
npm install --no-package-lock --no-save "$package_spec"
popd >/dev/null

echo "Fetched Linux Codex vendor payload version $resolved_version into $out_dir"
