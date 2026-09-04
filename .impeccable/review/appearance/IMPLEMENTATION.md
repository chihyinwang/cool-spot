# Appearance setting

## Scope and behavior

The local Settings addition preserves the existing native iOS visual system. It does not establish a new visual world, change product documentation, or add shipping raster assets.

- Open **You → Settings → Appearance**.
- **Match System** is the default and follows the device appearance; **Light** and **Dark** explicitly override it.
- Selection is stored locally with `@AppStorage` under `appAppearance`, survives relaunch, and is applied at the root view with `preferredColorScheme`.
- Settings uses a native `Form`, inline `Picker`, standard navigation, and system typography. It inherits the existing adaptive teal/mint palette. The Settings entry has a minimum height of 44 points.
- The explanatory footer uses semantic `.primary` foreground styling after review identified insufficient contrast in Light appearance. Final post-fix visual verification remains pending.

This follows `PRODUCT.md`'s native iOS conventions and requirement to support Dark Mode; it does not change the app's primary cooling-place discovery task.

## Source references

- `cool-spot/PrototypeModels.swift:9` — `AppAppearance` cases, labels, storage key, and optional color-scheme mapping.
- `cool-spot/PrototypeModels.swift:34` — incumbent adaptive `AppStyle` palette.
- `cool-spot/ContentView.swift:4` — persisted preference; line 41 passes the binding to `YouView`; line 54 applies the root appearance.
- `cool-spot/SavedYouViews.swift:288` — Settings navigation entry.
- `cool-spot/SavedYouViews.swift:377` — `SettingsView` and footer contrast adjustment.
- `cool-spotTests/cool_spotTests.swift:7` — appearance mapping test; line 14 covers default selection and persistence using an isolated preferences suite.

## Test evidence

Recorded command, run from the project root:

```sh
xcodebuild -project cool-spot.xcodeproj -scheme cool-spot \
  -destination 'platform=iOS Simulator,id=74E09CED-0FA8-41C8-84C1-5AD61C4DEFB7' \
  -derivedDataPath /tmp/cool-spot-tests-information \
  -parallel-testing-enabled NO test
```

`/tmp/cool-spot-appearance-test.log` records **TEST SUCCEEDED** on 2026-09-04 at 09:33 BST: 14 tests, 0 failures, on the iPhone 16 Pro simulator with iOS 18.2. Both appearance-specific tests passed. Results bundle: `/tmp/cool-spot-tests-information/Logs/Test/Test-cool-spot-2026.09.04_09-33-16-+0100.xcresult`.

This documents an existing run, not a new documenter-run test. The log establishes mapping and persistence behavior; it does not establish a final post-contrast-fix visual pass or physical-device accessibility validation.

## Screenshot inventory

Existing review files in this directory, inventoried without a new visual audit:

| File | Dimensions | Named scenario |
| --- | --- | --- |
| `phone-light.png` | 1320 × 2868 | Light appearance |
| `phone-dark.png` | 1320 × 2868 | Dark appearance |
| `phone-match-system.png` | 1320 × 2868 | Match System selection |
| `phone-large-type.png` | 1320 × 2868 | Large Dynamic Type |
| `phone-detail-after-relaunch.png` | 1320 × 2868 | Detail after relaunch |
| `tablet-dark.png` | 1668 × 2420 | Tablet dark appearance |

Screenshot names describe their intended scenarios, not an independent verification verdict. The implementing agent must record the final post-fix visual verdict before treating this review as complete.
