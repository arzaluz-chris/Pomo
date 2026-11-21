#!/bin/zsh
# Capture raw App Store screenshots from one simulator, in Spanish and English, light and dark.
# usage: capture.sh RAW_DIR SIM_UDID DEVICE [DISPLAY]
#   DEVICE  iphone | duo-folded   (folder name under RAW_DIR)
#   DISPLAY simctl display to capture (iPhone Duo outer screen: LCD)
# Output: RAW_DIR/DEVICE/{es,en}/{light,dark}/NN_name.png
# Optional env: LANGS="es en", MODES="light dark", SHOTS="timer adjust break stats settings"
RAW=$1; SIM=$2; DEVICE=$3; DISPLAY_ARG=${4:+--display=$4}
APP=com.christian-arzaluz.Pomo
LANGS=(${=LANGS:-es en}); MODES=(${=MODES:-light dark}); SHOTS=(${=SHOTS:-timer adjust break stats settings})

# shot name -> tab, demo state, file number
typeset -A TAB STATE NUM
TAB=(timer 0 adjust 0 break 0 stats 1 settings 2)
STATE=(timer running adjust adjusting break break stats running settings idle)
NUM=(timer 01 adjust 02 break 03 stats 04 settings 05)

shoot() { # lang mode shot
  local LANG=$1 MODE=$2 NAME=$3
  local LOCALE=$([ "$LANG" = es ] && echo es_MX || echo en_US)
  local OUT="$RAW/$DEVICE/$LANG/$MODE"; mkdir -p "$OUT"
  local A=$(xcrun simctl get_app_container $SIM $APP data)
  xcrun simctl terminate $SIM $APP >/dev/null 2>&1
  xcrun simctl spawn $SIM defaults write "$A/Library/Preferences/$APP" selectedTab -int ${TAB[$NAME]}
  # Durations back to the defaults (an earlier run may have changed them)
  for K in workDuration:25 shortBreakDuration:5 longBreakDuration:15 sessionsUntilLongBreak:4; do
    xcrun simctl spawn $SIM defaults write "$A/Library/Preferences/$APP" ${K%%:*} -int ${K##*:}
  done
  xcrun simctl launch $SIM $APP -PomoDemoData YES -PomoDemoState ${STATE[$NAME]} \
    -AppleLanguages "($LANG)" -AppleLocale $LOCALE >/dev/null
  sleep ${WAIT:-20}
  # Status bar shows the real time so it matches the timer's "ends at"
  xcrun simctl status_bar $SIM override --time "$(date +%-I:%M)" --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 >/dev/null 2>&1
  sleep 2
  xcrun simctl io $SIM screenshot $DISPLAY_ARG "$OUT/${NUM[$NAME]}_$NAME.png" >/dev/null 2>&1
  echo "$OUT/${NUM[$NAME]}_$NAME.png"
}

for MODE in $MODES; do
  xcrun simctl ui $SIM appearance $MODE >/dev/null 2>&1
  for LANG in $LANGS; do
    for NAME in $SHOTS; do shoot $LANG $MODE $NAME; done
  done
done
echo captured
