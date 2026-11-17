#!/bin/bash
# panel.cgi - openDucky web control panel (list / editor / run / arm)
DUCKY=/opt/ducky; PAYLOADS=$DUCKY/payloads; CFG=$DUCKY/config
mkdir -p "$PAYLOADS"
Q="${QUERY_STRING:-}"
getq(){ echo "$Q" | tr '&' '\n' | sed -n "s/^$1=//p" | head -1 | sed 's/+/ /g'; }
BODY=""; [ "${REQUEST_METHOD:-GET}" = "POST" ] && BODY=$(cat)
pf(){ echo "$BODY" | tr '&' '\n' | sed -n "s/^$1=//p" | head -1; }
urldec(){ local s="${1//+/ }"; printf '%b' "${s//%/\\x}"; }
hesc(){ sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g'; }
action=$(getq action); [ -z "$action" ] && action=$(pf action)
os=$(getq os); [ -z "$os" ] && os=win
payload=$(basename "$(getq payload)" 2>/dev/null)
msg=""
case "$action" in
  run) if [ -f "$PAYLOADS/$payload" ]; then
        "$DUCKY/dd2hid.sh" "$PAYLOADS/$payload" --os "$os" > "$DUCKY/current.hid" 2>/tmp/dd2hid.err
        systemctl reset-failed ducky-run 2>/dev/null
        systemd-run --unit=ducky-run --collect /bin/bash "$DUCKY/run-hid.sh" "$DUCKY/current.hid" >/dev/null 2>&1
        msg="Running $payload (os=$os) - USB drops while it types"
       else msg="not found: $payload"; fi;;
  arm) printf 'payload=%s\nos=%s\nrun_on_boot=1\n' "$payload" "$os" > "$CFG"; msg="Armed $payload (os=$os)";;
  disarm) printf 'run_on_boot=0\n' > "$CFG"; msg="Disarmed";;
  save) name=$(basename "$(urldec "$(pf name)")"); [ -n "$name" ] || name=payload
        case "$name" in *.dd);; *) name="$name.dd";; esac
        urldec "$(pf content)" > "$PAYLOADS/$name"; msg="Saved $name";;
  delete) [ -n "$payload" ] && [ -f "$PAYLOADS/$payload" ] && { rm -f "$PAYLOADS/$payload"; msg="Deleted $payload"; };;
esac
editname=""; editcontent=""
[ "$action" = edit ] && [ -f "$PAYLOADS/$payload" ] && { editname="$payload"; editcontent=$(cat "$PAYLOADS/$payload"); }
echo "Content-type: text/html"; echo
cat <<H
<!doctype html><meta name=viewport content="width=device-width,initial-scale=1"><title>openDucky Panel</title><style>
body{font-family:system-ui,sans-serif;max-width:680px;margin:1rem auto;padding:0 1rem;background:#0d0f12;color:#e8e8e8}
.btn{background:#39d98a;color:#002;border:0;padding:.3rem .6rem;border-radius:6px;text-decoration:none;display:inline-block;margin:2px;font-size:13px;cursor:pointer}
.arm{background:#f0a73f}.off{background:#555;color:#fff}.del{background:#e5484d;color:#fff}
.list{max-height:260px;overflow:auto;border:1px solid #222;border-radius:6px}
table{width:100%;border-collapse:collapse}td{padding:.35rem;border-bottom:1px solid #1c1f24}
textarea{width:100%;height:200px;background:#000;color:#9fe;border:1px solid #333;border-radius:6px;font-family:monospace;font-size:13px;padding:.5rem;box-sizing:border-box}
input[name=name]{padding:.35rem;background:#1a1d22;color:#eee;border:1px solid #333;border-radius:6px}
pre{background:#000;padding:.6rem;border-radius:6px;max-height:200px;overflow:auto;font-size:12px}
select{padding:.3rem;background:#1a1d22;color:#eee;border:1px solid #333;border-radius:6px}.msg{background:#10324a;padding:.5rem .7rem;border-radius:6px}.on{color:#f0a73f;font-weight:700}
</style><h2>🦆 openDucky Panel</h2>
H
[ -n "$msg" ] && echo "<p class=msg>$msg</p>"
boot="<span class=off>disarmed</span>"
if [ -f "$CFG" ] && grep -q '^run_on_boot=1' "$CFG"; then
  bp=$(sed -n 's/^payload=//p' "$CFG"); bo=$(sed -n 's/^os=//p' "$CFG"); boot="<span class=on>ARMED &rarr; $bp (os=$bo)</span>"; fi
echo "<p><b>Boot:</b> $boot &nbsp; <a class='btn off' href='?action=disarm'>Disarm</a></p>"
echo "<form method=get>Target OS: <select name=os onchange='this.form.submit()'>"
for o in win mac linux android; do s=""; [ "$o" = "$os" ] && s=" selected"; echo "<option$s>$o</option>"; done
echo "</select></form><h3>Payloads</h3><div class=list><table>"
shopt -s nullglob
for f in "$PAYLOADS"/*.dd; do n=$(basename "$f")
  echo "<tr><td>$n</td><td style=text-align:right><a class=btn href='?action=run&payload=$n&os=$os'>Run</a><a class='btn arm' href='?action=arm&payload=$n&os=$os'>Arm</a><a class=btn href='?action=edit&payload=$n&os=$os'>Edit</a><a class='btn del' href='?action=delete&payload=$n&os=$os'>Del</a></td></tr>"; done
echo "</table></div><h3>Editor</h3><form method=post action='/cgi-bin/panel.cgi'><input type=hidden name=action value=save>"
echo "<p><input name=name value='$editname' placeholder='name.dd'> <button class=btn>Save</button> <a class='btn off' href='/cgi-bin/panel.cgi'>New</a></p>"
echo -n "<textarea name=content placeholder='REM paste script&#10;DELAY 500&#10;STRING hello&#10;ENTER'>"; echo "$editcontent" | hesc; echo "</textarea></form>"
echo "<h3>Last run log</h3><pre>"; [ -f /tmp/ducky.log ] && tail -40 /tmp/ducky.log | hesc; echo "</pre>"
