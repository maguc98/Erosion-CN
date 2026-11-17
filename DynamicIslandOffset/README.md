# DynamicIslandOffset

A separate SpringBoard runtime tweak for moving the Dynamic Island window downward on the physical iPhone 12 mini (iPhone13,1).

## Why this is separate from Erosion

Erosion's MobileGestalt editor changes cached device traits. It does not inject code into SpringBoard. Moving a live SpringBoard window requires a runtime hook inside SpringBoard, so this component is packaged as a Theos tweak (.deb), not as an ordinary sideloadable Erosion IPA.

## Implementation

- Hooks SBSystemApertureWindow -layoutSubviews only in com.apple.springboard.
- Checks the physical hardware identifier using hw.machine; it does not trust a spoofed ProductType.
- Adds a user-configurable vertical offset to the system-computed Y coordinate.
- Stores the system-computed baseline per window, so repeated layout passes do not accumulate the offset.
- The feature is off by default. The offset control is bounded to 0–80 points.
- If the expected class or selector is absent, the tweak does not install the hook and logs a diagnostic instead of guessing another private class.

## Compatibility status

The hook target and offset behavior have not been verified on iOS 27.3 Beta 1 or on the target phone. The public VisibleIsland project is the reference for the SBSystemApertureWindow layout approach; its source lists iOS 16.0–16.6.1 as the officially supported range and labels some device offsets as estimates. An individual issue reports VisibleIsland 2.0 working on iOS 26.0 with Dopamine/rootless on an iPhone 11, but that is not proof for iOS 27.3 or iPhone 12 mini.

This package requires a jailbreak/bootstrap environment compatible with the installed iOS version, a working tweak-injection substrate (for example, ElleKit/Substitute-compatible injection), and PreferenceLoader. Installing or sideloading the Erosion IPA alone is not sufficient. No exploit, jailbreak, or signing bypass is included.

## Test procedure

1. Confirm the device is physically iPhone13,1.
2. Back up the device and confirm that SpringBoard tweak injection is working on the installed iOS build.
3. Install the package using a compatible package manager.
4. Leave the feature disabled for the first boot; then enable it and adjust the offset in small steps.
5. If the island becomes misplaced, disable the feature and request a SpringBoard restart. Removing the package also removes the hook.

The default 30 pt is only a starting value, not a verified calibration for this device or iOS build.
