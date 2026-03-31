#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

dmg_path=${1:-"$repo_root/Codex.dmg"}
canonical_dmg="$repo_root/Codex.dmg"
import_dir=${IMPORT_DIR:-"$repo_root/build/imported"}
runtime_dir=${RUNTIME_DIR:-"$repo_root/build/linux-runtime"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd makepkg
require_cmd node
require_cmd timeout

if [[ ! -f "$dmg_path" ]]; then
  echo "DMG not found: $dmg_path" >&2
  exit 1
fi

if [[ "$dmg_path" != "$canonical_dmg" ]]; then
  cp -f "$dmg_path" "$canonical_dmg"
  dmg_path="$canonical_dmg"
  echo "Copied DMG into $canonical_dmg"
fi

bash "$repo_root/scripts/import-codex-dmg.sh" "$dmg_path" "$import_dir"

import_summary="$import_dir/metadata/import-summary.json"
if [[ ! -f "$import_summary" ]]; then
  echo "Import summary not found: $import_summary" >&2
  exit 1
fi

app_version=$(
  node - "$import_summary" <<'NODE'
const fs = require("fs");
const summaryPath = process.argv[2];
const summary = JSON.parse(fs.readFileSync(summaryPath, "utf8"));
if (!summary.version) {
  process.exit(1);
}
process.stdout.write(String(summary.version));
NODE
)

if [[ ! "$app_version" =~ ^[a-zA-Z0-9][a-zA-Z0-9._]*$ ]]; then
  echo "Imported version string is not a valid Arch pkgver: $app_version" >&2
  exit 1
fi

node - "$repo_root/PKGBUILD" "$app_version" <<'NODE'
const fs = require("fs");
const pkgbuildPath = process.argv[2];
const version = process.argv[3];
const previous = fs.readFileSync(pkgbuildPath, "utf8");
const match = previous.match(/^pkgver=(.*)$/m);
if (!match) {
  console.error("Unable to locate pkgver in PKGBUILD");
  process.exit(1);
}
const next = previous.replace(/^pkgver=.*/m, `pkgver=${version}`);
fs.writeFileSync(pkgbuildPath, next);
NODE

echo "Synced PKGBUILD to Codex version $app_version"

bash "$repo_root/scripts/fetch-codex-vendor.sh" "${CODEX_CLI_VERSION:-}"
bash "$repo_root/scripts/stage-linux-runtime.sh" "$import_dir" "$runtime_dir"

if [[ "${SMOKE_TEST:-0}" == "1" ]]; then
  bash "$repo_root/scripts/rebuild-linux-natives.sh" "$runtime_dir/app"
  smoke_timeout=${SMOKE_TIMEOUT:-20s}
  set +e
  timeout "$smoke_timeout" bash "$repo_root/scripts/run-dev.sh" "$runtime_dir"
  smoke_status=$?
  set -e
  if [[ $smoke_status -ne 0 && $smoke_status -ne 124 ]]; then
    echo "Smoke test failed with exit code $smoke_status" >&2
    exit $smoke_status
  fi
  echo "Smoke test completed with timeout status $smoke_status"
fi

if [[ "${BUILD_PACKAGE:-1}" == "1" ]]; then
  makepkg -f
fi

pkgrel=$(
  sed -n 's/^pkgrel=//p' "$repo_root/PKGBUILD" | head -n 1
)
package_path="$repo_root/codex-desktop-bin-${app_version}-${pkgrel}-x86_64.pkg.tar.zst"

echo "Update pipeline complete for Codex $app_version"
if [[ -f "$package_path" ]]; then
  echo "Package ready: $package_path"
  echo "Install with: pkexec pacman -U $package_path"
fi
