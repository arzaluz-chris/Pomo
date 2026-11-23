# App Store screenshots

Raw captures come from the simulators with DEBUG demo data (`-PomoDemoData YES`,
`-PomoDemoState running|break|paused|idle|adjusting`). The store images are composed in a private
claude.ai page, "Pomo para App Store", with Apple's device frames (Apple Design Resources, licensed
for app mockups only: never commit them to this public repo).

## 1. Capture

`capture.sh RAW SIM_UDID DEVICE [DISPLAY]` shoots one simulator in Spanish and English, light and
dark: timer running, timer being adjusted (hold and slide), break, statistics and settings.

- iPhone 6.9″ (iPhone 18 Pro Max, 1320×2868): `capture.sh RAW <udid> iphone`
- iPhone Duo outer screen (1398×2034): `capture.sh RAW <udid> duo-folded LCD`
- iPhone Duo inner screen: the simulator has to be unfolded by hand in DeviceHub; capture with
  `simctl io <udid> screenshot --display=LCD-1` into `duo-unfolded` (landscape, 2853×2007) or
  `duo-unfolded-portrait` (2007×2853), same `<lang>/<mode>/NN_name.png` layout.
- Apple Watch (Series 11/12 46 mm, 416×496): a raw capture per language at `RAW/watch/<lang>/watch.png`.
  These go to App Store Connect as they are, without a frame.

Captures taken before the app finishes drawing come out blank: `WAIT=25` gives it more time.

## 2. Compose

`python3 -I artifact/build.py RAW DUO_DIR OUT` writes the page (`index.html`, `shots/`, `thumbs/`).
It is published as a claude.ai artifact with the frames copied in from the MemoMed store page.
In the page: pick the language (Español / English), the device tab, edit titles, background
("Cocina" colors per screen), template and frame, then download each PNG (24-bit, no alpha) or
the whole set as .zip.

`artifact/template.html` started as MemoMed's store page (MemoMed repo,
`artifacts/store-screenshots/documentation/scripts/store-art`) and is adapted to Pomo: palette,
rounded type, two languages, the Apple Watch in front of the iPhone, and no iPad.

`compose.py` is the earlier offline composer (Pillow); it still works for quick checks.
