#!/bin/bash
# install.sh - deploy openDucky to /opt/ducky and enable the services.
# Run ON the OpenStick dongle (Debian), from inside the repo folder.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "[*] Creating /opt/ducky ..."
sudo mkdir -p /opt/ducky/web/cgi-bin /opt/ducky/payloads

echo "[*] Copying scripts ..."
sudo cp "$HERE"/bin/*.sh                 /opt/ducky/
sudo cp "$HERE"/web/serve-panel.pl       /opt/ducky/web/
sudo cp "$HERE"/web/cgi-bin/panel.cgi    /opt/ducky/web/cgi-bin/
sudo cp "$HERE"/payloads/*.dd            /opt/ducky/payloads/ 2>/dev/null || true

echo "[*] Permissions ..."
sudo chmod +x /opt/ducky/*.sh /opt/ducky/web/serve-panel.pl /opt/ducky/web/cgi-bin/panel.cgi
# let the current user edit payloads without sudo
sudo chown -R "$(id -un)":"$(id -gn)" /opt/ducky

echo "[*] Installing systemd units ..."
sudo cp "$HERE"/systemd/ducky-web.service  /etc/systemd/system/
sudo cp "$HERE"/systemd/ducky-boot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ducky-web.service
sudo systemctl enable ducky-boot.service

IP=$(ip -4 addr show usb0 2>/dev/null | sed -n 's/.*inet \([0-9.]*\).*/\1/p' | head -1)
echo
echo "[+] openDucky installed."
echo "    Web panel: http://${IP:-<dongle-ip>}:8080/cgi-bin/panel.cgi"
echo "    Needs: OpenStick/Debian with /etc/gt/templates/hid.scheme and the 'gt' tool."
