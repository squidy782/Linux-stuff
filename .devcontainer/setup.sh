#!/usr/bin/env bash
set -e
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
if ! grep -Rqs 'ppa.launchpadcontent.net/xtradeb/apps/ubuntu' /etc/apt/sources.list.d; then
    sudo add-apt-repository -y ppa:xtradeb/apps
fi
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y htop tree curl cowsay sl figlet jq lxqt-core lxqt-themes openbox greybird-gtk-theme arc-theme papirus-icon-theme chromium
sudo env DEBIAN_FRONTEND=noninteractive apt-get remove -y surf epiphany-browser xfce4 budgie-desktop

source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 ]]; then
    echo "The pinned Ghostty package is only for Ubuntu 24.04; found $ID $VERSION_ID" >&2
    exit 1
fi

ghostty_arch=$(dpkg --print-architecture)
if [[ "$ghostty_arch" != amd64 && "$ghostty_arch" != arm64 ]]; then
    echo "Unsupported architecture for the Ghostty package: $ghostty_arch" >&2
    exit 1
fi

ghostty_deb=$(mktemp --suffix=.deb)
trap 'rm -f "$ghostty_deb"' EXIT
curl -fsSL "https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.3.1-0-ppa2/ghostty_1.3.1-0.ppa2_${ghostty_arch}_24.04.deb" -o "$ghostty_deb"
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$ghostty_deb"

mkdir -p "$HOME/.config/lxqt" "$HOME/.config/openbox" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
if [[ ! -e "$HOME/.config/lxqt/lxqt.conf" ]]; then
    cat > "$HOME/.config/lxqt/lxqt.conf" <<'EOF'
[General]
__userfile__=true
icon_theme=Papirus-Dark
theme=dark

[Palette]
window_color=#232323
base_color=#282828
highlight_color=#640b0c
highlighted_text_color=#ebfdff
link_color=#8c9bff
link_visited_color=#ffb3f7
text_color=#b8b8b8
window_text_color=#e1e6e6
tooltip_base_color=#232323
tooltip_text_color=#e1e6e6
EOF
fi
if [[ ! -e "$HOME/.config/lxqt/session.conf" ]]; then
    cat > "$HOME/.config/lxqt/session.conf" <<'EOF'
[General]
__userfile__=true
window_manager=openbox
EOF
fi
if [[ ! -e "$HOME/.config/openbox/rc.xml" && -f /etc/xdg/openbox/rc.xml ]]; then
    sed 's/^  <name>[^<]*<\/name>/  <name>Greybird-dark<\/name>/' /etc/xdg/openbox/rc.xml > "$HOME/.config/openbox/rc.xml"
fi
if [[ ! -e "$HOME/.config/gtk-3.0/settings.ini" ]]; then
    cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=true
EOF
fi
if [[ ! -e "$HOME/.config/gtk-4.0/settings.ini" ]]; then
    cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=true
EOF
fi

mkdir -p "$HOME/.vnc"
cat > "$HOME/.xsession" <<'EOF'
#!/usr/bin/env bash
export XDG_CURRENT_DESKTOP=LXQt
export XDG_SESSION_DESKTOP=lxqt
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR="$HOME/.cache/xdg-runtime"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
while true; do
    dbus-run-session -- startlxqt
    sleep 2
done
EOF
chmod +x "$HOME/.xsession"

if pgrep -x Xtigervnc >/dev/null; then
    tigervncserver -kill "${DISPLAY:-:1}"
fi
