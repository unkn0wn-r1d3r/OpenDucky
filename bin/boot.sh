#!/bin/bash
# boot.sh - fire the armed payload on boot (one-shot auto-disarm), else dev mode
DUCKY=/opt/ducky; CFG=$DUCKY/config
exec >> /tmp/ducky-boot.log 2>&1
echo "=== boot $(date) ==="
[ -f "$CFG" ] || { echo "no config -> dev mode"; exit 0; }
rob=$(sed -n 's/^run_on_boot=//p' "$CFG")
pay=$(sed -n 's/^payload=//p' "$CFG")
os=$(sed -n 's/^os=//p' "$CFG"); [ -z "$os" ] && os=win
if [ "$rob" = "1" ] && [ -n "$pay" ] && [ -f "$DUCKY/payloads/$pay" ]; then
  echo "ARMED -> $pay (os=$os); firing in 5s"
  sleep 5
  "$DUCKY/dd2hid.sh" "$DUCKY/payloads/$pay" --os "$os" > "$DUCKY/current.hid"
  printf 'run_on_boot=0\n' > "$CFG"
  /bin/bash "$DUCKY/run-hid.sh" "$DUCKY/current.hid"
  echo "fired; disarmed"
else
  echo "not armed -> dev mode"
fi
