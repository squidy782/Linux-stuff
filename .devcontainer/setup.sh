#!/usr/bin/env bash
set -e
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y htop tree curl cowsay sl figlet jq budgie-desktop epiphany-browser
sudo env DEBIAN_FRONTEND=noninteractive apt-get remove -y surf

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

sudo sed -i 's/org.buddiesofbudgie.BudgiePolkit;//' /usr/share/gnome-session/sessions/org.buddiesofbudgie.BudgieDesktop.session

mkdir -p "$HOME/.vnc"
cat > "$HOME/.xsession" <<'EOF'
#!/usr/bin/env bash
export XDG_CURRENT_DESKTOP=Budgie:GNOME
export XDG_SESSION_DESKTOP=budgie
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR="$HOME/.cache/xdg-runtime"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
while true; do
    dbus-run-session -- budgie-desktop
    sleep 2
done
EOF
chmod +x "$HOME/.xsession"

if pgrep -x Xtigervnc >/dev/null; then
    tigervncserver -kill "${DISPLAY:-:1}"
fi
