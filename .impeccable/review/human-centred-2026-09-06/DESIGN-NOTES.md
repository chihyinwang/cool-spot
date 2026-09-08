# Human-centred contribution and report revision — native continuity

Recorded from the implemented SwiftUI prototype on 6 September 2026. This bounded note extends the incumbent native teal/mint system; it does not establish a new visual identity or replace an app-wide design system. Root `DESIGN.md` is absent. The authorized write scope is this note only, so no root design file or web/CSS sidecar is created.

Authority and continuity: [PRODUCT.md](../../../PRODUCT.md), the current implementation section of [PROTOTYPE-BRIEF.md](../../../PROTOTYPE-BRIEF.md), and this revision's [DECISIONS.md](DECISIONS.md). The current implementation supersedes the pending chooser, optional-field, photo-switch and section-order proposals in the [historical feedback notes](../feedback-2026-09-06/DESIGN-NOTES.md). There are no pending owner design-preference questions.

**Evidence status:** implementation is recorded, but final ship disposition remains pending. The scoped [VERDICT.md](VERDICT.md) resolves the native feeling rows and partially verifies contrast. Two existing interaction states still need final-color captures; the precise boundary appears below. This note does not turn the pending verdict into a pass.

## Overview

Contribution uses **Operate** mode: choose the intended place, answer related questions together, and make an explicit public commitment. Report reading uses **Read** mode: experience and factual context precede recognition or invitations to contribute. Both use native navigation, semantic text styles, system forms/lists, and the incumbent teal/mint accents.

The durable product constraints are low effort under heat and fatigue, readable evidence, and a clear distinction between private saving, stable public place facts, time-specific reports and anonymous presence. The implementation supports these intentions; no participant outcome or 30-second success rate is claimed.

Primary source evidence: [ContributionView.swift](../../../cool-spot/ContributionView.swift), [VisitorReportsView.swift](../../../cool-spot/VisitorReportsView.swift), [PlaceDetailView.swift](../../../cool-spot/PlaceDetailView.swift), [PrototypeModels.swift](../../../cool-spot/PrototypeModels.swift), and shared button styles in [PrototypeSharedViews.swift](../../../cool-spot/PrototypeSharedViews.swift).

## Colors

The canonical native values remain in `AppStyle`; this note does not duplicate them into CSS or create a parallel token source.

- `brand` supplies appearance-aware teal/mint foregrounds for interactive actions, selected answers and report feeling emphasis. `ink` remains the dark fill paired with an explicitly white foreground on enabled primary buttons.
- `supportingText` is the new opaque, appearance-aware role used across changed chooser copy, public-form help and explicit field prompts, report details, provenance/date, and the visitor-comment prompt. Lower hierarchy is expressed through type size and placement without relying on faint text opacity.
- Primary body content retains the native primary foreground. `paper`, `controlSurface` and `subtleBorder` retain semantic system backgrounds and separators. Existing mint/blue surfaces elsewhere are preserved.
- Disabled primary controls retain their separate secondary foreground and control-surface treatment. The stronger supporting-text role is not an instruction to make disabled actions look enabled.

**The Readable Evidence Rule.** Source, visit date, instructions and empty prompts are substantive content. Their hierarchy must remain legible in Light and Dark appearances. The source correction and nine fresh captures support this rule; two final-color states are still unverified.

## Typography

SwiftUI system text styles keep San Francisco and Dynamic Type in control. Headline marks the selected place, report feeling, form question and primary action; body carries answers and comments; subheadline carries supporting facts and secondary actions; caption carries provenance and visit date. Completion screens use the existing larger title styles.

**The Complete Answer Rule.** Place names, report comments, helped-feature labels, selected-answer summaries and stay details grow vertically. Feeling rows retain complete labels; their decorative leading symbol is omitted at accessibility sizes while the selected/unselected indicator remains. No fixed-height text row or one-off screen geometry becomes a reusable type rule.

## Layout

