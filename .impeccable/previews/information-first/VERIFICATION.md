# Information-first native revision

Implemented 3–4 September 2026. Scope: the existing SwiftUI place detail and shared components; not the throwaway Web prototype or a production-service rebuild.

## Design basis and method

- Preserve the chosen photo, restrained teal/mint/sky palette, SF text, native sheets and persistent Directions/Save.
- Clear information is primary; collecting reports is secondary. Separate reading the current-use count from the presence-contribution invitation.
- Impeccable clarify → layout → native adapt → harden → polish. Layout used two independent, read-only sub-agent assessments, followed by a separate final source review.
- The layout detector was attempted before and after edits, returning `[]` / exit 0. It has no meaningful SwiftUI coverage; this is not a native-quality pass. No Web substitute or overlay was used.
- Backlog source: `.impeccable/critique/2026-09-03T19-10-46Z__cool-spot-placedetailview-swift.md`.

## Root causes addressed

- Conceptual misalignment: contribution UI preceded decision-critical information. Reordered the detail, moved entry/seating/hours into the header, moved the complete three-way distribution beside its summary, and separated count from contribution action.
- Incorrect evidence abstraction: the largest category was described as a majority. `CoolingEvidence` uses exact report fractions, ties and zero-report states. Freshness now includes submitted reports for the same place.
- Shared-state implementation gap: button styles ignored `isEnabled`. Both styles now have disabled appearances; an unanswered report explains the requirement before Publish.
- Layout constraint gap: individual flow items were unconstrained, and actions always used two columns. FlowLayout now proposes bounded widths; accessibility-size actions and distribution rows change structure.
- Data-visualisation contrast: distribution bars now use the adaptive brand foreground, rather than the low-contrast mint surface role.

## Layout verification

| Check | Evidence |
|---|---|
| Squint test | `CoolSpotDetailView.experienceSummary`: one dark summary surface; contribution buttons use SecondaryButtonStyle. |
| Rhythm | Detail section gap 24 pt, inner evidence/feature gaps 12 pt, header gap 8 pt. Removed standalone dividers that unintentionally doubled outer gaps. |
| Hierarchy | `body` orders identity/entry facts, summary/full distribution, features, current-use count, planning, visitor details/report action, presence action. |
| Breathing room | Shared 20 pt content inset and 16 pt summary padding; minimum 44 pt Close and feature-disclosure targets. Native screenshots preserve the photo without placing a contribution CTA above the evidence. |
| Consistency | Shared PrimaryButtonStyle/SecondaryButtonStyle and AppStyle colour roles; no Web CSS imported. |
| Adaptation | `actionBar` stacks at accessibility sizes; `ExperienceDistribution` reflows label/count above bars; FlowLayout measures and places bounded-width children. |

## Verification performed

- Xcode build succeeded. XCTest: 12 tests, 0 failures, on iPhone 16 Pro / iOS 18.2.
- Tests cover plurality wording, two- and three-way ties, zero reports, one-report wording, matching-bucket updates, report timestamps isolated by place, report independence, proximity, the 24-hour boundary, no remote extension and saving not granting eligibility.
- Native iPhone 17 Pro Max / iOS 26.4: normal and largest accessibility text sizes; all seven features expanded with complete wrapped labels; full Directions/Save labels; disabled Publish; independent report starts blank; explicit publishing updates 8→9 and Latest while people stay at 2; presence separately updates 2→3 and reveals a preselected but unpublished report shortcut; dark-mode information and contribution sections.
- Native iPhone 16 Pro / iOS 18.2: smaller-screen library and park screenshots, light/dark appearances; 6/14 plurality visibly accompanied by all three counts.
- Final whitespace check passed. No claim of a timed participant test or improved comprehension rate.

## Deliberate limits

- The questionnaire layout and missing place-name context in that form remain deferred; this pass fixes its disabled button, not the whole form.
- Real GPS, persistent state, actual ten-minute expiry, moderation and production anti-abuse are not implemented. Live-presence counts remain prototype fixtures/in-memory state; the UI is not evidence that the service semantics are ready to ship.
- Zero/tied states were unit-tested, not injected into native screenshots. Full VoiceOver traversal, real-device glare/performance, landscape and iPad were not audited.
- During the resumed verification, the user was interacting with iPhone 17 Pro Max. Its current view was left alone; remaining screenshots used iPhone 16 Pro. The latter was restored to its original light appearance and large text size.

## Next validation

Use the Information-first retest in `PROTOTYPE-TEST-GUIDE.md`: can a person explain whether they would go, their evidence, and what remains unknown within 30 seconds? A justified decision not to go is valid. Do not prioritise report-form redesign until the core information task is tested.
