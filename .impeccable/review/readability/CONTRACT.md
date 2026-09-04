# Place-detail readability pass — 4 September 2026

## Boundary

The owner reported that the page felt text-heavy and crowded, and explicitly required all previously agreed meaning to survive. This is an owner review, not a new first-time-participant finding. Use native SwiftUI as authority, not throwaway Web CSS.

This pass changes grouping, spacing, and relative visual weight only. **No user-facing string is deleted, shortened, or added.** A sorted string-literal comparison against the starting revision checks the full PlaceDetailView.swift file; visual and source checks also verify placement and behavior, which a string comparison alone cannot prove.

## Protected contract

- Preserve the photo, identity, distance/address, source badge, entry/seating and unknown hours.
- Preserve exact report fraction, cooling conclusion, latest timestamp, all three response counts and uncertainty caveat. No sensor temperatures, composite scores, invented recent window or per-feature votes.
- Preserve reviewed feature source, first-three preview, all-features expansion, wrapping and unknown-AC explanation.
- Preserve section order: identity → experience evidence → reviewed features → current-use count → visit planning → visitor reports and independent entry → presence contribution.
- Keep the count separate from the contribution action. Its ten-minute context remains visible, and current use does not guarantee effectiveness or capacity.
- Keep Directions and Save in the persistent safe-area action bar; do not change saving behavior.
- Keep the independent report entry, unselected initial answer, remote-disabled explanation and proximity/24-hour eligibility rules. Reporting never starts presence.
- Keep the first-time presence tip, permanent anonymity line, How this works sheet, nearby-only disabled state, success consequence, ten-minute duration and Stop sharing.
- Keep the optional three-way experience shortcut after presence, its separate meaning, explicit publication and optional causes.
- Do not edit models, report form, Saved, Settings, location simulation, expiry implementation, shared tokens or shared components.

## Spatial intent

The cooling conclusion and its evidence remain the first reading task. Use 32 pt between major sections, 24 pt within the identity/evidence group, 16 pt for related blocks and 8 pt for related text. These are local implementation choices, not universal UX constants.

Keep cooling features and current-use information adjacent but distinct. Keep explanatory captions visibly associated with their own actions. Use a compact outlined report button rather than full-page width; retain its label, icon, disabled treatment and touch size. Present visitor quotations as text with their attribution, without adding another enclosing card. Keep the presence card and all of its words, with more internal breathing room.

## Verification

- All 131 string literals in PlaceDetailView.swift match the starting revision, including count, punctuation and interpolation. No other Swift file changed.
- Byte-for-byte comparison confirms the evidence block, presence/report action block, quick-choice/report-form/help implementation are unchanged.
- `xcodebuild test`, iPhone 16 Pro iOS 18.2: 14 tests passed, 0 failures. Log: `/tmp/cool-spot-readability-test.log`.
- iPhone 16 Pro Light, iPhone 17 Pro Max Dark and iPad 11-inch M4 Dark captured. Dark on the iPhone used a process-only defaults argument for inspection; the user's stored appearance was not overwritten.
- Verified the seven-feature expanded list; independent report with no answer selected and Publish disabled; Cancel leaves people count at two. Starting presence changes it to three and keeps the success consequence, anonymity, ten-minute duration, Stop sharing and optional three choices.
- Maximum Dynamic Type on the smaller iPhone: report and presence buttons wrap; the 24-hour remote explanation and privacy line remain; How this works opens the full explanation sheet. The disabled report does not open a form. Restored the original large text-size setting afterward.
- Source regression review found no semantic changes. Its only requested fix, moving local 44-pt touch frames inside Button labels, was applied with a content shape.
- The independent final check confirmed that touch-target fix and found no obvious new layout regressions in the phone top, phone information and tablet expanded captures. No further changes were recommended within this pass.
- No HTML detector was used for native SwiftUI. No generated or replacement raster assets ship in the app.

Captures in this directory: `phone-light.png`, `phone-dark.png`, `phone-information.png`, `phone-presence-active.png`, `tablet-dark.png`, `tablet-expanded.png`, `phone-large-type-top.png`, `phone-large-type-report.png`, `phone-large-type-presence.png`. Midpage captures deliberately show a scrolled region; content outside that region remains scroll-accessible.

Runtime checks do not establish participant comprehension or complete accessibility conformance; unchanged global contrast and top-right overlay behavior are outside this layout pass. The next usability task remains the 30-second decision test.
