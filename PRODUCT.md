# Product

## Register

product

## Platform

ios

## Purpose and scope

Cool Spot helps people discover places in London where they could cool down, understand the available evidence, and decide whether to go. Private saving, reviewed place information, a visitor's experience and current use are different signals.

This document records current implemented behavior and agreed product intent. Implementation is not proof of usability. The source baseline and working instructions are in [AGENTS.md](AGENTS.md); verification status and owner tests are in [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md).

## Users

People exposed to heat while outside or travelling, potentially tired, hurried, using one hand or working with limited attention. The primary design target is a useful decision within 30 seconds, including deciding not to go when information is insufficient. This is a target, not a measured result. Saving, reporting and contributing are secondary tasks.

## Brand Personality

Calm, trustworthy, fresh and helpful. Preserve the native SwiftUI interface, system typography, SF Symbols and teal/mint identity while improving clarity. Mutual aid should help someone else, not turn heat exposure into competitive engagement.

## References and anti-references

Apple Maps and iOS conventions inform familiar map/navigation behavior; Google Maps informs separation of saving, visitor experience and place corrections. These are design references, not claims that our specific flows are platform requirements. Avoid tourism-style rewards, leaderboards, database jargon, decorative dashboard patterns and unsupported claims that a place is currently cool, safe, open or has seats available.

## Design Principles

1. Prioritise the decision to visit and Directions over invitations to contribute.
2. Distinguish known facts, missing information, example data and a person's report; never infer individual reports from aggregate totals.
3. Make private versus public consequences clear before commitment. Minimise required answers and unnecessary navigation.
4. Group related questions, use concrete language and keep labels visible while typing. Do not expose internal place-resolution categories to users.
5. Follow native navigation, controls and accessibility. Target AA contrast, 44-point touch areas, Dynamic Type, dark appearance, Reduce Motion and meaningful VoiceOver order. These are requirements, not claims of a completed accessibility audit.

## Shared language

| Concept | Meaning |
|---|---|
| Location anchor | Reference to a recognised place, a point inside a larger place, or an unmatched coordinate; no cooling claim by itself. |
| Recognised place | A named map/source place. It becomes a Cool Spot only when reviewed cooling information is published. In this prototype these are fixtures, not live search results. |
| Cool Spot | Public location with reviewed cooling information in the product model. Current map entries and review provenance are illustrative fixtures. |
| Saved place / private Pin | A private bookmark or coordinate. Neither confirms a visit nor initiates a contribution. `SavedLocation` is the code model for both; the UI separates Places and Pins. |
| Place information / contribution | Facts such as cooling features, eligibility, cost and seating, or a proposal to add/correct them. A proposal awaits review; it is not a visitor's time-specific report. |
| Visit Report | Experience relative to outside at a stated visit time. It does not replace place information or automatically share presence. |
| Live Presence | Anonymous indication of current use for ten minutes after a deliberate nearby action. Not seat availability, all occupants or cooling effectiveness. |
| Visit Confirmation | Private per-place record created by a deliberate nearby report/presence action. It supports later reporting but does not prove entry into the venue. Proximity is simulated. |

## Discovery and private saving

Sources: `ExploreView` in [ExploreView.swift](cool-spot/ExploreView.swift), `SavedView`/`SavedPrivateDetails` in [SavedYouViews.swift](cool-spot/SavedYouViews.swift), and `PrototypeStore` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift).

- Explore, Saved and You are the three tabs. Search can return existing Cool Spots and ordinary places; no-match feedback offers changing the query or entering the contribution flow.
- Filters are single-select: Indoor, Outdoor shade, AC, Free and Water. More is not implemented. Search this area only resets its UI state; it does not fetch another region. Nearby and location explanations are simulated.
- Save bookmarks a place under Saved → Places. Save a pin here saves the fixed simulated current coordinate under Pins, not the map camera centre. Pins can have private names/notes; there is no Pin-delete UI.
- Both kinds of saved place open the same respective detail view used from Explore, including Save/Saved and private details. Private save shows success feedback. Cancelling a place bookmark does not remove visit reports. Preparing a public contribution does not copy private text or move the saved Pin.
- Directions on both kinds of place detail open an external Apple Maps walking link with the selected coordinates. Navigation itself is not implemented or verified inside this app.

## Public place contributions

Sources: `ContributionFlow`, `PlaceContributionDraft.canSend`, `PlaceContributionDraft.changes` and `PostedStayLimitPicker` in [ContributionView.swift](cool-spot/ContributionView.swift); `PrototypeStore.existingSpot(for:)` and `submitPlaceContribution` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift).