The unified chooser contains inline place-name/address search, nearby or matching results, and one map action. Each result names the place and explains whether selection adds cooling information or updates an existing Cool Spot. Internal recognised/missing/exact categories remain implementation details, not user-facing route choices.

Known-place and existing-Cool-Spot entry opens the public form directly. Saved-pin entry begins at the saved coordinates with map confirmation. Public name and note start separately from private saved content. Nearby ranking does not establish place identity.

The public contribution is one grouped `Form`: selected-place context, place facts, inline cooling-feature choices, any required unnamed-point information, expandable optional groups, a direct note and native photo field. There is one Send for review action, without minimum/ready destinations. The visit report likewise uses one grouped form with required feeling, visit time, inline optional helped features, duration and a directly available comment.

At accessibility text sizes the public-form context stacks vertically and the primary send/publish action moves into the scrolling form. At ordinary sizes that action sits in the bottom safe-area inset. Phone and tablet keep the same content sequence.

Report reading is a plain native list. The place name and Newest visits first appear as unboxed section context; each report uses the same reading component. On the place detail, the latest preview groups feeling, available comment, provenance and visit date closely. Suggest an edit is a secondary action beside place information; the generic Before you go block is removed. Directions and Save retain their existing priority.

## Elevation & Depth

Native form grouping, list separators and navigation/sheet materials supply structure. The primary form action uses the existing regular material at the bottom edge. Feeling choices are ordinary full-width rows within one Form group, without separate rounded fills or strokes. This revision adds no shadow vocabulary.

The incumbent presence illustration retains real MapKit context. Its geographic anchor and map stay fixed while the shared count badge demonstrates arrival. It does not become a new decorative surface treatment for forms or reports.

## Shapes

Native rows carry answer selection. Full-row hit regions, checkmarks and selected text weight make state perceivable beyond color; changed selection and text-action controls retain a minimum 44-point height. Existing shared primary/secondary button shapes and the shared circular map marker/capsule count badge remain.

Map and photo clipping are local component geometry, not a new global radius scale. The flat feeling-row correction does not prohibit the incumbent buttons or map badges from using their established shapes.

## Components

### Context-preserving public contribution

**The Place Before Answers Rule.** A known identity enters with its available facts. A saved coordinate supplies the location anchor, never its private title or note. An unmatched point asks for a public name only when it has one; a nameless point retains the outdoor, valid-photo and public-entry requirements. Adding a public name changes the applicable requirements without introducing a separate jargon-labelled route.

Native Back retains the active draft. Returning to the same place preserves its answers. Changing to a different place with edited answers explains that the current answers will be cleared and requires confirmation. Explicit Close also confirms discarding changed contribution answers; it does not discard Saved Places/Pins. These are separate consequences, expressed separately.

Optional Entry and seating and Other facilities answers expand inline. Not added remains distinct from No. A posted stay limit remains a stable place fact, separate from how long a visitor stayed. Source corrections are an inline disclosure, and existing-place updates retain their proposed-changes summary.

### Photo and public commitment

The native PhotosPicker provides a decoded image preview, Replace photo, Remove photo, loading state and load-error recovery. The former identification self-confirmation switch is removed. A nameless outdoor point still requires an actual decodable photo plus public-entry confirmation; a named place retains the optional photo field. Send is disabled while a replacement image is loading.

Send for review remains a deliberate public-information action. Completion says the information is waiting for review and is not public yet. Prototype submission retains the session payload; the completion message explicitly identifies the absence of a real review service.

### Individual report evidence and newest preview

**The Evidence Before Recognition Rule.** `VisitorReportContent` presents available feeling, comment, helped features, stay duration, then provenance and visit time. Optional absent facts remain absent. Own, visitor and example provenance are explicit; the current peer records are independently authored, complete labelled fixtures with fixed synthetic dates. Aggregate totals never supply invented individual answers or dates.

