#!/bin/bash
# AetherOS first-login experience: applies the macOS-style panel layout once per user.
set -u
MARK="$HOME/.config/aether/firstlogin.done"
[ -f "$MARK" ] && exit 0
mkdir -p "$(dirname "$MARK")"

apply_layout() {
qdbus org.kde.plasmashell /PlasmaShell evaluateScript "$(cat <<'LAYOUT'
// AetherOS layout: macOS-style top menu bar + floating bottom dock
var panels = panels();
for (var i in panels) { panels[i].remove(); }
// top menubar
var top = new Panel("org.kde.plasma.private.panel");
top.alignment = "center";
top.location = "top";
top.height = 28;
top.hiding = "normal";
top.spacing = 2;
top.addWidget("org.kde.plasma.appmenu");
var spacerL = top.addWidget("org.kde.plasma.pager");
spacerL.currentConfigGroup = ["general"];
spacerL.writeConfig("showWindowIcons", false);
var tray = top.addWidget("org.kde.plasma.private.systemtray");
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Configuration", "Appearance"];
clock.writeConfig("showDate", false);
// bottom dock
var dock = new Panel("org.kde.plasma.private.panel");
dock.alignment = "center";
dock.location = "bottom";
dock.height = 56;
dock.hiding = "dodgewindows";
dock.floating = true;
dock.spacing = 6;
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("launchers", ["applications:firefox-esr.desktop","applications:org.kde.dolphin.desktop","applications:org.kde.konsole.desktop","applications:aether-welcome.desktop"]);
// wallpaper
var allDesktops = desktops();
for (var j in allDesktops) {
    var d = allDesktops[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper","org.kde.image","General"];
    d.writeConfig("Image", "/usr/share/wallpapers/Aether-Night");
}
LAYOUT
)" >/dev/null 2>&1
}

apply_layout
# icon/cursor/scheme apply (belt and suspenders)
plasma-apply-colorscheme AetherDark >/dev/null 2>&1 || true
plasma-apply-cursortheme WhiteSur-cursors >/dev/null 2>&1 || true
plasma-apply-wallpaperimage /usr/share/wallpapers/Aether-Night/contents/images/3840x2160.png >/dev/null 2>&1 || true
date > "$MARK"
