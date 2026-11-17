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


## Further injection-path research (2026-11-17)

### 5. A modern public tweak runner exists, but it is not for this device

The public Liter8 project demonstrates that a tethered, non-TrollStore jailbreak environment can provide a real SpringBoard tweak loader: its documentation describes ElleKit, Objective-C hooks, C-function hooks, and the ability to install a dylib under `/var/jb/usr/lib/TweakInject/` and respawn the target.

But its own support statement is explicit:
- Device target: **iPhone 11 only** (`iPhone12,1`, A13).
- iOS 27.3 beta 1 (`24C5037i`): marked `run` for iPhone 11 only; iPhone 11 Pro / Pro Max marked `experimental`.
- It does not claim iPhone 12 mini (`iPhone13,1`, A14) support.
- The workflow is tethered: it requires a Mac and pwn-DFU boot each time.
- The restore step erases the phone; its README says SEP and passcode do not work.
- The tweak-loader instructions say the tested ElleKit setup was device-tested on iPhone 11 (`n104ap`) on build `24B5099f`; no other build was boot-tested with a C hook.

This is a useful proof that a system-level hook is technically possible in a different, specifically supported environment. It is **not a usable or safe porting target for the user's A14 iPhone 12 mini**. Do not attempt its restore/boot workflow on the user's device.

Sources:
- https://github.com/Xplo8E/Liter8
- https://github.com/Xplo8E/Liter8/blob/main/docs/USING_TWEAKS.md

### 6. Independent iOS 27 exploit research does not establish a route for this A14 build

The public `SKVLENT/iOS27-Research-Exploits` status page says its measured configuration is iPhone 17 Pro (A19 Pro) on iOS 27.0.1 and iPhone 16 Pro Max (A18 Pro) on iOS 27.2. It explicitly states that kernel read/write and a jailbreak were not demonstrated in the first configuration, and clarifies that its demonstrated sandbox escape crosses a container boundary in userland; it does not provide kernel code execution, root, or unsigned-code execution outside the sandbox.

Those measurements do **not** prove that no exploit exists on every device/build, and they are not measurements on iPhone 12 mini / A14 / 24C5037i. They do, however, provide no basis to claim a generic iOS 27 kernel exploit or SpringBoard injection method is available for this target.

Source:
- https://github.com/SKVLENT/iOS27-Research-Exploits/blob/main/STATUS.md
- https://github.com/SKVLENT/iOS27-Research-Exploits/blob/main/README.md

### 7. Current go/no-go decision

| Candidate | Why it is not usable here |
|---|---|
| Erosion / `worse_query` | Filesystem sandbox extension; no process injection or kernel execution |
| VisibleIsland Theos tweak | Correct historical hook idea; old iOS 16 support only, no verified 27.3b1 runtime |
| Cyanide / DarkSword | The documented kernel exploit window does not include iOS 27.3b1 |
| Liter8 | Has a real tweak loader, but explicitly supports iPhone 11 (A13), not iPhone 12 mini (A14); destructive tethered restore workflow |
| Calif research demos | No public end-user injection tool or released supported chain for this exact device/build was identified |

**Result:** no verified non-TrollStore SpringBoard injection route for iPhone 12 mini / A14 / iOS 27.3 beta 1 has been found in the public sources inspected on 2026-11-17. Do not compile or install a live offset tweak until that prerequisite is met.

### 8. Next non-invasive research step

If work continues without a supported injection environment, the remaining useful task is static analysis of the exact `24C5037i` firmware for the SpringBoard aperture classes and their layout call paths. The class name `SBSystemApertureWindow` is a historically observed target, but its presence and method behavior must be confirmed against this exact build before writing a hook. Static class discovery is not a substitute for runtime validation.
