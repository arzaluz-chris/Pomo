# Device tests

UI tests that drive the installed Pomo app and SpringBoard on a real iPhone: start a session, kill the
app, expand the Dynamic Island, wait for the end, tap **Next** and check that focus starts.

```bash
cd tools/devicetests && xcodegen generate
xcodebuild test -project PomoDeviceTests.xcodeproj -scheme PomoDeviceUITests \
  -destination 'id=<iPhone UDID>' -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"
```

- Pomo must be a **Debug** build already installed on the phone: it reads `-PomoDebugAction startBreak`
  (and `-shortBreakDuration 1`) at launch.
- Connect the iPhone **by USB**. Over Wi-Fi `xcodebuild test` fails with
  "Root install style is not supported on this device" (CoreDeviceError 1001), although
  `devicectl device install app` works.
- Without a cable, the same checks run by hand: `devicectl device process launch ... -- -PomoDebugAction startBreak
  -shortBreakDuration 1`, `devicectl device process terminate --pid ... --kill`,
  `devicectl device capture screenshot`, and the timer state from the App Group plist
  (see SUBIR_A_APP_STORE.md / memory notes).
