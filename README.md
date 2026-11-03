# Screen to 11

Screen to 11 is a menu bar app that requests EDR headroom on the built-in display and applies a click-through multiply overlay to brighten ordinary content. It uses public AppKit and Metal APIs. The actual gain is capped continuously by `NSScreen.maximumExtendedDynamicRangeColorComponentValue`; the slider's upper request is based on `maximumPotentialExtendedDynamicRangeColorComponentValue`.

## Build and run

Requires macOS 13 or later and Xcode with Swift 5.10 or later.

```sh
make test
make app
open dist/ScreenTo11.app
```

The app starts with boost **off**, including after login or a relaunch. Only the slider level is saved. To enable Launch at Login reliably, move the built app to `/Applications` before registering it; macOS may require approval in System Settings → Login Items.

## Physical display check

On an EDR-capable MacBook Pro, set macOS brightness to 100%, open the menu bar icon, and turn on boost. Compare the same ordinary desktop content with boost off and on, then move the slider. Confirm that mouse and keyboard input pass through, test another Space and a full-screen app, and turn boost off or quit. Screenshots do not establish increased emitted brightness, so this check must be made by looking at the panel.

On November 3, 2026, the Mac14,6 running macOS 15.8.1 was checked on its built-in panel: boost visibly brightened ordinary content at macOS brightness 100%, the slider changed the result, mouse and keyboard input passed through, full-screen apps remained usable, and Off and Quit immediately restored normal appearance. The remaining Space-swipe behavior is noted below.

If the built-in display is not available in the launch session, or its potential headroom is 1.0×, the switch and slider are disabled and the menu explains why. Current headroom can also fall while the app is running, such as from brightness or thermal conditions; the effective gain follows it.

### Space transition limitation

On macOS 15.8.1, the boost can temporarily fade during the animated swipe between Spaces, then return when the swipe completes. The overlay windows stay visible with stable window IDs and the display's reported EDR headroom stays constant during the gesture. This appears to be how WindowServer composites all-Spaces windows into the transition. The app keeps its overlays alive across Spaces, but public AppKit window controls did not remove that transient fade in physical testing.

The app does not use screen capture, private display APIs, or gamma tables. The EDR overlay technique is described in [MaxNits](https://yogeshvar.github.io/maxnits.html); this is an independent implementation.
