## verdict

1. Resolved — Meaningful update validation: `changes` now compares normalized text; `canSend` rejects edited nil Setting/Type and invalid image data, ignores bookkeeping-only/blank changes, and requires a removal reason when the final cooling feature is removed. Focused `ApprovedContributionTests` cases pass in `/tmp/cool-spot-approved-tests.log`. The recaptured tablet update screen retains its explicit no-change state. This semantic resolution is supported by inspected source and tests, not inferred from a static screen.
2. Resolved — Duplicate reconciliation: the existing spot initializes the new baseline, then only changed incoming key paths are applied. Untouched access/seating survive; proposed Type/Setting remain distinct from original values for comparison. The focused duplicate test verifies both preservation and explicit overrides and passed. Original identity remains intact.
3. Resolved — Private Pin eyebrow: the re-read `phone-pin-light.png` removes the small label above “Shade near the river,” closes the gap naturally, and retains the native “Saved pin” title and clear privacy statements.

All prior screenshot paths were re-read. No fix-batch visual regression was found. The additional native captures close the previously pending visual evidence: `tablet-markers-digits-light.png` clearly distinguishes 3, 10 and 100; `phone-place-reports-light.png` shows the single labelled preview, View all, preserved stay disclosure and secondary contribution control; `phone-report-large-footer-dark.png` shows the full maximum-type Publish button; `phone-report-published-large-dark.png` shows the completed maximum-type publication state. Parent-reported native accessibility Scroll Up/Down and Publish actions support operation of that report path; full VoiceOver and hardware testing remain outside this verdict.

## remaining

Clear. Ship covers the three scored fixes, not a fresh audit of the whole surface.

disposition: ship
