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
| Recognised place | A named map/source place. It becomes a Cool Spot only when reviewed cooling information is published. Sources include live Apple Maps search results and retained prototype fixtures. |
| Cool Spot | Public location with reviewed cooling information in the product model. Current map entries and review provenance are illustrative fixtures. |
| Saved place / private Pin | A private bookmark or coordinate. Neither confirms a visit nor initiates a contribution. `SavedLocation` is the code model for both; the UI separates Places and Pins. |
| Place information / contribution | Facts such as cooling features, eligibility, cost and seating, or a proposal to add/correct them. A proposal awaits review; it is not a visitor's time-specific report. |
| Visit Report | Experience relative to outside at a stated visit time. It does not replace place information or automatically share presence. |
| Live Presence | Anonymous indication of current use for ten minutes after a deliberate nearby action. Not seat availability, all occupants or cooling effectiveness. |
| Visit Confirmation | Private per-place record created by a deliberate nearby report/presence action. It supports later reporting but does not prove entry into the venue. Proximity is simulated. |

## Discovery and private saving

Sources: `ExploreView` in [ExploreView.swift](cool-spot/ExploreView.swift), `SavedView`/`SavedPlaceEditor` in [SavedYouViews.swift](cool-spot/SavedYouViews.swift), and `PrototypeStore` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift).

- Explore, Saved and You are the three tabs. Explore search and the contribution chooser use native `MKLocalSearch` for place names, landmarks, addresses and postcodes, alongside retained example places and Cool Spots. The existing result → place detail / contribution form routes remain. Ordinary Apple Maps results have no reviewed cooling information, Report or Cooling here actions.
- `PlaceSearchModel` in [PlaceSearch.swift](cool-spot/PlaceSearch.swift) waits 350 ms after typing; Search and Try again submit immediately. Empty input cancels work. Replaced requests are cancelled and late results ignored. Loading, no matches and failure with retry are distinct; a failed request does not hide matching local examples or saved places. Results scroll instead of being limited to two ordinary places. While a nonempty search field is focused, the nearby strip is temporarily hidden to make room above the keyboard; it returns on Search, loss of focus or clearing.
- Explore provides the visible map region as a search hint. The contribution chooser uses its original source location (including a saved Pin or selected place). A region is a hint, not a London-only boundary. Apple may return approximate matches for nonsense input; absence of an exact text match is not an API failure. No-match feedback keeps the existing add-location entry. Search requires network access, but does not request GPS permission.
- Filters are single-select: Indoor, Outdoor shade, AC, Free and Water. More is not implemented. Search this area only resets its UI state; it does not fetch another region. Nearby and location explanations are simulated.
- Save bookmarks a place under Saved → Places. Selected Apple Maps results use their Place ID, or a deterministic name/coordinate fallback if unavailable. Saved results retain name, address, coordinates and known type locally so the same detail can reopen after relaunch; existing v1 journeys remain readable. Search alone does not save a bookmark, confirm a visit or publish a place.
- MapKit categories supply a place type only where mapped; unknown types stay optional. Search never infers an indoor/outdoor setting or cooling facilities. Ordinary place details lead with name, source category when mapped, address and cooling-information status; no decorative cover is shown. Optional source phone and website links appear when available and are retained with saved places. The broad Cool Spot place type remains separate from the more specific source category; unknown categories are not guessed.
- Save a pin here saves the fixed simulated current coordinate under Pins, not the map camera centre. Pins can have private names/notes; there is no Pin-delete UI.
- Both kinds of saved place open the same respective detail view used from Explore. **Save** immediately bookmarks the place; **Saved** opens a menu with **Edit saved place** and **Remove from Saved**. Editing opens `SavedPlaceEditor` with Name in Saved and Your note; **Save changes** is enabled only after a change and with a nonblank name. Cancel protects unsaved edits; the editor does not autosave. The place card shows a read-only **Your note** section only when a note exists, with Edit. There is no inline private-details form added by saving. Pins use the same editor through **Edit saved pin**. Removing a place with a note requires confirmation; visit reports are retained. Preparing a public contribution does not copy private text or move a saved Pin.
- Selecting a map marker, nearby Cool Spot or search result focuses the map on its coordinates. An ordinary selected place gets a marker without becoming a Cool Spot. Explore details start at a native medium sheet and expand by dragging upward. The visible map stays above the sheet; Directions and Save remain at the card bottom. Cool Spot cards lead with one cooling-features block (two priority features, with expansion in place), cost/seating and known entry information. **How it felt** groups the experience summary, latest-visit date, always-visible distribution and stay-length disclosure. A separate **Visitor reports** group contains the latest individual report preview, the single **Read all reports** navigation link and the report-entry action. The preview itself is read-only; there is no duplicate View all link beside the statistics. Places without individual reports show their empty state without a reading link. A supplied photo follows the cooling and visitor information; absent photos do not create a decorative illustration block. Example place data is labelled as such, without claiming a real authority import.
- “Seating provided” describes the fact that a place has seating, not current vacant seats. Display wording is updated in cards and contribution choices; the stored enum value is unchanged for compatibility.
- Ordinary places offer **Find nearby Cool Spots** before invitations to contribute. Explore switches to results around that selected place, initially within 1 km; **Search a wider area** expands to 3, 6, 12, 24 and 25 km. Only the existing Cool Spot catalogue is searched, ordered by straight-line distance from the selected place; the result card uses the same distance context. A missing result does not claim there are no cooling opportunities. Closing a result returns to the same radius/results; **Back to [place]** restores the original card and the Explore search text. From Saved, the same action opens Explore around that saved place. This prototype catalogue has three illustrative places, not a complete London service. Report/presence eligibility is unchanged.
- `ApplePlaceInformationView` in PlaceDetailView puts **Opening hours & place details** before a collapsed **View nearby streets** disclosure. The disclosure requests native Look Around only when expanded. Recognised Apple places with a valid Place ID resolve the exact map item and pass it to `MKLookAroundSceneRequest(mapItem:)`; the same item is reused for the on-demand Apple Maps place details system card. Coordinate-only results and fixtures use a coordinate request without inventing an Apple business identity. Apple chooses the street scene, which may not show the entrance or indoor conditions. The control and compact caption call it nearby streets, not an entrance photo. Loading, unavailable coverage and retryable failure have distinct text. Street views around fixture Cool Spots are labelled as near an example location. Closing the system card returns to the cooling card. This supplementary information makes no cooling claim.
- Directions on both kinds of place detail open an external Apple Maps walking link with the selected coordinates. Navigation itself is not implemented or verified inside this app.

