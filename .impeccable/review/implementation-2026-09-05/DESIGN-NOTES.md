# Approved contribution and evidence flows — native extension

Recorded from the final SwiftUI build on 2026-09-05. This is a scoped implementation record, not a new design system. Authority: [PRODUCT.md](../../../PRODUCT.md), the approved [SHAPE.md](../shape-2026-09-05/SHAPE.md), and the incumbent [recognition notes](../recognition/DESIGN-NOTES.md). This record supersedes those notes only for the presence illustration and Place report-preview behavior described below.

## Overview

The build retains Cool Spot’s calm native teal/mint world: system navigation and grouped forms, readable summaries, and explicit commitment actions. Reading evidence supports the immediate cooling decision; contributing remains a secondary choice. Saved Places/Pins and You → Your reports keep their established destinations.

**The Separate Consequences Rule.** Private saving, a visit report, public place information and ten-minute anonymous presence keep distinct labels and outcomes. Selecting a feeling makes a report ready; only Publish publishes it. Place proposals say Send for review and remain pending review.

Source evidence is in `cool-spot/ContributionView.swift`, `PlaceDetailView.swift`, `ExploreView.swift`, `VisitorReportsView.swift`, `SavedYouViews.swift`, `PrototypeModels.swift` and `ContentView.swift`. The native captures and final bounded verdict live beside this file.

## Colors

Reuse `AppStyle` directly: appearance-aware `brand` supplies interactive foregrounds; `mint` supplies the presence example field; fixed dark `ink` supplies white-on-dark primary controls and place-type circles. `controlSurface`, system backgrounds, primary/secondary text and `subtleBorder` support grouping and state. Existing blue presence surfaces remain part of the incumbent world.

The shared count badge uses native primary text on `controlSurface` with a separator outline. It no longer inherits the earlier illustration’s white-on-dark count treatment. Canonical values remain in `PrototypeModels.swift`; no CSS conversion or second token source is introduced.

## Typography

SwiftUI system text styles remain the native hierarchy: bold title2 for required questions and Ready headings, headline for place/section emphasis, body for answers and comments, subheadline for answer summaries and controls, caption/footnote for provenance and consequences. Native inline navigation titles orient subpages. Count badges use semibold caption with monospaced digits and SF Symbols.

**The Answer Before Decoration Rule.** Summaries wrap vertically. At accessibility text sizes, report rows stack their Change label and omit supplementary feeling icons while retaining the selected-state symbol and text. This is an observed adaptation of these flows, not a new global display-font rule.

## Layout

Native NavigationStack, Form, List and sheet presentations carry progressive disclosure. Ready pages group the minimum answer summary before Optional rows; optional editors return through native Back with their current answers retained. Repeated heading groups use 12-point vertical spacing; report summary rows use 6-point spacing and a minimum 44-point height.

At ordinary text sizes, Publish and Send use the existing primary button treatment in a bottom safe-area material bar. At accessibility sizes, the actions become part of the scrollable Form. The visitor-preview heading uses a horizontal layout when it fits and stacks when necessary. No web breakpoints or separate tablet composition were added.

## Elevation & Depth

Native grouped surfaces, sheet chrome and bottom-bar material provide depth in the forms. These new form and marker components add no custom shadow system. This does not prohibit existing shadows elsewhere in Explore. The presence illustration uses a tonal field without pretending to be a live map.

## Shapes

Retain native list and form geometry. Feeling choices use the existing rounded control treatment with a visible selected symbol. The shared marker combines a circular place-type icon with a capsule containing `person.fill` and the complete count. Its bottom-aligned reserved space keeps the map anchor stable when the count badge appears or disappears. Local drawing dimensions are implementation details, not a new app-wide radius scale.

## Components

### Visitor report: required → Ready → optional

One feeling is sufficient to reach Ready. Existing drafts with a feeling and presence-shortcut answers open there directly. How it felt and actual Visit time remain visible with Change; publication time does not replace visit time. What helped, How long you stayed and Add a comment each open a separate optional editor. Helping features remain available even for Not cooler and never modify stable place features.

