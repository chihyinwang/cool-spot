# Owner feedback and bounded revision — 6 September 2026

Authority: the owner's seven screenshots and feedback override the earlier finish verdict. This is an extension of the existing native SwiftUI design, not a new visual system. Saved Places/Pins were explicitly liked and are preserved.

## Implemented clear requests

- Visitor reports now share one `VisitorReportContent`: actual feeling when present, comment, grouped help/stay facts, then provenance/time. Each report gets a native List Section. Missing fixture answers/dates remain absent; actual and example are not forced to contain the same facts. No authors or reports were invented. The current phone preview copies actual persisted reports into a memory-only store for visual verification.
- Presence illustration is a native non-panning MapKit view with Apple attribution and the existing CoolSpotPin. Only the badge gains a small arrival scale/rotation/lift across the 2→3 transition. The map itself stays still. Pause/Resume and static Reduce Motion 3 remain.
- Remove the wheelchair-uncertainty row from Before you go for MVP. No stored data or source fields are erased.
- Photo, Note and other public-form children use contextual native titles and Back, without a competing whole-form Close. Main choose/minimum/ready screens retain Close and discard confirmation. A UIKit presentation observer connects attempted dirty sheet dismissal to the same confirmation, while the existing interactive-dismiss guard protects drafts. No child Back calls the sheet-level dismiss.

## Discussion — not applied without the owner's preference

Three asynchronous preference questions were offered. No answer had arrived when this record was written; suggestions below remain proposals, not silently approved changes.

1. **Visitor report optional details.** Recommend native same-page disclosure for What helped and stay, with an immediately available comment field. That lowers navigation effort while leaving the initial required question short. Keep the owner-liked public-place optional pages. Compare both versions by completion, hesitation and optional-answer quality, not click count alone. NN/g progressive-disclosure guidance supports moving advanced/rare tasks aside, but does not establish that these three commonly useful answers should each require a separate page, nor prove any conversion effect for this app.
2. **Place selection.** Recommend one search/nearby page and one “Choose a spot on the map” action. Only after the position is confirmed ask whether the real-world place has a name (shop/park) or is an unnamed outdoor point (shade/river seating). All entities have coordinates; presence of a recognised place identity is a separate fact. Existing-provider results can already exist in maps without being reviewed Cool Spots. The old internal terms are not required product vocabulary. This unification and branch sequencing await the owner's preference; neither new labels nor duplicate-route removal were partially applied.
3. **Identifying-photo switch.** It was a self-confirmation, not a photo-quality detector. Recommend pre-pick instruction and visible preview/replace/remove, without a separate blocking toggle. Exact spots would still require a decoded image and legal public access; image suitability would remain a review concern. Awaiting preference, so the current boolean and validation remain unchanged.

## Explanation and proposed ordering

`Add or correct place details` edits a reviewed Cool Spot's public facts. `Add cooling information` on a recognised map place proposes cooling information for its first Cool Spot review. Both use the same contribution form but have different initial status; a place existing in the map provider does not mean it is already a Cool Spot. Visit report remains one visit's experience, not those public facts.

Before you go preceded the report preview to surface practical trip constraints before detailed evidence. Opening/access conditions can determine whether someone can go at all; this is a product judgment, not an Apple-required section order. At this MVP stage the section now contains only a generic opening-hours reminder, so it need not outrank the individual report preview. Recommend placing Visitor reports before that compact reminder and the public correction action; actual entry/seating conditions remain prominent in the existing place header. The broader section order and correction position remain unchanged for discussion; only the explicitly unwanted wheelchair row was removed.

## Apple rationale and research

- [Apple, Explore navigation design for iOS](https://developer.apple.com/videos/play/wwdc2022/10001/): a modal may contain pushed child views; child Back follows hierarchy, while cancel/close exits the focused task. User input warrants explicit cancellation semantics and loss confirmation.
- [Apple, Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets?changes=_3_3): support vertical dismissal with confirmation for unsaved changes. Tapping outside is not a portable replacement for an explicit dismissal path.
- [Apple, Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/): provide a button alternative when using a gesture to dismiss.
- [NN/g, Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/): choose the initial/secondary split from real task needs and frequency. No measured improvement for this prototype is claimed.

No new business rule, glossary meaning, real GPS, map-provider search or backend submission was introduced.
