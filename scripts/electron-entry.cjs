const path = require("path");
const electron = require("electron");
const { app, nativeTheme } = electron;

const appDir = process.env.CODEX_APP_ROOT || path.join(__dirname, "..", "build", "linux-runtime", "app");
const packageJson = require(path.join(appDir, "package.json"));
const iconPath = process.platform === "linux"
  ? (
      process.env.CODEX_WINDOW_ICON
      || process.env.CODEX_APP_ICON
      || "/usr/share/icons/hicolor/512x512/apps/codex-desktop.png"
    )
  : null;
const opaqueWindowBackground = nativeTheme.shouldUseDarkColors ? "#1f1f1f" : "#f9f9f9";

if (process.platform === "linux") {
  const OriginalBrowserWindow = electron.BrowserWindow;
  class PatchedBrowserWindow extends OriginalBrowserWindow {
    constructor(options = {}) {
      const patchedOptions = { ...options };

      if (!patchedOptions.icon && iconPath) {
        patchedOptions.icon = iconPath;
      }
      const needsBgFix =
        patchedOptions.backgroundColor === "#00000000"
        && patchedOptions.transparent !== true;
      if (needsBgFix) {
        patchedOptions.backgroundColor = opaqueWindowBackground;
      }

      super(patchedOptions);

      if (iconPath) {
        this.setIcon(iconPath);
      }
      if (needsBgFix) {
        this.setBackgroundColor(opaqueWindowBackground);
      }
    }
  }

  Object.setPrototypeOf(PatchedBrowserWindow, OriginalBrowserWindow);
  electron.BrowserWindow = PatchedBrowserWindow;

  if (!process.env.CHROME_DESKTOP) {
    process.env.CHROME_DESKTOP = "codex-desktop.desktop";
  }
}

process.chdir(appDir);
if (packageJson && typeof packageJson.version === "string") {
  app.setVersion(packageJson.version);
}
if (packageJson && typeof packageJson.productName === "string") {
  app.setName(packageJson.productName);
}
if (process.platform === "linux" && !packageJson.desktopName) {
  packageJson.desktopName = "codex-desktop.desktop";
}
require(path.join(appDir, ".vite", "build", "bootstrap.js"));
