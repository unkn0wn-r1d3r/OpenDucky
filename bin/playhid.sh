#!/bin/bash
# playhid.sh - play a compiled .hid op-stream to the HID keyboard gadget
HIDFILE="${1:?usage: playhid.sh file.hid [/dev/hidg0]}"; DEV="${2:-/dev/hidg0}"
report(){ local mod=$1; shift; local keys=(00 00 00 00 00 00) i=0
  for k in "$@"; do keys[$i]=$k; i=$((i+1)); [ $i -ge 6 ] && break; done
  printf "\\x$mod\\x00\\x${keys[0]}\\x${keys[1]}\\x${keys[2]}\\x${keys[3]}\\x${keys[4]}\\x${keys[5]}" > "$DEV"; }
release(){ printf '\x00\x00\x00\x00\x00\x00\x00\x00' > "$DEV"; }
while read -r op a1 a2 a3 a4 a5 a6 a7; do case "$op" in
  ''|\#*) ;;
  D) sleep "$(awk "BEGIN{printf \"%.3f\", $a1/1000}")" ;;
  K) report "${a1:-00}" $a2 $a3 $a4 $a5 $a6 $a7; release; sleep 0.01 ;;
esac; done < "$HIDFILE"