**The Visit Date Determines Order Rule.** The combined collection sorts by reported visit date across authors, with unknown dates last and deterministic tie handling. Both the full list and place preview use this collection; the first item supplies the preview whether it is the owner's report or another report. Examples do not become newer on each launch.

The local popsicle thank-you remains below evidence and absent from the owner's own report. Example/Demo labels and the device-only delivery explanation remain; recognition does not alter cooling evidence, presence or report ordering.

### One-page visit report

`ReportChoice` is a flat native single-selection row with a full-width target, complete wording, selected text weight and checkmark. One feeling answer is sufficient; helped features, duration and comment remain optional in the same form. Publishing remains explicit.

Answers autosave privately as they change. Finish later preserves the draft and original visit time; discard is explicit and confirmed. Moving optional answers inline does not change report eligibility, saved-location semantics, the visit-time model or the independent report entry.

### Preserved presence and saving patterns

Saved Places/Pins and the existing non-panning MapKit presence example remain. The example loops from 2 to 3 with local badge arrival motion, Pause/Resume, and an inactive-scene stop. Reduce Motion shows the completed count with equivalent explanatory text. The illustration is labelled, does not alter the real count, and does not depict seating, capacity, temperature or ten-minute expiry. This revision creates no new motion concept.

## Do's and Don'ts

- Do preserve place context, actual answers, original visit time and private/public boundaries as a task changes presentation.
- Do use native form/list structure, inline optional answers, readable supporting text and visible non-color selection cues.
- Do keep reading evidence ahead of recognition and use one author-independent chronological collection for list and preview.
- Do distinguish implementation, simulated data and observed interaction evidence from participant findings.
- Don't restore internal place-category jargon, minimum/ready detours, the photo self-confirmation switch or nested feeling panels as established patterns.
- Don't copy private saved content into a public draft or treat nearby results as proof of identity.
- Don't populate missing report facts from aggregates, treat synthetic examples as real visits, or let ownership override freshness.
- Don't reinstate generic Before you go advice as a required section; place-specific conditions would need their own evidence and design decision.

### Verification and remaining evidence

[VERIFICATION.md](VERIFICATION.md) records **41 passing tests after the last code correction**, with the test log at `/tmp/cool-spot-human-centred-review-fixes.log`. Native interaction records cover direct known-place entry, preserved answers on Back/reselection, distinct Close/change-place safeguards, saved-coordinate privacy, inline answers, decoded photo loading and waiting-for-review completion. These are simulator/prototype observations, not a usability-study result.

The full independent [REVIEW.md](REVIEW.md) identified only supporting-text/prompt contrast and nested feeling panels. One correction batch introduced opaque `supportingText` and flat selection rows. The scoped [VERDICT.md](VERDICT.md) records the rows as resolved and contrast as partially verified: nine final-build captures cover chooser, known-place form, report reading and visitor-report form across their named Light/Dark and maximum-text states. No further code defect or broad test round is identified.

Two files still contain the earlier, validated interaction state from before the color correction and **do not prove final colors**:

- `phone-optional-inline-light.png`: expanded Entry and seating, including the empty public-form prompts.
- `phone-place-preview-light.png`: latest report preview with provenance and visit date.

Those final-build replacements await CUA interaction after the owner unlocks the Mac. The owner has been asked; the latest check still found the Mac locked. This is a capture-evidence limitation, not a pending design preference. The final ship decision remains pending those images. No claim of a passed full review or completed task is made.

After the last code correction and normal launch, every app-preference key matched the original pre-work backup, including report journeys, local popsicle state and appearance. The phone was returned to the normal app and the temporary tablet shut down. No test report or public contribution was written to the owner's persistent store. Full VoiceOver, physical-device gestures and gesture-only dismissal remain unverified; real search/GPS, accounts, uploads and moderation are outside this prototype's scope.

Not canonized: superseded proposals, the former low-contrast treatment, nested feeling panels, one-off geometry, fixture content and simulated delivery are not reusable system rules. Partial screenshot coverage and passing tests are not an accessibility or usability certification.
