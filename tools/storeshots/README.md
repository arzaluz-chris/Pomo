# App Store screenshots

Raw captures come from the simulators with DEBUG demo data (`-PomoDemoData YES`,
`-PomoDemoState running|break|paused|idle`); the composer frames them with Apple's
device bezels (Apple Design Resources, licensed for app mockups only: keep them out of
this repo) and adds the headline.

1. Simulators: iPhone 18 Pro Max (6.9", 1320×2868) paired with Apple Watch Series 11
   46 mm (416×496), and iPhone 18 Pro (6.3", 1206×2622). Install the Debug build.
2. `./capture.sh RAW P69_UDID P63_UDID WATCH_UDID` (es and en), then
   `./retake.sh RAW P69 P63 WATCH` to redo captures taken before the app finished drawing.
3. `python3 -I compose.py RAW OUT` writes `OUT/{es,en}/iphone-69|iphone-63|watch-46/*.png`
   (RGB, exact App Store sizes). Bezel paths are set at the top of `compose.py`.