Finish later, edits and dismissal retain the existing persisted visitor draft, without a completion deadline or a presence increment. A failed publication keeps the answers private and editable. Success follows explicit Publish and moves the visit into Published; the native success screen currently says “Thanks for the update.”

### One public place form

Recognised Place, Explore plus, Saved Pin and Existing Cool Spot enter the same form with different identity/baseline data. Saved-pin suggestions and map position use the saved coordinate, without importing its private name, note or photo. Unknown source Setting/Type stays unknown; trusted identity values carry source treatment and a separate correction route.

Minimum details lead to Ready, then optional Entry and access, Seating and stay, Other facilities, Photo and Note editors. Exact unnamed spots require confirmed coordinates, Outdoors, a cooling feature, legal public-access confirmation, a decodable selected image and confirmation that the image identifies the spot. Their required photo is not duplicated under Optional. PhotosPicker exposes loading, replacement and failure recovery; the visible prototype disclosure says images remain in the session and are not uploaded.

**The Explicit Delta Rule.** Updates require meaningful normalized changes and validate changed fields without demanding untouched legacy gaps be completed. Whitespace-only and bookkeeping changes do not enable sending; edited Setting/Type cannot become nil. Removing the last existing cooling feature requires a reason. Duplicate reconciliation starts with existing facts and applies only the incoming proposal’s explicit changes, preserving untouched access/seating and showing proposed differences for review.

Back preserves the active draft. Closing an edited place proposal requests discard confirmation; this flow has no new cross-launch draft persistence. Changing identity requires confirmation before resetting place-specific answers. The Saved pin page retains its native navigation title, private details and one public-information entry; the redundant eyebrow above the private title was removed.

### Place evidence preview

The section presents Visitor reports / View all, one individual preview, the existing stay-distribution disclosure, then the secondary report-entry control. Directions and Save remain the Place page’s bottom actions. Actual reports precede fixtures; an actual report without a comment can preview its feeling. Fixture text says “Example report · Visit date unavailable.” Empty individual data gets an honest empty state and no empty View all destination; aggregate totals never manufacture reports.

### Shared count marker and illustration

Explore and PresenceMapExample use `CoolSpotPin(type:count:)`. Zero omits the badge entirely and means no active shared presence, not an empty venue. Full 10/100 counts remain readable rather than becoming dots or a cap. Place type and count combine into one accessibility element; source remains separate place information.

The illustration loops 2 → 3 with a restrained numeric transition, a labelled restart and Pause/Resume. User pause preserves its state; inactive scenes stop the loop. Reduce Motion displays static 3 with the equivalent 2 → 3 explanation and no looping control. A stable accessibility description avoids per-frame announcements. Text distinguishes this illustration from expiry, real presence, seating, capacity and temperature.

## Do's and Don'ts

- Do preserve the reading-first hierarchy and separate private/public consequences.
- Do retain actual visit time, unknown values, source provenance and Example/Demo labels.
- Do keep full count digits and the stable marker anchor; use text and symbols as well as color.
- Don't turn visit duration into a formal stay limit, outlets into laptop permission, or public access into free entry.
- Don't copy private pin information into a public proposal or silently erase existing facts during duplicate reconciliation.
- Don't infer production delivery, current temperature, real GPS eligibility or individual reports from prototype state.

Validation: [VERIFICATION.md](VERIFICATION.md) records 38 passing tests, native phone/tablet Light/Dark captures, maximum-type report scrolling/publication and Reduce Motion checks. [VERDICT-PASS.md](VERDICT-PASS.md) resolves the three fixes scored in [FINISH-REVIEW.md](FINISH-REVIEW.md). Its ship disposition covers that bounded correction pass, not a fresh whole-surface accessibility certification. Full VoiceOver traversal, measured contrast, hardware/GPS behavior and first-time comprehension remain untested. Public proposals and photos are session-only; no backend, real upload, provider or GPS integration was added.

Not canonized: unrelated existing display treatments, one-off geometry, fixture gaps and simulated delivery are not rules for future surfaces. No root DESIGN.md or web/CSS sidecar is created from this native slice.
