# Saved, visitor reports and recognition — native extension

Recorded from the built SwiftUI source on 2026-09-05. This is a scoped implementation record, not a new global design system. Product and interaction authority remain [PRODUCT.md](../../../PRODUCT.md) and [PROTOTYPE-BRIEF.md](../../../PROTOTYPE-BRIEF.md).

## Overview

The extension inherits Cool Spot’s native teal/mint interface. Visitor reports support reading and assessing a place; a popsicle is a secondary, free virtual thank-you attached to one report. Private saving, report evidence and anonymous presence retain separate meanings.

Built surfaces: Saved’s Places/Pins grouping; the individual Visitor reports destination; sent and received popsicle states; and the schematic inside the presence explanation sheet. The existing You navigation list remains the entry to Your reports, and received examples appear on their own published report.

Source: `cool-spot/VisitorReportsView.swift`, related sections of `cool-spot/SavedYouViews.swift` and `cool-spot/PlaceDetailView.swift`, with appearance roles and state behavior in `cool-spot/PrototypeModels.swift`.

## Colors

Reuse the existing native `AppStyle` roles directly. `brand` supplies interactive tint and recognition text; `mint` supplies the illustrative background and popsicle detail. Both adapt to Light and Dark appearances. The presence-example count uses white text on the fixed dark `ink` fill. Native primary/secondary text and background colors provide the remaining hierarchy.

These notes do not translate the appearance roles into CSS or introduce a parallel token source. Their canonical definitions remain in `PrototypeModels.swift`.

## Typography

Use SwiftUI system text styles. Report comments use body; response summaries and section emphasis use headline; supporting answers and recognition labels use subheadline; dates, missing-data disclosures and demo explanations use caption. Inline navigation titles identify the deeper destinations. Text may wrap without a fixed report-row height.

The schematic count uses a bold title2 with monospaced digits. Its height follows `@ScaledMetric(relativeTo: .subheadline)` so the explanatory composition grows with reading size.

## Layout

Saved uses an inset grouped list, with named places and coordinate pins in separate sections. Individual reports and published-report details use native lists and navigation. Each visitor row presents identity or example provenance, available response and visit details, comment, then the thank-you action. Report rows use a vertical stack with 12-point spacing and 8-point vertical padding.

The presence illustration belongs inside the existing scrollable explanation sheet after the privacy and expiry explanation. It has its own textual meaning and Replay action; it is not an interactive location picker.

## Elevation & Depth

The extension relies on native list grouping, sheet presentation and tonal separation. The report and recognition components introduce no custom shadows. The schematic’s mint field, crossing background-colored roads and dark count capsule separate illustration elements without implying a live map.

## Shapes

Keep native list and alert geometry. `PopsicleMark` is a small SwiftUI drawing made from a rounded rectangle and capsules, shared by sending and receiving states. It is supplementary to a text label. The schematic uses a rounded field and count capsule; these local drawing dimensions are not a new app-wide radius scale.

## Components

### Saved Places and Pins

- **Places** holds saved named places; **Pins** holds private coordinates. Saving never starts a report or confirms a venue visit.
- **Save a pin here** opens a native explanation/confirmation alert that states the private audience and simulated location. Confirmation says **Private pin saved**, **Only you can see it**, and offers **View pin**.
- Empty content uses the native unavailable-content view. An unmatched saved location explains **No cooling information yet** inline, with the optional cooling-information action.

### Individual visitor reports

- Place quotes and **Read all visitor reports** open the same reader. Display all available individual items; do not manufacture records from aggregate totals.
- Locally published reports show their actual response, visit time, optional helping features, stay and comment. Missing optional content is omitted.
- Fixture quotes say **Example visitor report** and **Visit date and response details unavailable**. A footer explains that some prototype totals lack individual details.
- With no individual items, show **No individual reports to read yet**. Recognition does not change ordering, cooling answers or presence.

### Popsicle thanks

- The initial action is a text-labelled, borderless **Send a popsicle** button below report content, with a visible **Demo** explanation. The first successful send follows a native confirmation alert explaining that it is free, virtual, reversible and device-only.
- After sending, show **Popsicle sent · Demo**, **Undo**, and **Saved on this device only. No one has been notified.** Subsequent sends use one tap after the explanation has been accepted.
- The store accepts at most one current sent state per eligible example report. Undo removes that state. Own reports expose no sending button and the store rejects self-thanks.
- A received example appears only on the associated Published row and its report detail. The detail explicitly says **Example only — no real person sent this.** Settings → Prototype controls supplies the simulation action.

### Presence example and accessibility

- The illustration changes an example count from 2 to 3 after a short delay; **Replay example** restarts it. Text explains the same change and the anonymity of the public number.
- Reduce Motion immediately displays the completed state. The illustration never calls location or presence operations, and the visible caption says it does not change the real count.
- The illustration exposes one descriptive VoiceOver label for its before/after state. The decorative popsicle drawing is accessibility-hidden; adjacent text names the action or status.
- Send, Undo and Replay provide a minimum 44-point height. Native navigation, alerts and sheets retain platform behavior. Status and prototype limitations are stated in text rather than conveyed by color alone.

## Do's and Don'ts

- Do preserve the reading-first order and the established native semantic styles.
- Do keep Demo/Example provenance visible beside recognition states and preserve honest missing-data disclosures.
- Do retain the textual 2 → 3 explanation when animation is unavailable.
- Don't turn thanks into cooling evidence, report ranking, a presence increment, a reward total or a new top-level You section.
- Don't infer a real sender, recipient delivery, visit date or individual response from the prototype fixtures.

The prototype persists thanks on this device only and provides no backend, account synchronization, actual recipient notification or production anti-abuse service. Fixture totals and individual quotes are incomplete relative to each other. This source-based record does not claim a production accessibility audit or hardware validation; screenshot review is handled separately.

Not canonized: unrelated existing display treatments, one-off illustration geometry, simulated recognition and fixture gaps are not global design rules. No root `DESIGN.md` or web component sidecar is created from this native slice.
