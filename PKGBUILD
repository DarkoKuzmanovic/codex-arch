pkgname=codex-desktop-bin
pkgver=26.311.21342
pkgrel=1
pkgdesc="Unofficial Arch packaging scaffold for the Codex Electron desktop app"
arch=("x86_64")
url="https://openai.com/"
license=("custom")
depends=("ripgrep")
makedepends=("nodejs" "p7zip" "python" "make" "gcc")
source=(
  "Codex.dmg"
)
sha256sums=("SKIP")

prepare() {
  cd "$srcdir"

  command -v asar >/dev/null 2>&1 || {
    echo "asar is required on PATH for the import step" >&2
    return 1
  }

  bash "$startdir/scripts/import-codex-dmg.sh" "$srcdir/Codex.dmg" "$srcdir/imported"
  bash "$startdir/scripts/stage-linux-runtime.sh" "$srcdir/imported" "$srcdir/linux-runtime"

  if [[ ! -x "$srcdir/linux-runtime/bin/codex" ]]; then
    echo "Linux codex binary was not staged. Set CODEX_CLI_PATH or CODEX_LINUX_BIN." >&2
    return 1
  fi

  if [[ ! -d "$srcdir/linux-runtime/vendor" ]]; then
    echo "Linux Codex vendor payload was not staged. Populate build/codex-vendor first." >&2
    return 1
  fi

  icon_source=$(find "$srcdir/imported/app/webview/assets" -maxdepth 1 -type f -name 'app-*.png' | sort | head -n 1)
  if [[ -z "$icon_source" ]]; then
    echo "Launcher icon source was not found in the recovered web assets." >&2
    return 1
  fi

  cp "$icon_source" "$srcdir/codex-desktop.png"
}

build() {
  cd "$srcdir"
  bash "$startdir/scripts/rebuild-linux-natives.sh" "$srcdir/linux-runtime/app" "$srcdir/native-rebuild"
}

package() {
  install -d "$pkgdir/usr/bin"
  install -d "$pkgdir/usr/lib/codex-desktop"
  install -d "$pkgdir/usr/share/applications"
  install -d "$pkgdir/usr/share/icons/hicolor/512x512/apps"
  install -d "$pkgdir/usr/share/pixmaps"

  cp -a "$srcdir/linux-runtime/app" "$pkgdir/usr/lib/codex-desktop/app"
  if [[ -d "$srcdir/linux-runtime/bin" ]]; then
    cp -a "$srcdir/linux-runtime/bin" "$pkgdir/usr/lib/codex-desktop/bin"
  fi
  if [[ -d "$srcdir/linux-runtime/vendor" ]]; then
    cp -a "$srcdir/linux-runtime/vendor" "$pkgdir/usr/lib/codex-desktop/vendor"
  fi
  if [[ -d "$srcdir/native-rebuild/node_modules/electron/dist" ]]; then
    cp -a "$srcdir/native-rebuild/node_modules/electron/dist" \
      "$pkgdir/usr/lib/codex-desktop/electron"
  else
    echo "Bundled Electron runtime not found in native-rebuild output." >&2
    return 1
  fi

  install -m 755 "$startdir/packaging/codex-desktop" "$pkgdir/usr/bin/codex-desktop"
  install -m 644 "$startdir/scripts/electron-entry.cjs" \
    "$pkgdir/usr/lib/codex-desktop/electron-entry.cjs"
  install -m 644 "$startdir/scripts/codex-env.sh" \
    "$pkgdir/usr/lib/codex-desktop/codex-env.sh"
  install -m 644 "$startdir/packaging/codex-desktop.desktop" \
    "$pkgdir/usr/share/applications/codex-desktop.desktop"
  install -m 644 "$srcdir/codex-desktop.png" \
    "$pkgdir/usr/share/icons/hicolor/512x512/apps/codex-desktop.png"
  install -m 644 "$srcdir/codex-desktop.png" \
    "$pkgdir/usr/share/pixmaps/codex-desktop.png"
}
