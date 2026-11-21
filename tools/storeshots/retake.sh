#!/bin/zsh
# Retake captures that came out blank (taken before the app finished drawing).
# usage: retake.sh RAW_DIR SIM_UDID DEVICE [DISPLAY]   (same arguments as capture.sh)
RAW=$1; SIM=$2; DEVICE=$3; DISP=$4
HERE=${0:A:h}
for f in $RAW/$DEVICE/*/*/*.png(N); do
  # A blank launch is one flat color (only the status bar differs): share of the most common color, in %
  flat=$(python3 -I -c "from PIL import Image; import sys; im=Image.open(sys.argv[1]).convert('RGB').resize((132,286)); print(int(100*max(im.getcolors(40000))[0]/(132*286)))" $f)
  [ $flat -lt 90 ] && continue
  rel=${f#$RAW/$DEVICE/}; LANG_=${rel%%/*}; rest=${rel#*/}; MODE_=${rest%%/*}; NAME=${${f:t:r}#*_}
  [ "$NAME" = watch ] && continue
  echo "retake $LANG_ $MODE_ $NAME ($flat% one color)"
  xcrun simctl ui $SIM appearance $MODE_ >/dev/null 2>&1
  LANGS=$LANG_ MODES=$MODE_ SHOTS=$NAME WAIT=${WAIT:-30} $HERE/capture.sh $RAW $SIM $DEVICE $DISP >/dev/null
done
echo checked
