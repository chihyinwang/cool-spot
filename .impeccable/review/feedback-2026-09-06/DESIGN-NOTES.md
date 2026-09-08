# Owner feedback revision — native extension

Recorded from the implemented SwiftUI slice on 2026-09-06. This is a bounded implementation record, not a replacement design system. Authority: [PRODUCT.md](../../../PRODUCT.md), the owner's feedback as recorded in [DECISIONS.md](DECISIONS.md), and the incumbent [implementation notes](../implementation-2026-09-05/DESIGN-NOTES.md). This record supersedes the earlier notes only for the report-reading hierarchy, presence example backdrop and arrival motion, public-form child navigation, and removed wheelchair-uncertainty row.

## Overview

Cool Spot retains its calm native teal/mint appearance, system navigation, grouped forms and explicit public commitment actions. The implemented changes make individual evidence easier to read, keep child editing within its parent task, and explain anonymous presence on a recognisable map. Saved Places/Pins remain part of the incumbent design.

Source evidence: `cool-spot/VisitorReportsView.swift`, `ExploreView.swift` (`CoolSpotPin`), `ContributionView.swift` and `PlaceDetailView.swift`. No new palette, business rule, persistence schema, real GPS, provider search or backend submission was introduced.

## Colors

Reuse the existing `AppStyle` tokens and native appearance-aware foregrounds. Report feelings and interactive actions use `brand`; body text uses primary; help/stay details and provenance use secondary. The shared presence badge retains primary text on `controlSurface` with `subtleBorder`; its place-type circle retains white symbols on `ink`.

The presence example now uses native MapKit tiles with muted standard-map styling. This replaces the former mint illustration field in this component only. It does not redefine the app's mint token or create a separate map palette. Canonical token values remain in the Swift source; no CSS token copy is introduced.

## Typography

Native SwiftUI text styles retain the hierarchy: headline for the available report feeling and place/section emphasis, body for the comment, subheadline for help and stay details, and caption for report provenance and visit time. The count badge uses semibold caption with monospaced digits. Public-form children use contextual inline navigation titles such as Photo and Note.

**The Complete Answer Rule.** Report feeling, comment, helped-feature labels, stay length and provenance grow vertically. The maximum Dynamic Type correction explicitly allows the detailed labels and their enclosing report content to wrap in full; neither truncation nor a fixed row height is the recorded pattern.

## Layout

Each individual report occupies a native List Section. Actual and example reports share `VisitorReportContent`: available feeling, comment, grouped help/stay details, then provenance and visit time. Thank-you controls sit below the reading content for reports that are not the user's own. Sharing a hierarchy does not require incomplete examples to contain the same fields as actual reports.

The map example scales its height with Dynamic Type and sits above its explanatory text and Pause/Resume control. The map does not pan or accept map interaction in this illustration. Native phone and tablet presentations retain the same content sequence.

Before you go retains its opening-hours reminder and public correction action. Only the wheelchair-uncertainty row was removed. Visitor reports, the wider section order and the correction action's position were not rearranged by this batch. Directions and Save remain the place page's priority actions.

## Elevation & Depth

Native list sections, form surfaces and sheet/navigation chrome provide the existing grouping and depth. The presence example adds real map context without introducing a new shadow vocabulary. Its count badge moves locally during arrival; the map and geographic anchor stay fixed. Existing shadows elsewhere are outside this revision.

## Shapes

The incumbent circular place-type marker and capsule count badge remain shared between Explore and `PresenceMapExample`. Reserved bottom-aligned space keeps the geographic anchor stable when the badge appears or disappears. Full digits remain visible; a zero count omits the badge. The example's rounded map clipping is local geometry, not a new app-wide radius scale.

## Components

### Individual report evidence

**The Evidence Before Recognition Rule.** Both actual reports and examples use the same reading component before any thank-you action. Only available facts appear: an incomplete fixture shows its comment and identifies itself as an Example report with “Visit date and response details unavailable.” It gains no invented feeling, helped feature, stay duration, visit date or author. Actual reports retain their visit time and answers. Aggregate totals do not create individual reports.

### Public contribution navigation

**The Back Preserves the Task Rule.** Photo, Note and other pushed public-form editors have their own inline title and native Back. They do not repeat a whole-form Close action. Back returns with the active draft intact. Main choose/minimum/ready pages retain Close, and dirty proposals show the existing discard confirmation.

The dirty interactive-dismiss guard remains. A UIKit presentation observer now routes an attempted dirty sheet dismissal to the same confirmation. Source review supports that wiring, but the callback was not triggered by the attempted CUA swipe and is not runtime-certified. The verified explicit Close path remains available; this record does not claim complete swipe or VoiceOver conformance.

### Presence illustration

The non-panning MapKit example uses the shared marker, visible native attribution and the label Example Cool Spot. It loops from 2 to 3. Only the arriving count badge briefly scales, tilts and lifts, then settles. The restart label and explanation distinguish the loop from ten-minute expiry and from any change to the real count.

Pause holds the displayed state and changes to Resume. Inactive scenes stop the loop. Actual OS Reduce Motion displays a static 3, suppresses arrival motion and looping controls, and retains the equivalent explanation. The map exposes a stable accessibility description rather than announcing every animation frame. Count remains anonymous shared presence, not seating, capacity or temperature.

### Proposals still awaiting preference

The following are discussion proposals, not implemented patterns or approved design-system rules:

- Inline/disclosed optional visitor fields and an immediately available comment field. The existing optional-page flow remains.
- One unified place picker with search/nearby and a map-position route, followed by recognised/named versus unnamed-place branching. The existing routes and labels remain.
- Replacing the identifying-photo confirmation switch with instruction and preview/replace/remove. The current boolean and photo validation remain.
- Moving Visitor reports before the remaining opening-hours reminder and reconsidering the public correction action's position. The existing broader order remains.

## Do's and Don'ts

- Do preserve actual answers, visit time, unknown values and clear Example/Demo provenance.
- Do use native child Back to retain the active draft and explicit root Close for whole-task cancellation.
- Do keep map position stable while the count badge demonstrates arrival; preserve Pause and equivalent Reduce Motion content.
- Don't treat shared visual structure as permission to fill missing fixture facts.
- Don't treat the removed wheelchair row as removal of stored accessibility data.
- Don't present the pending optional-field, picker, photo-switch or ordering proposals as approved or delivered.

Validation: [VERIFICATION.md](VERIFICATION.md) records a successful native build, **38 passing tests**, and native report, child-navigation and map evidence on phone/tablet across the named Light/Dark and maximum-type states. `presence-motion.mp4` and `motion-frames/` record the running badge transition; Pause and actual OS Reduce Motion have separate captures. Note → Back retained keyboard-entered text; changed Setting → Back → root Close produced the discard confirmation.

The first finish-review attempt errored; its retry delivered [VERDICT.md](VERDICT.md), with a **ship disposition limited to these four executed fixes**. That disposition excludes the pending proposals and does not certify the attempted-dismiss callback, physical-device swipe, or a complete VoiceOver audit. No whole-app accessibility certification is implied by the passing tests or captures.

Final preservation checks recorded in VERIFICATION.md found report journeys, local popsicle state and appearance unchanged against the pre-run backup after returning to the normal app. Only the original iPhone simulator remains booted; the temporary tablet simulator is shut down.

Not canonized: unresolved proposals, fixture gaps, simulated delivery and one-off geometry are not rules for future surfaces. No root DESIGN.md or web/CSS sidecar is created from this native slice; the existing dirty worktree is preserved.
