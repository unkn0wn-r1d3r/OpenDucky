#!/bin/bash
# run-hid.sh - swap USB net gadget -> HID keyboard, play a .hid, then restore networking
exec > /tmp/ducky.log 2>&1
set -x
HIDFILE="${1:?need .hid file}"
gt disable dual
gt load hid.scheme hid
[ -z "$(cat /sys/kernel/config/usb_gadget/hid/UDC)" ] && gt enable hid
sleep 3
/opt/ducky/playhid.sh "$HIDFILE" /dev/hidg0
sleep 1
gt disable hid; gt rm -rf hid; gt enable dual
echo DONE
