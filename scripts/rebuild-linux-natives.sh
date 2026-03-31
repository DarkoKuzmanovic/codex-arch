#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

app_dir=${1:-"$repo_root/build/linux-runtime/app"}
work_dir=${2:-"$repo_root/build/native-rebuild"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd node
require_cmd npm

package_json="$app_dir/package.json"
if [[ ! -f "$package_json" ]]; then
  echo "App package.json not found: $package_json" >&2
  exit 1
fi

mapfile -t resolved_versions < <(
  node - "$package_json" <<'NODE'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const normalize = (value) => String(value ?? "").replace(/^[^0-9]*/, "");
console.log(normalize(pkg.devDependencies?.electron));
console.log(normalize(pkg.dependencies?.["better-sqlite3"]));
console.log(normalize(pkg.dependencies?.["node-pty"]));
NODE
)

electron_version=${ELECTRON_VERSION:-${resolved_versions[0]}}
better_sqlite3_version=${BETTER_SQLITE3_VERSION:-${resolved_versions[1]}}
node_pty_version=${NODE_PTY_VERSION:-${resolved_versions[2]}}

if [[ -z "$electron_version" || -z "$better_sqlite3_version" || -z "$node_pty_version" ]]; then
  echo "Unable to resolve required package versions from $package_json" >&2
  exit 1
fi

echo "Rebuilding Linux native modules"
echo "Electron: $electron_version"
echo "better-sqlite3: $better_sqlite3_version"
echo "node-pty: $node_pty_version"

if [[ -z "$work_dir" || "$work_dir" != "$repo_root"/* ]]; then
  echo "Refusing to clean unsafe path: ${work_dir:-<empty>}" >&2
  exit 1
fi
rm -rf "$work_dir"
mkdir -p "$work_dir"

cat > "$work_dir/package.json" <<'JSON'
{
  "private": true,
  "name": "codex-linux-native-rebuild",
  "version": "0.0.0"
}
JSON

pushd "$work_dir" >/dev/null
npm install --no-package-lock --no-save \
  "electron@$electron_version" \
  "better-sqlite3@$better_sqlite3_version" \
  "node-pty@$node_pty_version"
npm rebuild --build-from-source \
  --runtime=electron \
  --target="$electron_version" \
  --dist-url=https://electronjs.org/headers \
  better-sqlite3 \
  node-pty
popd >/dev/null

install -D -m 755 \
  "$work_dir/node_modules/better-sqlite3/build/Release/better_sqlite3.node" \
  "$app_dir/node_modules/better-sqlite3/build/Release/better_sqlite3.node"

install -D -m 755 \
  "$work_dir/node_modules/node-pty/build/Release/pty.node" \
  "$app_dir/node_modules/node-pty/build/Release/pty.node"

if [[ -f "$work_dir/node_modules/node-pty/build/Release/spawn-helper" ]]; then
  install -D -m 755 \
    "$work_dir/node_modules/node-pty/build/Release/spawn-helper" \
    "$app_dir/node_modules/node-pty/build/Release/spawn-helper"
fi

echo "Native Linux modules installed into $app_dir"