## Reading hierarchy and interface copy

- Related metadata uses 4 pt spacing, labels and fields 8 pt, related items 12–16 pt, sections 24 pt and major place-card groups 32 pt, with 20 pt page insets where a native Form/List does not own the layout. These roles are shared as `LayoutSpacing` in PrototypeSharedViews. Native forms and lists retain platform grouping. Touch controls keep at least a 44 pt target.
- Identity, cooling/access facts, visitor evidence, current use, supplemental place information and personal notes are distinct groups. A heading sits closer to the content it introduces than to the preceding group. Do not compensate for unclear grouping by adding explanatory paragraphs.
- Remove repetitive interpretation disclaimers and prototype implementation narration from the reading path. Retain dates, actual missing-data/error states, compact Example/Demo labels and information needed before an action (privacy, duration, required input, losing edits). Longer eligibility help remains behind Why can’t I share? or How this works. No live-data or service claim is added by shortening copy.

## Public place contributions

Sources: `ContributionFlow`, `PlaceContributionDraft.validationIssues`/`canSend`, `PlaceContributionDraft.changes` and `PostedStayLimitPicker` in [ContributionView.swift](cool-spot/ContributionView.swift); `PrototypeStore.existingSpot(for:)` and `submitPlaceContribution` in [PrototypeModels.swift](cool-spot/PrototypeModels.swift).

