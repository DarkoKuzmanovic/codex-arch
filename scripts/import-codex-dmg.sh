#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

dmg_path=${1:-"$repo_root/Codex.dmg"}
out_dir=${2:-"$repo_root/build/imported"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd 7z
require_cmd asar
require_cmd node

if [[ ! -f "$dmg_path" ]]; then
  echo "DMG not found: $dmg_path" >&2
  exit 1
fi

if [[ -n "${CODEX_DMG_SHA256:-}" ]]; then
  actual_sha256=$(sha256sum "$dmg_path" | awk '{print $1}')
  if [[ "$actual_sha256" != "$CODEX_DMG_SHA256" ]]; then
    echo "DMG checksum mismatch" >&2
    echo "  expected: $CODEX_DMG_SHA256" >&2
    echo "  actual:   $actual_sha256" >&2
    exit 1
  fi
  echo "DMG checksum verified"
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/codex-dmg-XXXXXX")
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "Extracting $dmg_path"
7z x -y "$dmg_path" "-o$tmp_dir" >/dev/null

app_bundle=$(find "$tmp_dir" -maxdepth 4 -type d -name "Codex.app" | head -n 1)
if [[ -z "$app_bundle" ]]; then
  echo "Unable to locate Codex.app inside extracted DMG" >&2
  exit 1
fi

resources_dir="$app_bundle/Contents/Resources"
info_plist="$app_bundle/Contents/Info.plist"
app_asar="$resources_dir/app.asar"
app_asar_unpacked="$resources_dir/app.asar.unpacked"

if [[ ! -f "$app_asar" ]]; then
  echo "Missing app.asar at $app_asar" >&2
  exit 1
fi

if [[ -z "$out_dir" || "$out_dir" != "$repo_root"/* ]]; then
  echo "Refusing to clean unsafe path: ${out_dir:-<empty>}" >&2
  exit 1
fi
rm -rf "$out_dir"
mkdir -p "$out_dir/app" "$out_dir/raw" "$out_dir/macos" "$out_dir/icons" "$out_dir/metadata"

echo "Recovering packaged Electron app"
cp "$app_asar" "$out_dir/raw/app.asar"
if [[ -d "$app_asar_unpacked" ]]; then
  cp -R "$app_asar_unpacked" "$out_dir/raw/app.asar.unpacked"
fi
if [[ -f "$resources_dir/codex" ]]; then
  cp "$resources_dir/codex" "$out_dir/macos/codex-darwin-arm64"
fi
if [[ -f "$resources_dir/rg" ]]; then
  cp "$resources_dir/rg" "$out_dir/macos/rg-darwin-arm64"
fi
if [[ -f "$resources_dir/electron.icns" ]]; then
  cp "$resources_dir/electron.icns" "$out_dir/icons/electron.icns"
fi
cp "$info_plist" "$out_dir/metadata/Info.plist"

asar extract "$app_asar" "$out_dir/app"

node - "$out_dir/app/package.json" "$out_dir/metadata/import-summary.json" <<'NODE'
const fs = require("fs");

const packagePath = process.argv[2];
const outputPath = process.argv[3];
const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));

const summary = {
  name: pkg.name,
  productName: pkg.productName,
  version: pkg.version,
  electronVersion: pkg.devDependencies?.electron ?? null,
  buildFlavor: pkg.codexBuildFlavor ?? null,
  buildNumber: pkg.codexBuildNumber ?? null,
  betterSqlite3Version: pkg.dependencies?.["better-sqlite3"] ?? null,
  nodePtyVersion: pkg.dependencies?.["node-pty"] ?? null,
};

fs.writeFileSync(outputPath, JSON.stringify(summary, null, 2));
NODE

echo "Imported app into $out_dir"
echo "App directory: $out_dir/app"
