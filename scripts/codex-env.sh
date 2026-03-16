# scripts/codex-env.sh - Shared environment setup for Codex launchers.
# Source this file; do not execute directly.

# Validate the Electron binary has the expected NODE_MODULE_VERSION.
# Usage: codex_validate_electron "$electron_bin" "$required_modules"
codex_validate_electron() {
  local electron_bin=$1
  local required_modules=$2

  local electron_version
  electron_version=$(
    ELECTRON_RUN_AS_NODE=1 "$electron_bin" -p 'process.versions.electron || ""' 2>/dev/null
  )
  local electron_modules
  electron_modules=$(
    ELECTRON_RUN_AS_NODE=1 "$electron_bin" -p 'process.versions.modules || ""' 2>/dev/null
  )
  if [[ "$electron_modules" != "$required_modules" ]]; then
    echo "Codex requires Electron 40.x with NODE_MODULE_VERSION $required_modules." >&2
    echo "Selected launcher: $electron_bin" >&2
    echo "Detected Electron version: ${electron_version:-unknown}" >&2
    echo "Detected NODE_MODULE_VERSION: ${electron_modules:-unknown}" >&2
    return 1
  fi
}

# Set up the runtime environment for the Codex Electron app.
# Usage: codex_setup_env "$app_dir" "$bin_dir"
codex_setup_env() {
  local app_dir=$1
  local bin_dir=$2

  if [[ -x "$bin_dir/codex" && -z "${CODEX_CLI_PATH:-}" ]]; then
    export CODEX_CLI_PATH="$bin_dir/codex"
  fi

  if [[ -d "$bin_dir" ]]; then
    export PATH="$bin_dir:${PATH:-/usr/bin}"
  fi

  if [[ -z "${CHROME_DESKTOP:-}" ]]; then
    export CHROME_DESKTOP="codex-desktop.desktop"
  fi

  if [[ -n "${CODEX_OZONE_PLATFORM:-}" && -z "${ELECTRON_OZONE_PLATFORM_HINT:-}" ]]; then
    export ELECTRON_OZONE_PLATFORM_HINT="$CODEX_OZONE_PLATFORM"
  fi
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" && -z "${ELECTRON_OZONE_PLATFORM_HINT:-}" ]]; then
    export ELECTRON_OZONE_PLATFORM_HINT="x11"
  fi

  if [[ -z "${ELECTRON_RENDERER_URL:-}" ]]; then
    export ELECTRON_RENDERER_URL="file://$app_dir/webview/index.html"
  fi
  export CODEX_APP_ROOT="$app_dir"
}

# Launch Electron with the standard arguments.
# Usage: codex_exec "$electron_bin" "$entry_script" "$@"
codex_exec() {
  local electron_bin=$1
  local entry_script=$2
  shift 2

  local electron_args=()
  if [[ -n "${ELECTRON_OZONE_PLATFORM_HINT:-}" ]]; then
    electron_args+=("--ozone-platform=${ELECTRON_OZONE_PLATFORM_HINT}")
  fi

  exec "$electron_bin" "${electron_args[@]}" "$entry_script" "$@"
}