| Part | Current behavior |
|---|---|
| Entry | Explore + opens one search/nearby/map chooser. A known place opens its form directly; a known Cool Spot opens Update place details. A saved Pin begins at its saved coordinate, with map confirmation before the public form. |
| Selected location | Unlisted positions show a map and Change location. Adjusting this same proposal's point retains its answers. Switching to a different place with changed answers requires confirmation and clears the old place's answers. Returning to the same selected identity retains them within the open flow. |
| New proposal requirements | Valid confirmed coordinates, Indoors/Outdoors/Both and at least one cooling feature. Public place name and untrusted place type are optional. There is no distinct indoor name/type requirement. |
| Identification | An unlisted proposal without a place name requires a decodable photo, for indoor, outdoor and mixed settings alike. Directions text may describe a floor/corner but does not replace this photo requirement. With a name, the photo is optional. |
| About the place | Indoors or outdoors? leads the section; three direct options, no default for a new unlisted point. Name and How to find this spot are adjacent. The directions field starts at one line and grows. Known trusted metadata is displayed rather than re-asked. |
| Optional facts | Entry and seating and Other facilities expand in the same form; the public note stays optional. They are not separate per-field pages. |
| Who can use this spot? | Everyone / Limited access / Not sure. Students, members and residents are examples. All answers permit review; entry eligibility is not a submission gate. |
| Cost to use | Free to use / Purchase required / Entry fee / Not sure. Separate from eligibility: free can coexist with limited access. A free ticket is not an entry fee. |
| Time limit | Not added / Not sure / No stated limit / 30 minutes / 1 hour / 2 hours / Other duration…; custom duration uses Hours and Minutes. This is a posted limit, not how long this visit lasted. |
| Removed controls | No Who is it limited to?, Tickets and booking, wheelchair-access question or photo self-confirmation toggle in this form. Some historical model values remain for compatibility; this does not make them active inputs. |
| Updating a Cool Spot | A real change is required; unchanged facts are not re-required. Source name/type corrections use a note. Removing every original cooling feature requires a reason. Invalid changed fields/photos block submission. |
| Duplicate | Near-identical coordinates plus compatible identity trigger explicit Review update, retaining proposed changes. Proximity alone does not merge places; fuzzy matching is absent. |
| Finish or leave | Send for review records a session-only proposal and shows confirmation; it does not change published map facts. Close protects changed answers; the sheet attempts the same protection on dismissal. There is no persistent public-contribution draft or Finish later. |

## Visitor reports and presence

Sources: `PrototypeStore.canReportVisit`, `hasCurrentConfirmation`, `beginVisitReport`, `beginNewVisitReport`, `discardReportAnswers`, `submitReport`, `checkIn` and `visitorReportItems` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift); `VisitReportFlow` in [PlaceDetailView.swift](cool-spot/PlaceDetailView.swift); [VisitorReportsView.swift](cool-spot/VisitorReportsView.swift).

- A report can start while nearby or from a previously confirmed, unreported visit. Confirmed visits have no deadline to start or finish. Browsing and saving do not create confirmation; someone now away with no earlier confirmation cannot report through the current flow.
- The only required questionnaire answer is Not cooler / A little cooler / Much cooler. Visit time is prefilled, editable and cannot be in the future. Helping features, stay and comment are optional and remain on the form.
- Answers save as they change; Finish later, leaving and relaunch preserve them and the original visit time. You → Your reports separates Unfinished, Published and Visits you can report. Presence without answers is not an unfinished report.
- Discard answers clears only that draft, retaining confirmation. Publishing completes only the matching visit and rejects duplicate publication. A nearby user can explicitly Share a new visit after publishing; it preserves older reports. There is no edit/delete UI for published reports or multiple simultaneous drafts at the same place.
- Visitor reports and the single place-page preview use the same newest-visit-time-first list, regardless of author. Own and example reports share a renderer. Examples have labelled synthetic answers and fixed dates; missing optional fields are omitted. Aggregate fixture counts need not equal the available individual records. The generic Before you go block is absent; Suggest an edit is secondary to reading.

I’m cooling off here is a separate nearby action. It adds one anonymous count for ten minutes, with one active place per device. Stop sharing removes that count; it does not revoke report eligibility. Relaunch preserves the original end time. The How this works map animation illustrates 2 → 3 with Pause/Resume; Reduce Motion shows a static completed example and never shares real presence.

## Data lifetime and prototype limits

Sources: `ContentView` in [ContentView.swift](cool-spot/ContentView.swift), `ReportJourneySnapshot`/`PrototypeStore` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift), and account/settings/outcomes in [SavedYouViews.swift](cool-spot/SavedYouViews.swift).

| Lifetime / service | What actually exists |
|---|---|
| Persisted on normal device launches | Saved places/Pins/private notes; confirmations, report drafts and published reports; simulated nearby flags; active presence/end time; local popsicle state; appearance preference. Stored locally via UserDefaults/encoded snapshots, without account sync. |
| Session only | Public place proposals and simulated review status; public form answers/photos; preview sign-in; some Cool Hunt state. Relaunch can reset these. |
| Native services | MapKit map display; external Apple Maps link; PhotosPicker and local photo decoding. No photo upload. |
| Fixtures / simulation | Places, search, current coordinate and nearby flags, source/review badges, other people's presence/evidence, account and review outcomes. No live GLA import, GPS permission/accuracy flow, authentication, backend moderation, notifications or sync. |
| Review outcomes | In review, Action needed, Published, Not published and Added to an existing Cool Spot are demonstrations. No clarification/resubmission/appeal flow, and simulated Publish does not create or update a real map entry. |

Send a popsicle is a local demo thank-you for an example report: first-use confirmation, one per report, Undo, no self-thanks and no change to ordering, cooling evidence or presence. Received thanks can be simulated for a specific own report. Nobody is notified. Cool Hunt/account views are prototype demonstrations, not a completed rewards/account service. Report a problem explains its unavailable service rather than pretending to send.

## Unresolved questions, not approved features

| Question | Current boundary |
|---|---|
| Can first-time users choose a useful place quickly and distinguish evidence from presence? | Needs observation; implementation and owner acceptance of a draft UI do not establish this. |
| Can people identify a corner/unlisted point and understand name/photo/eligibility choices with little effort? | Validate current form before broad visual work. No new required answers are approved. |
| What about a genuine past visitor who did nothing in the app while there? | Current confirmation rule excludes them when away. Whether to accept other evidence remains a product decision. |
| Can people find unfinished reports, understand same-place repeat visits and understand review outcomes? | Test current return paths. Editing/deleting reports and completing real review services are not implemented. |
| How useful are current-use counts and popsicle thanks? | Comprehension and social usefulness are unvalidated; do not infer engagement or cooling benefit from fixture interactions. |
