#!/usr/bin/env bash
set -e
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y htop tree curl cowsay sl figlet jq budgie-desktop surf

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
