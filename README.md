# openDucky from Hackerpod.space
visit: https://hackerpod.space/blog/openducky-lte-badusb/

Turn a cheap Qualcomm **MSM8916 4G LTE USB dongle** (≈ ₹600 / ~$7) into a
self-contained, web-managed **USB keystroke-injection platform** with its own
Ducky-style `.dd` script compiler, a browser control panel, armed-on-boot
payloads, and optional worldwide remote control over LTE + a WireGuard mesh.

Built on **OpenStick** (Debian on the mainline postmarketOS MSM8916 kernel).
Pure **Bash + Perl** - no Python, no heavyweight web server.

> ⚠️ **Authorized use only.** This types into any machine it is plugged into,
> on power. Use it only on systems you own or are explicitly authorized to
> test. Keep a benign default payload. For security research and education.

Full build write-up & explanation: **hackerpod.space**

---

## What it does

| Capability | How |
|---|---|
| USB keyboard (HID) injection | configfs `hid.scheme` gadget → `/dev/hidg0` |
| Standard `.dd` scripts | `dd2hid.sh` compiler → `.hid` → `playhid.sh` |
| Cross-OS payloads | Target Profile (`--os/--layout/--speed/--lead`) + macro verbs |
| Web control | Perl server + Bash CGI panel on `:8080` |
| Standalone drop box | armed config + one-shot boot service |
| Worldwide remote control | LTE uplink + Tailscale/headscale mesh |

## Requirements

- An MSM8916 LTE dongle (UZ801 / UFI001C / UF896 / HMUF02 / …) flashed with
  **OpenStick / Debian** (ships `gt`, configfs gadget support, and
  `/etc/gt/templates/hid.scheme`).
- Back up your modem calibration partitions **before** flashing
  (`persist`, `modem*`, `fsg`, `modemst1`, `modemst2`) - losing them bricks the modem.

## Install

On the dongle, from inside this repo:

```bash
chmod +x install.sh
./install.sh
```

This deploys everything to `/opt/ducky/`, installs the systemd units, and starts
the web panel. Open `http://<dongle-ip>:8080/cgi-bin/panel.cgi`.

## Usage

- **Write a payload** in the panel editor (or drop a `.dd` in `/opt/ducky/payloads/`).
- **Run now** - compiles with the chosen Target OS and fires it (USB flips to
  keyboard, types, then restores networking automatically).
- **Arm** - writes `/opt/ducky/config`; the next boot fires it once, then
  auto-disarms.

### Compile a payload by hand

```bash
/opt/ducky/dd2hid.sh payloads/macro.dd --os win --layout us --speed 5 --lead 2000 > out.hid
/opt/ducky/playhid.sh out.hid          # (while a hid gadget is active)
```

### `.dd` script support

`REM  DELAY  DEFAULT_DELAY  STRING  STRINGLN  ENTER  REPEAT`, modifier combos
(`GUI r`, `CTRL ALT DELETE`, …), named keys (arrows, F-keys, TAB, ESC, …),
and cross-OS macro verbs: `RUN <cmd>`, `OPEN_TERMINAL`, `OPEN_URL <url>`.

## Remote control (optional)

1. **LTE:** `sudo nmcli con add type gsm ifname '*' con-name lte apn <your-apn>` → `nmcli con up lte`.
2. **Mesh:** `sudo modprobe tun` → install Tailscale → `sudo tailscale up` →
   reach the dongle at its `100.x` address from anywhere. For a self-hosted
   control plane, point Tailscale at your own **headscale** with
   `--login-server`.

## Layout

```
bin/        dd2hid.sh  playhid.sh  run-hid.sh  boot.sh
web/        serve-panel.pl  cgi-bin/panel.cgi
systemd/    ducky-web.service  ducky-boot.service
payloads/   demo.dd  macro.dd
install.sh  config.example  LICENSE
```

## License

Connect to : Hackerpod.space