| Part | Current behavior |
|---|---|
| Entry | Explore + opens one search/nearby/map chooser. A known place opens its form directly; a known Cool Spot opens Update place details. A saved Pin begins at its saved coordinate, with map confirmation before the public form. |
| Selected location | Unlisted positions show a map and Change location. Adjusting this same proposal's point retains its answers. Switching to a different place with changed answers requires confirmation and clears the old place's answers. Returning to the same selected identity retains them within the open flow. |
| New proposal requirements | Valid confirmed coordinates, Indoors/Outdoors/Both, a name and at least one cooling feature; unlisted locations also require a decodable photo. Untrusted place type remains optional. Recognised places start with their source name; an explicit correction can propose a different name for review. |
| Identification | A public proposal for an unlisted map-selected location requires both a descriptive, understandable name and a decodable photo, regardless of indoor/outdoor/mixed setting. A supplied name does not waive the photo, and a photo cannot substitute for the name. This includes an unmatched saved Pin entering the public contribution flow; private saving itself does not require these public details. Recognised-place and existing-Cool-Spot update flows keep photos optional. |
| About the place | Indoors or outdoors? leads the section; three direct options, no default for a new unlisted point. Name and How to find this spot are adjacent. The name and directions fields start at one line and grow. Known trusted metadata is displayed rather than re-asked. |
| Form hierarchy | Section titles group related questions. Required/Optional sits beside each editable question, never in section headings. Short instructions stay with their question; cooling-choice instructions appear before the options. Photo has one stable section after cooling features, before More details. Section spacing uses 24 pt; question stacks use 8 pt. All optional picker rows share one layout with a 44 pt content minimum, and stack their label/value when width or Dynamic Type needs it. Extra helper text can increase a row's height. |
| Validation feedback | Send for review remains operable while answers are incomplete. A submit attempt reveals all current validation errors next to their questions and scrolls to the first one; it does not submit or clear answers. Errors resolve as answers change, without automatically scrolling while typing. An untouched form has no errors. An unchanged update explains that at least one detail must change. Photo loading and completed submission disable Send. At accessibility text sizes, Send is at the form end instead of covering the viewport. |
| Optional facts | Entry and seating and Other facilities expand in the same form; the public note stays optional. They are not separate per-field pages. |
| Who can use this spot? | Everyone / Limited access / Not sure. Students, members and residents are examples. All answers permit review; entry eligibility is not a submission gate. |
| Cost to use | Free to use / Purchase required / Entry fee / Not sure. Separate from eligibility: free can coexist with limited access. A free ticket is not an entry fee. |
| Time limit | Not added / Not sure / No stated limit / 30 minutes / 1 hour / 2 hours / Other duration…; custom duration uses Hours and Minutes. This is a posted limit, not how long this visit lasted. |
| Removed controls | No Who is it limited to?, Tickets and booking, wheelchair-access question or photo self-confirmation toggle in this form. Some historical model values remain for compatibility; this does not make them active inputs. |
| Updating a Cool Spot | A real change is required; unchanged facts are not re-required. Name or place type is incorrect expands a prefilled Suggested name and, for a known type, a Suggested place type picker using the existing category choices. Only changed fields become proposals; Additional details is optional. Blank proposed names block submission. The original source values are retained and the proposal does not edit Apple Maps or published facts. Removing every original cooling feature requires a reason. Invalid changed fields/photos block submission. |
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
| Persisted on normal device launches | Saved places/Pins/private notes and the basic details of saved Apple Maps results; confirmations, report drafts and published reports; simulated nearby flags; active presence/end time; local popsicle state; appearance preference. Stored locally via UserDefaults/encoded snapshots, without account sync. |
| Session only | Public place proposals and simulated review status; public form answers/photos; preview sign-in; some Cool Hunt state. Relaunch can reset these. |
| Native services | MapKit map display and live local search; external Apple Maps link; PhotosPicker and local photo decoding. No photo upload. |
| Fixtures / simulation | Initial Cool Spot catalogue and example places, current coordinate and nearby flags, source/review badges, other people's presence/evidence, account and review outcomes. No live GLA import, GPS permission/accuracy flow, authentication, backend moderation, notifications or sync. |
| Review outcomes | In review, Action needed, Published, Not published and Added to an existing Cool Spot are demonstrations. No clarification/resubmission/appeal flow, and simulated Publish does not create or update a real map entry. |

Send a popsicle is a local demo thank-you for an example report: first-use confirmation, one per report, Undo, no self-thanks and no change to ordering, cooling evidence or presence. Received thanks can be simulated for a specific own report. Nobody is notified. Cool Hunt/account views are prototype demonstrations, not a completed rewards/account service. Report a problem explains its unavailable service rather than pretending to send.

## Unresolved questions, not approved features

| Question | Current boundary |
|---|---|
| Can first-time users choose a useful place quickly and distinguish evidence from presence? | Needs observation; implementation and owner acceptance of a draft UI do not establish this. |
| Can people identify a corner/unlisted point and understand name/photo/eligibility choices with little effort? | The Identification rule, consistent form labels/spacing and submit-attempt validation are implemented. Agent native checks are recorded in the walkthrough; owner comprehension and comfort still need observation. Further required answers are not approved. |
| What about a genuine past visitor who did nothing in the app while there? | Current confirmation rule excludes them when away. Whether to accept other evidence remains a product decision. |
| Can people find unfinished reports, understand same-place repeat visits and understand review outcomes? | Test current return paths. Editing/deleting reports and completing real review services are not implemented. |
| How useful are current-use counts and popsicle thanks? | Comprehension and social usefulness are unvalidated; do not infer engagement or cooling benefit from fixture interactions. |
