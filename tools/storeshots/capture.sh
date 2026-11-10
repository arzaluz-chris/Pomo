#!/bin/zsh
# Capture raw App Store screenshots from the simulators.
# usage: capture.sh RAW_DIR PHONE69_UDID PHONE63_UDID WATCH_UDID
RAW=$1; P69=$2; P63=$3; W=$4
mkdir -p $RAW
APP=com.christian-arzaluz.Pomo
WAPP=com.christian-arzaluz.Pomo.watch

shoot_phone() { # sim size lang tab state name
  local SIM=$1 SIZE=$2 LANG=$3 TAB=$4 STATE=$5 NAME=$6
  local LOCALE=$([ "$LANG" = es ] && echo es_MX || echo en_US)
  local A=$(xcrun simctl get_app_container $SIM $APP data)
  xcrun simctl terminate $SIM $APP >/dev/null 2>&1
  xcrun simctl spawn $SIM defaults write "$A/Library/Preferences/$APP" selectedTab -int $TAB
  xcrun simctl terminate $SIM com.apple.Preferences >/dev/null 2>&1
  local NOTIF=$([ "$NAME" = settings ] && echo true || echo false)
  xcrun simctl spawn $SIM defaults write "$A/Library/Preferences/$APP" isNotificationEnabled -bool $NOTIF
  xcrun simctl launch $SIM $APP -PomoDemoData YES -PomoDemoState $STATE -AppleLanguages "($LANG)" -AppleLocale $LOCALE >/dev/null
  sleep 22
  # Status bar shows the real time so it matches the timer's "ends at"
  xcrun simctl status_bar $SIM override --time "$(date +%-I:%M)" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null 2>&1
  sleep 2
  xcrun simctl io $SIM screenshot "$RAW/${LANG}_${SIZE}_${NAME}.png" >/dev/null 2>&1
}

for SIM_SIZE in "$P69:69" "$P63:63"; do
  SIM=${SIM_SIZE%%:*}; SIZE=${SIM_SIZE##*:}
  xcrun simctl status_bar $SIM override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null 2>&1
  xcrun simctl ui $SIM appearance light >/dev/null 2>&1
  for LANG in es en; do
    shoot_phone $SIM $SIZE $LANG 0 running timer
    shoot_phone $SIM $SIZE $LANG 0 break break
    [ -n "$ONLY_TIMERS" ] || shoot_phone $SIM $SIZE $LANG 1 running stats
    shoot_phone $SIM $SIZE $LANG 2 idle settings
  done
done

if [ -n "$W" ] && [ -z "$ONLY_TIMERS" ]; then
  for LANG in es en; do
    LOCALE=$([ "$LANG" = es ] && echo es_MX || echo en_US)
    xcrun simctl terminate $W $WAPP >/dev/null 2>&1
    xcrun simctl launch $W $WAPP -PomoDemoData YES -AppleLanguages "($LANG)" -AppleLocale $LOCALE >/dev/null
    sleep 14
    xcrun simctl io $W screenshot "$RAW/${LANG}_watch_timer.png" >/dev/null 2>&1
  done
fi
echo captured
