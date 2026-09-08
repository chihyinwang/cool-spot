# Feedback revision verification — 6 September 2026

Scope: four clear user-requested refinements; optional-answer, place-picker and photo-switch alternatives plus broader ordering remain discussion proposals in DECISIONS.md. User screenshots user-1.png through user-7.png were preserved unchanged.

## Build and checks

- Native xcodebuild build succeeded, then test succeeded: **38 tests passed**. Final log `/tmp/cool-spot-feedback-tests.log`; build `/tmp/cool-spot-feedback-build`.
- No report/presence/persistence schema or photo validation rules changed. Existing tests cover those rules. The final correction fixes maximum-text report labels to wrap in full.
- `git diff --check` passed.

## Native evidence

All PNGs are unedited Simulator captures. iPhone 17 Pro Max / iOS 26.4: 1320×2868. iPad Pro 11-inch M5 / iPadOS 26.4: 1668×2420. Preview screens use the production views in native sheets; actual local reports are copied into memory for reading-only presentation checks, with no injected actual-report answers or dates.

- phone-reports-light.png: actual owner report and incomplete example share hierarchy; preserved visit date/comment/answers.
- phone-reports-large-dark.png and phone-reports-large-details-dark.png: accessibility5 reflow, fully wrapped features/stay/provenance after native accessibility Scroll Down.
- tablet-reports-dark.png: tablet missing-answer fixture treatment.
- phone-place-light.png: wheelchair row removed; section order/correction placement retained pending discussion.
- phone-note-child.png: contextual child title and native Back, no whole-flow Close.
- phone-close-confirmation.png: changed Setting retained on Back, main Close gives discard confirmation.
- phone-presence-light.png and tablet-presence-dark.png: loaded native MapKit tiles/attribution behind the shared marker.
- phone-presence-reduce-dark.png: actual OS Reduce Motion enabled, static count 3 with equivalent explanation.
- phone-presence-paused.png: actual Pause tap changes to Resume and holds 3.
- presence-motion.mp4: native recording of the running loop. motion-frames/00.png–17.png are unedited video frames at 250ms intervals over one complete cycle; extracted with AVFoundation. The badge briefly scales, lifts and rotates; the map stays fixed.

Map tiles in the initial tablet capture had not loaded; it was recaptured with visible real tiles. The maximum-type first inspection exposed truncated help/stay labels; one correction batch made labels and their row vertically self-sizing. No open-ended polish pass was performed.

## Interaction evidence and limits

- Native Back after typing a Note retained its text and enabled Send with a meaningful delta. AX setValue alone changed displayed text without firing the editable-control event; the verification was repeated using focused keyboard typing, and the actual draft summary was checked.
- Changed Setting from Indoors to Both in the child, returned, saw the before/after delta, and invoked main Close: confirmation appeared. These checks ran in memory-only previews.
- No gesture-only path is required: main Close remains accessible and dirty interactive dismissal remains guarded. The new UIKit observer forwards attempted native dismissal to the same confirmation. CUA coordinate-drag and escape attempts did not visibly trigger a swipe; the swipe-attempt callback therefore is not runtime-certified. Physical-device swipe and complete VoiceOver remain untested; do not claim an exhaustive Apple-conformance audit.
- Pause held the displayed count; Resume and Reduce Motion use the existing cancellation/state rules. The OS Reduce Motion setting is restored to its original false value after capture.

## Preservation

Device preferences were copied before launch/build to `/Users/chihyinwang/.codex/cool-spot-device-backup-2026-09-06/com.chihyinwang.cool-spot.plist`, outside the repository. Final stored-data comparison and simulator restoration are recorded at completion. No public proposal was sent to a backend; no fixture reaction was sent. Photos, Saved and report rules were not migrated or reset.

## Completion

- Final device preference comparison after returning to the app: `prototype.reportJourneys.v1`, `prototype.popsicles.v1`, and `appAppearance` are byte-for-byte/value unchanged from the pre-work backup. Only the originally booted iPhone remains booted; the QA tablet is shut down.
- The first finish reviewer failed during its follow-up execution. A fresh independent retry inspected the required native captures and sampled motion frames and returned `ship` for the four executed fixes in VERDICT.md. Pending design choices and unverified swipe behavior are explicitly outside that disposition.
- Final `git diff --check` passed.
