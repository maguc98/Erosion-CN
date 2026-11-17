# Dynamic Island Y-Offset Investigation

## Goal and scope

Target: iPhone 12 mini (`iPhone13,1`, A14), iOS 27.3 beta 1, build `24C5037i`.

The only in-scope goal is to move the **real SpringBoard Dynamic Island UI downward** so that it is no longer obscured by the physical notch. Siri edge animations are explicitly out of scope for this investigation.

The intended control, once a supported system injection route exists, is a user-adjustable vertical offset (Y). Horizontal offset should remain centered by default. No MobileGestalt subtype value should be presented as a position control.

## Findings

### 1. The actual position hook used by existing work

VisibleIsland declares and hooks `SBSystemApertureWindow` and adjusts its frame in `-layoutSubviews`. This is the correct *kind* of system-level target to investigate because it changes the system aperture window after its layout pass.

However, the project README documents full compatibility only for iOS 16.0–16.6.1. The code's `iPhone13,1` branch sets `frame.origin.y = 19.5` and labels the value as an estimate. It is not a verified iPhone 12 mini calibration, and it is not evidence that the selector or window hierarchy is unchanged on iOS 27.3 beta 1.

Sources:
- https://github.com/ethxnn88/VisibleIsland
- https://github.com/ethxnn88/VisibleIsland/blob/main/Tweak.xm

### 2. Erosion's current exploit is not a SpringBoard injection mechanism

The upstream Erosion implementation uses `worse_query` to request an App Group container sandbox extension. The implementation creates a temporary symlink under the App Group's `Library/Caches`, performs a container query, consumes the returned sandbox token, and then cleans up the symlink.

That mechanism gives the app access to selected filesystem paths. The inspected Erosion source does not implement RemoteCall, SpringBoard task injection, a tweak loader, or a dyld injection path. Adding a Y-offset slider to Erosion alone would only change Erosion's own UI or stored preference; it would not move SpringBoard's Dynamic Island.

Sources:
- https://github.com/jailbreakdotparty/Erosion/blob/main/Erosion/Exploits/worse_query.m
- https://github.com/jailbreakdotparty/Erosion/blob/main/Erosion/Exploits/WorseQuerySwift.swift

### 3. The other public injection candidates do not match this build

- Cyanide's published DarkSword-based runner documents tested support through iOS 26.0.1 (and older 17.x–18.x releases). It states that the kernel bugs it uses were fixed in 26.1. This does not cover iOS 27.3 beta 1.
- Troy's README states that its Cryptex installation bug was patched and Apple no longer signs custom Cryptex1 images, so new installs cannot be produced.
- Erosion's `worse_query` support for build `24C5037i` is valuable for filesystem customization, but it does not turn the app into a kernel exploit or SpringBoard tweak runner.

Sources:
- https://github.com/d1y/cyanide-ios
- https://github.com/jakeajames/tr0y
- https://github.com/jailbreakdotparty/Erosion

### 4. Avoid treating MobileGestalt display fields as offsets

`ArtworkDeviceSubType` and `DeviceSupportsDynamicIsland` describe device/display capability state, not a SpringBoard window coordinate. A public report on a notched iPhone running iOS 27.2 also records that changing ArtworkDeviceSubType values did not fix the resulting status-bar geometry. This is consistent with keeping subtype experiments separate from actual window positioning.

Source:
- https://github.com/rooootdev/mond/issues/150

## Current conclusion

There is a known historical implementation pattern for moving the Dynamic Island: hook `SBSystemApertureWindow -layoutSubviews` and adjust its Y origin. There is **not yet a verified, non-TrollStore SpringBoard injection route for this device/build** in the sources inspected.

Therefore, do not package the old Theos hook into the Erosion IPA and imply it will run. Do not install the previously drafted unverified DynamicIslandOffset tweak. A successful Theos build or IPA build would not prove SpringBoard injection or on-device functionality.

## Implementation gate

Before writing or installing a live tweak, all of the following must be demonstrated:

1. A non-TrollStore execution/injection path that actually targets SpringBoard on iOS 27.3 beta 1, build `24C5037i`, on A14.
2. Runtime confirmation that `SBSystemApertureWindow` exists on that exact build and that `layoutSubviews` is still the correct layout point.
3. A minimal hook that changes only the aperture window's Y origin, without hiding the Magicians Curtain view or changing notification/banner windows.
4. A reversible preference with a bounded Y-offset range and a default/off state.
5. A device test confirming the Dynamic Island moved and remains correctly centered during idle, Live Activity, media playback, calls, and notifications.

Until gate 1 is met, only source research and non-invasive diagnostics are justified. The app must not label a preview or stored number as a working system offset.

## Version warning

The upstream Erosion README currently states that `worse_query` is patched in iOS 27.3 beta 2 (`24C5049d`). The target device is reported to be on beta 1 (`24C5037i`); preserving that build matters if Erosion's current filesystem capability is still needed. Re-check compatibility before any OS update.

Source:
- https://github.com/jailbreakdotparty/Erosion/blob/main/README.md
