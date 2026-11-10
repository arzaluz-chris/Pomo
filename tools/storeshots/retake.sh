#!/bin/zsh
# Retake blank captures. usage: retake.sh RAW P69 P63 W
RAW=$1; P69=$2; P63=$3; W=$4; APP=com.christian-arzaluz.Pomo; WAPP=com.christian-arzaluz.Pomo.watch
blank() { python3 -I -c "
import sys
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGB').resize((40,80)); c=im.getcolors(4000)
sys.exit(0 if (c is not None and len(c)<300) else 1)" "$1"; }
for f in $RAW/*.png; do
  n=$(basename $f .png); LANG=${n%%_*}; rest=${n#*_}; SIZE=${rest%%_*}; NAME=${rest#*_}
  LOCALE=$([ "$LANG" = es ] && echo es_MX || echo en_US)
  for try in 1 2 3; do
    blank $f || break
    if [ "$SIZE" = watch ]; then
      xcrun simctl terminate $W $WAPP >/dev/null 2>&1
      xcrun simctl launch $W $WAPP -PomoDemoData YES -AppleLanguages "($LANG)" -AppleLocale $LOCALE >/dev/null
      sleep 25; xcrun simctl io $W screenshot $f >/dev/null 2>&1
    else
      SIM=$([ "$SIZE" = 69 ] && echo $P69 || echo $P63)
      case $NAME in timer) TAB=0; ST=running;; break) TAB=0; ST=break;; stats) TAB=1; ST=running;; settings) TAB=2; ST=running;; esac
      A=$(xcrun simctl get_app_container $SIM $APP data)
      xcrun simctl terminate $SIM $APP >/dev/null 2>&1
      xcrun simctl spawn $SIM defaults write "$A/Library/Preferences/$APP" selectedTab -int $TAB
      xcrun simctl launch $SIM $APP -PomoDemoData YES -PomoDemoState $ST -AppleLanguages "($LANG)" -AppleLocale $LOCALE >/dev/null
      sleep 25; xcrun simctl io $SIM screenshot $f >/dev/null 2>&1
    fi
  done
  blank $f && echo "STILL BLANK $n"
done
echo retake-done
