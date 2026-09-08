# Native verification — human-centred revision

## Scope and authority
The owner authorized implementation of the discussed report, place-detail and contribution improvements. The latest annotation explicitly requires newest report preview regardless of author. The work extends the existing native visual system. No web detector ran.

## Build and tests
The first complete implementation built and passed 41 tests. The one correction batch addresses maximum-text place-context wrapping, redundant context copy, full-width map confirmation, accurate waiting-for-review wording and disabling Send while a replacement photo finishes loading. After that correction batch, all 41 tests passed again (`/tmp/cool-spot-human-centred-tests-final.log`, TEST SUCCEEDED). `git diff --check` is clean.

## Interaction evidence
- From chooser, selected Riverside Café and reached the form directly, without minimum/ready screens. Selected Indoors and Air conditioning; Send became enabled before optional questions were answered.
- Expanded Entry and seating in the same form. Closed the form to show discard confirmation; dismissed that prompt and used native Back. Reselected the same café: Indoors, selected Air conditioning and enabled Send were retained.
- Change to another place produced the explicit clear-answers confirmation. No real data was discarded; all contribution actions were in a memory-only inspection store.
- Saved-pin entry displayed the original example anchor with a single Use this spot action. Confirming it opened an unnamed-location form with blank public name/note, without copying the private saved title/note.
- Chose Outdoors, Tree shade and public-entry confirmation. Native PhotosPicker showed the Simulator sample library; chose the waterfall sample. Loading completed to a preview, Replace/Remove and enabled Send, with no photo self-confirmation switch. Send reached the waiting-for-review completion page in the memory-only store. No backend is connected.
- In the one-page visit report, typed a clearly labelled layout-test comment through native keyboard events, expanded What helped and scrolled; the comment remained intact and Publish stayed enabled. Earlier regression tests cover Finish later, original visit time, persistence and independent report eligibility.
- The actual owner report/comment/date are copied into memory for the report-list/place-detail reading checks. They are never replaced by fixture answers. Complete peer examples have fixed synthetic dates and explicit Example provenance. Tablet peer-first preview also contains a clearly named older personal layout-test report solely in the inspection store.

## Native capture matrix
All PNGs are unedited simctl screenshots. Phone: iPhone 17 Pro Max iOS 26.4, 1320×2868. Tablet: iPad Pro 11-inch M5 iPadOS 26.4, 1668×2420. Light/Dark and accessibility5 are view-scoped debug overrides; normal preferences are not changed.

- phone-chooser-light.png — search, nearby and one map route.
- phone-new-place-light.png / tablet-new-place-dark.png — known-place single form.
- phone-optional-inline-light.png — optional fields expanded in the same form.
- phone-close-confirmation.png / phone-change-confirmation.png — distinct exit and new-place safeguards.
- phone-saved-pin-light.png — original pin and confirmation.
- phone-photo-ready-light.png / phone-sent-for-review.png — decoded photo without toggle, completion.
- phone-reports-light.png — owner newest, complete same-format example.
- tablet-reports-peer-dark.png — example newer than the older synthetic personal report.
- phone-reports-large-dark.png — full report wrapping at maximum text.
- phone-report-form-light.png / phone-report-inline-expanded.png — direct comment and optional answers.
- tablet-report-form-large-dark.png — native report form at maximum text.
- phone-place-preview-light.png — latest report with provenance, tighter grouping, no Before you go.
- phone-update-light.png — contextual edit opens prefilled update form.
- phone-new-place-large-dark.png — final confirmation of stacked place context at maximum text.

First-round inspection was batched across these production views. Corrections were made together. The confirmation round verified stacked maximum-text context, final normal-size form, full-width map confirmation, native photo loading → enabled Send, and the final waiting-for-review message. Corresponding PNGs were replaced with final-build captures; unchanged screens retain valid first-batch captures. Every named file was opened and checked before handoff. Independent finish review follows. Native screenshots verify named states, not an exhaustive physical-device or VoiceOver audit. Gesture-only dismissal is not required; explicit Close and draft protection remain. External real search/GPS, moderation, accounts and uploads remain out of prototype scope.

## Preservation
Before work, source snapshots were copied into before/. Device preferences were backed up outside the repository at /Users/chihyinwang/.codex/cool-spot-device-backup-human-centred-2026-09-06/com.chihyinwang.cool-spot.plist. At final confirmation, every app-preference key matched the pre-work backup exactly, including report journeys, popsicle reactions and appearance. The phone was relaunched into the normal app without preview flags; the temporary tablet was shut down. No test report or public contribution was written to the owner’s persistent store. No commit or push was requested.

## Independent review correction — round 1
The full independent review found two material finish issues (REVIEW.md): low-contrast supporting text/field prompts and bordered feeling controls nested inside a grouped Form. The one requested correction batch introduces opaque appearance-aware AppStyle.supportingText on the changed input/evidence roles and flattens ReportChoice into full-row native selection controls. Selection still has a checkmark plus semibold brand text and a minimum 44-point target. Disabled Send remains distinct. No flow, sorting or persistence rules changed.

All 41 tests passed after this batch (xcodebuild exit 0, /tmp/cool-spot-human-centred-review-fixes.log). Source color contrast is approximately 7.70:1 against white, 6.90:1 against the Light grouped surface, and 7.90:1 against Dark grouped surface; rendered evidence is scored by the reviewer.

Fresh final-build captures replace nine same-name files: phone-chooser-light, phone-new-place-light, tablet-new-place-dark, phone-new-place-large-dark, phone-reports-light, tablet-reports-peer-dark, phone-reports-large-dark, phone-report-form-light, tablet-report-form-large-dark (all .png). Each was opened. The remaining files show previously validated interaction states before the color-only correction, not final text colors. The Mac locked during capture: CUA could not click/scroll and requested a manual unlock; the owner was asked. Native simulator launch/capture remained available. No alternate event automation or lock bypass was used. The scoped verdict (VERDICT.md) scores the native feeling rows resolved and contrast partial only for missing final-build evidence in two views: expanded Entry and seating prompts, and place-preview provenance. No additional code defect or broader testing is requested. These two recaptures await manual unlock.

After the last code correction, the phone was returned to the normal app, the tablet shut down, and all app preference keys again matched the original backup.
