#!/bin/bash
# dd2hid.sh - compile Ducky-style .dd scripts -> .hid report ops, with cross-OS macro verbs
set -u
OS=win; LAYOUT=us; SPEED=5; LEAD=2000; SRC=""
while [ $# -gt 0 ]; do case "$1" in
  --os) OS=$2; shift 2;; --layout) LAYOUT=$2; shift 2;;
  --speed) SPEED=$2; shift 2;; --lead) LEAD=$2; shift 2;;
  *) SRC=$1; shift;; esac; done
[ -n "$SRC" ] || { echo "usage: dd2hid.sh file.dd [--os ..][--layout ..][--speed ms][--lead ms]" >&2; exit 1; }
[ "$LAYOUT" = us ] || echo "# WARN: only 'us' layout implemented; using us" >&2
declare -A KM NK MOD
i=4; for c in a b c d e f g h i j k l m n o p q r s t u v w x y z; do KM[$c]=$(printf '00 %02x' $i); i=$((i+1)); done
i=4; for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do KM[$c]=$(printf '02 %02x' $i); i=$((i+1)); done
KM[1]="00 1e";KM[2]="00 1f";KM[3]="00 20";KM[4]="00 21";KM[5]="00 22";KM[6]="00 23";KM[7]="00 24";KM[8]="00 25";KM[9]="00 26";KM[0]="00 27"
KM['!']="02 1e";KM['@']="02 1f";KM['#']="02 20";KM['$']="02 21";KM['%']="02 22";KM['^']="02 23";KM['&']="02 24";KM['*']="02 25";KM['(']="02 26";KM[')']="02 27"
KM[' ']="00 2c";KM['-']="00 2d";KM['_']="02 2d";KM['=']="00 2e";KM['+']="02 2e";KM['[']="00 2f";KM['{']="02 2f";KM[']']="00 30";KM['}']="02 30"
KM['\']="00 31";KM['|']="02 31";KM[';']="00 33";KM[':']="02 33";KM["'"]="00 34";KM['"']="02 34";KM['`']="00 35";KM['~']="02 35"
KM[',']="00 36";KM['<']="02 36";KM['.']="00 37";KM['>']="02 37";KM['/']="00 38";KM['?']="02 38"
NK[ENTER]=28;NK[RETURN]=28;NK[SPACE]=2c;NK[TAB]=2b;NK[ESC]=29;NK[ESCAPE]=29;NK[BACKSPACE]=2a;NK[DELETE]=4c;NK[DEL]=4c;NK[INSERT]=49
NK[HOME]=4a;NK[END]=4d;NK[PAGEUP]=4b;NK[PAGEDOWN]=4e;NK[UP]=52;NK[DOWN]=51;NK[LEFT]=50;NK[RIGHT]=4f;NK[CAPSLOCK]=39
f=58; for n in F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12; do NK[$n]=$(printf '%02x' $f); f=$((f+1)); done
MOD[CTRL]=01;MOD[CONTROL]=01;MOD[SHIFT]=02;MOD[ALT]=04;MOD[GUI]=08;MOD[WINDOWS]=08;MOD[COMMAND]=08;MOD[META]=08;MOD[SUPER]=08
dly(){ [ "${1:-0}" -gt 0 ] 2>/dev/null && echo "D $1"; }
typestr(){ local s=$1; local n=${#s} j=0 ch code; while [ $j -lt $n ]; do ch=${s:$j:1}; code=${KM[$ch]:-}
  if [ -n "$code" ]; then echo "K $code"; dly "$SPEED"; else echo "# WARN no keymap: '$ch'" >&2; fi; j=$((j+1)); done; }
launcher(){ case "$OS" in
  win) echo "K 08 15";; mac) echo "K 08 2c";; linux) echo "K 04 3b";;
  *) echo "# WARN launcher undefined os=$OS" >&2;; esac; }
term_open(){ case "$OS" in
  win) launcher; dly 500; typestr "powershell"; echo "K 00 28";;
  mac) launcher; dly 500; typestr "Terminal"; dly 400; echo "K 00 28";;
  linux) echo "K 05 17";;
  *) echo "# WARN OPEN_TERMINAL undefined os=$OS" >&2;; esac; }
url_open(){ case "$OS" in
  win) launcher; dly 500; typestr "$1"; echo "K 00 28";;
  mac) launcher; dly 500; typestr "$1"; dly 300; echo "K 00 28";;
  linux) echo "K 05 17"; dly 800; typestr "xdg-open $1"; echo "K 00 28";;
  *) echo "# WARN OPEN_URL undefined os=$OS" >&2;; esac; }
echo "# $SRC  os=$OS layout=$LAYOUT speed=${SPEED}ms lead=${LEAD}ms"
dly "$LEAD"; DEF=0; LAST=""
while IFS= read -r raw || [ -n "$raw" ]; do
  raw=${raw%$'\r'}; line=${raw#"${raw%%[![:space:]]*}"}
  [ -z "$line" ] && continue; [ "${line:0:1}" = "#" ] && continue
  cmd=${line%%[[:space:]]*}; rest=${line#"$cmd"}; rest=${rest# }; U=${cmd^^}
  [ "$DEF" -gt 0 ] 2>/dev/null && echo "D $DEF"
  case "$U" in
    REM) out="";;
    DELAY) out="D ${rest// /}";;
    DEFAULT_DELAY|DEFAULTDELAY) DEF=${rest// /}; out="";;
    STRING) out=$(typestr "$rest");;
    STRINGLN) out=$(typestr "$rest"; echo "K 00 28");;
    RUN) a=${rest#\"}; a=${a%\"}; out=$(launcher; dly 500; typestr "$a"; echo "K 00 28");;
    OPEN_TERMINAL|TERMINAL) out=$(term_open);;
    OPEN_URL) a=${rest#\"}; a=${a%\"}; out=$(url_open "$a");;
    REPEAT) n=${rest// /}; out=""; for ((k=0;k<n;k++)); do out+="$LAST"$'\n'; done; out=${out%$'\n'};;
    *) mb=0 kh=""; for t in $U $rest; do TU=${t^^}
         if [ -n "${MOD[$TU]:-}" ]; then mb=$(( mb | 0x${MOD[$TU]} ))
         elif [ -n "${NK[$TU]:-}" ]; then kh=${NK[$TU]}
         else c=${t:0:1}; km=${KM[$c]:-}; [ -n "$km" ] && kh=${km#* }; fi; done
       mh=$(printf '%02x' "$mb"); [ -n "$kh" ] && out="K $mh $kh" || out="K $mh";;
  esac
  [ -n "$out" ] && { printf '%s\n' "$out"; LAST=$out; }
done < "$SRC"
