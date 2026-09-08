# Cool Spot iPhone Flow Prototype

## Current owner feedback revision — 7 September 2026

This section supersedes older eligibility and form instructions below. The current owner walkthrough is [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md).

- Confirmed visits have no deadline to start or finish a report. Discard clears answers, keeping the visit eligible. A nearby person can explicitly choose Share a new visit after publishing; retries never create duplicates.
- Saved recognised places and existing Cool Spots open their normal place pages, with Save/Saved and shared private-note controls. Private save success is acknowledged in place.
- Indoor, outdoor and mixed settings use the same location-identification rule. Public names and untrusted place types are optional. An unnamed point needs a decodable identifying photo; optional location directions can identify a floor or corner. Who can use this spot is optional for every place: Everyone, Limited access (with students, members and residents as visible examples), or Not sure. Limited access and unknown eligibility do not block review. Eligibility and cost remain separate. The MVP form omits the Who is it limited to? and Tickets and booking text fields (owner decision, 2026-09-08). Cost to use offers Free to use, Purchase required, Entry fee and Not sure; a free ticket is not an entry fee.
- The public form uses a map preview with one Change location action. Name and helper text share one row. Time limit has presets and hours/minutes controls.
- Explore explicitly shows no matches and offers an optional contribution route. Your own published report reuses the public report layout. The review/account/moderation services remain prototype boundaries.

Older sections below record prior iterations; do not use their 24-hour cutoff, forced indoor name/type, mandatory public-entry confirmation, or free-text time-limit instructions.

## Current implementation — human-centred revision, 6 September 2026

This section supersedes the historical flow revisions below. The owner delegated product/UX decisions and approved implementation. Contributions now use one unified chooser (search/nearby/map), preserve saved-pin coordinates, skip selection for known places, and collect public facts in one grouped form. Required cooling choices and photo requirements are visible; optional groups expand inline. One Send for review replaces the minimum/ready sequence. Photo selection no longer requires a second self-confirmation toggle. A public name resolves a map selection to a named-place proposal; a nameless outdoor point still needs a valid photo and public-entry confirmation.

Reports use explicit provenance and complete labelled synthetic examples, sorted by visit date regardless of author. The place preview uses the same newest-first order. Report reading has unboxed place context; Before you go is omitted until meaningful place-specific conditions exist; Suggest an edit is secondary. Visit-report optional fields are inline, and saving/visit-time rules are retained. Saved Places/Pins and the presence animation remain.

## Question

Can someone discover a useful place to cool down in London, understand why it may help, privately save either a recognised place or their current coordinate, and later turn that saved location into reviewed public cooling information without confusing saving, visiting, and contributing?

## Flows to exercise

1. Browse reviewed Cool Spots on a map and in a compact result sheet.
2. Search for a recognised place that does not yet have cooling information.
3. Open a Cool Spot and distinguish GLA-sourced information from community information.
4. Save a recognised place without making a public claim about it.
5. Save the current coordinate immediately, without completing a form.
6. Open a Saved Location and decide whether to keep it private, match it to a nearby place, or add cooling information later.
7. Match a coordinate to a nearby recognised place or keep it as a specific unnamed location.
8. Submit a new place or place update for review and understand its status.
9. Share a time-specific Visit Report during a location-confirmed visit or within its limited follow-up window, with reactive reporting/moderation.
10. Create a ten-minute, proximity-checked “cooling off here” presence without retaining location history.
11. Understand private contribution history and the lightweight Cool Hunt collection.

## Prototype data and simulated behaviour

- Fixed example Cool Spots representing GLA and community sources.
- Fixed Apple Maps-style search candidates that are visually distinct from Cool Spots.
- Simulated current location, proximity checks, review outcomes, sign-in, and notifications.
- Saved places/coordinates, private reporting confirmations, unfinished report answers and submitted prototype reports persist on this device. Appearance also persists. Other prototype state remains simulated; there is no account sync or backend.

## Deliberately out of scope

- Real GLA import, Apple Maps search, directions, geocoding, or location permission prompts.
- Accounts, syncing, backend persistence, push notifications, admin tooling, or moderation services.
- Photo upload and image moderation. Native photo selection and in-session preview are implemented; no image is uploaded or reviewed by a real service.
- Production accessibility audit, localisation, analytics, anti-abuse systems, and final branding.
- TDD and production architecture. The validated prototype will be discarded and rebuilt test-first.

## Revision after the first six-mission test

The first round answered the original distinction question: private saving, public place data, live presence and a past visit are valid separate concepts, but the first interface did not consistently expose those distinctions.

The revised prototype now tests these corrections:

1. A current coordinate becomes visible with an accuracy estimate before it is saved.
2. A saved coordinate offers separate paths for a named place and an exact unnamed spot.
3. Nearby suggestions rank possibilities but never decide place identity for the contributor.
4. Known-place submissions require a cooling feature first; access, seating, photo and notes are optional on the review screen.
5. Exact unnamed outdoor spots additionally require public-access confirmation and a photo.
6. Live ten-minute presence is a dedicated interaction rather than a peer of Directions and Save.
7. Past-visit feedback begins with the visible Felt cool / Didn’t feel cool choice.
8. Stable corrections use concrete labels such as Edit cooling features and Add or correct place details.
9. The You tab is a compact navigation list: account, Your reports, Places you’ve added or updated, Cool Hunt, and Settings. Only the unfinished-report count and actionable place-update count appear below their entries; individual reports do not preview on You.
10. Cool Hunt adds a small exploration goal rather than relying only on a static place-type grid.
11. All custom colour roles adapt to Light and Dark Mode, and selection is not communicated by colour alone.

## Revision after visual-direction and interaction shaping

This revision records decisions made after comparing the visual probes and critiquing the language around saving, live presence and visitor experience. These are hypotheses for the next prototype, not usability findings.

### Chosen visual direction

- Use the restrained deep-teal, mint and pale-sky palette shared by visual directions A and C.
- Use a real place photo near the top of place detail to support recognition, but keep it short enough that cooling evidence remains visible without a long scroll.
- Treat cooling information as the primary content: recent visitor experience answers whether it felt cooler, Place Information explains why it may feel cooler, and source plus recency explains how much confidence to place in each signal.
- Order the place detail as photo and identity with entry/seating/hours information, visitor cooling summary and full three-way response distribution, reviewed cooling features, a compact current-use count, remaining visit-planning information, detailed visitor reports with their independent report entry, then the live-presence contribution action. Reading information takes priority over collecting it; current use remains supporting evidence rather than proof of cooling effectiveness.
- Attribute a unique leading experience to an exact fraction of reports, never an unconditional “Most visitors.” Show different experiences for a tie and no conclusion for zero reports. Display the latest timestamp from the same fixture/submitted-report set used for counts. The prototype cannot establish a rolling “recent” window from aggregate fixture counts, so the interface says **Visitor reports** rather than inventing one.
- Keep Directions and Save in a persistent bottom action bar. Directions is primary and Save is secondary, but neither becomes a large content card that competes with cooling evidence.
- Show the first three reviewed cooling features, followed by **Show all N cooling features**. Expanded features wrap naturally in the scroll view; no feature becomes unavailable. Do not attach visitor-report counts to these tags unless the product actually collects the corresponding per-feature data.
- Do not present a sensor-like temperature, invented temperature difference or composite coolness score when the product has no sensor data.

### Chosen interaction hypothesis: progressive live presence

1. Keep the compact current-use count after reviewed cooling features, but place the contribution action after visitor information. It remains separate from Directions and Save and uses a secondary button treatment.
2. Express the public state in plain language, for example **2 people are cooling off here** and **Shared in the last 10 minutes**. Do not use internal labels such as **Live count** or **location-confirmed**.
3. On first encounter, show a dismissible contextual tip: **Help others decide whether to come here** and **Let others know you're here to cool down. For 10 minutes, they'll see one more person here—not your name.**
4. On every visit, retain the compact disclosure **Others see the number, not your name · How this works**. **How this works** opens a native sheet explaining the one-time nearby check, public count, privacy, ten-minute expiry and the difference between current use and cooling effectiveness.
5. The action reads **I'm cooling off here** and is enabled only when the device is near the Cool Spot. When location is known to be too far away, keep the action visible but disabled and explain why. This visibility rule remains a test hypothesis.
6. After the action succeeds, confirm **Others can now see one more person here**, say when sharing ends, and offer **Stop sharing**.
7. Progressively reveal an optional Visit Report question in the same place detail: **How did it feel compared with outside?** with **Not cooler**, **A little cooler**, and **Much cooler**. Choosing an answer opens the report with that answer preselected; it does not publish immediately.
8. Ask **What helped?** as an optional follow-up with concrete causes such as air conditioning, shade, airflow and water.
9. A nearby action records a private Visit Confirmation. Presence alone retains a 24-hour window to **start** a report. Once a report is started, it can be completed later without a submission deadline. Do not expose user-facing categories such as **Pending reports**.

### Independent visitor-report entry

- **Visitor reports** always includes a visible **Share how it felt** entry after the visitor details. The full three-way response distribution is also visible beside the prominent cooling summary, without requiring a report action. The independent entry opens the same report form with no answer preselected; it never starts Live Presence or changes the people count.
- The three relative-experience choices revealed after **I'm cooling off here** are a shortcut, not a prerequisite. They open the same form with the chosen answer preselected.
- Starting a report while nearby creates a durable unfinished report. Leaving, stopping presence and restarting the app do not revoke it. Resuming or checking in again never silently replaces its original confirmation, answers or visit time. Presence without a started report still expires after 24 hours; that is a start window, not a submission deadline.
- When neither nearby nor holding an unfinished report or valid presence confirmation, retain the disabled entry and explain: **Start while you’re here. You can finish later, even after leaving.** Saving a place or coordinate never grants report eligibility.
- **Finish later** preserves answers as they change, including sheet dismissal. **You → Your reports** lists **Unfinished** and **Published** separately. Each unfinished row shows the place, visit time and **Continue report**. Presence-only visits appear separately as **Visits you can report**, never in the unfinished count. No sign-in or Save is required. Publishing moves only that report into Published; a duplicate submission for the same confirmation does not add another vote. Published reports open a read-only detail of the actual submitted answers.
- **Saved → a published Cool Spot** opens the same full place page used by Explore, including evidence, Directions/Save and the report entry. Ordinary saved places and coordinates retain their private detail flows.
- Previously time-locked started reports now resume under the same rules without discarding data. Discarding answers remains explicit and confirmed. Multiple unfinished visits at the same place remain outside this model; the existing report must not be silently overwritten by a later visit.
- People with no earlier nearby action still cannot report after leaving. Keep a visible disabled report entry and **Why can’t I share?**. This explanation does not claim to recover missing evidence. Do not add an opening tutorial or passive location recording in this pass.
- The form records an editable **Visit time**, initially based on the nearby action and retained when resuming. The prototype permits a time within the 24 hours before that action through the current time. This is a self-reported time, not sensor evidence. Public freshness uses the reported visit time rather than submission time; no submitted answer is treated as a current temperature reading.
- Proximity remains simulated. **You → Settings → Prototype controls → Nearby place** changes the nearby fixture; **Simulate leaving after 24 hours** expires only confirmations without a started report and does not alter unfinished answers or visit times. Real permissions, GPS accuracy/retry and server-side anti-abuse checks are not implemented. The local ten-minute presence timer ends the user's additional count without ending report eligibility; other people's counts remain fixtures.

### Native implementation after wireframe validation — 2026-09-05

- Three tabs remain Explore, Saved and You. You uses native grouped navigation rows, not expandable sections or a report preview card. Account details, place-contribution outcomes and Cool Hunt content remain accessible on their own pages.
- Place-contribution history excludes visit reports; Your reports contains the actual saved drafts and published visit reports. Your help statistics and Place types discovered live inside Cool Hunt. Prototype controls live inside Settings.
- New/unset appearance defaults to Light; explicit Light, Dark or Match System preferences are preserved.
- Follow-up implementation adds the accepted Saved terminology, individual visitor reports, a local popsicle-thanks demo and the presence explainer animation. The main place evidence and action hierarchy remain unchanged.

### Saved-location language

- **Save** bookmarks a named place under **Saved → Places**. **Save a pin here** privately marks the current point under **Saved → Pins** so it can be found again; it does not start a report, confirm a venue visit, or imply contribution intent.
- After **Save a pin here**, confirm **Private pin saved**, state **Only you can see it**, and offer **View pin**. Existing saved names and notes are preserved.
- On an unmatched Saved Location detail, show an inline state rather than a modal: **No cooling information yet**. Explain that the saved location is not currently shown on the Cool Spot map and offer **Add cooling information** as an optional next action.
- Do not use **Location drafts**, **registered**, or other internal workflow language in the interface.

### Visitor reading and mutual-aid thanks — 2026-09-05

- Place quotes and **Read all visitor reports** open all available individual reports. No avatars or social profiles are required. Local submitted reports retain their actual responses, visit time and optional comment; fixture quotes have no fabricated visit metadata. Aggregate totals are not converted into invented individual reports.
- **Send a popsicle** is a free virtual thank-you for a report, not a cooling rating. First use explains the action and asks for confirmation. Later use is one tap, with Undo. Each device can send one per example report; self-thanks are blocked. Thanks do not affect report ordering, cooling evidence or presence counts.
- This prototype has no backend. Sent thanks persist only on this device and are visibly marked Demo; nobody is notified. A received-thanks example can be triggered in Settings → Prototype controls, then appears on the specific published report inside Your reports, not as another You section. It is explicitly labelled as an example.
- **How this works** includes a schematic map whose example count changes from 2 to 3, with Replay. It never checks location or changes real presence. Reduce Motion shows the completed state and keeps the textual explanation.

### Questions for the next test

- Within 30 seconds, can a person explain whether they would go, the cooling evidence they used, and what remains unknown? Not going because the evidence is insufficient is a valid outcome.
- Can they distinguish a plurality such as 6 of 14 reports from broad agreement, and find the conflicting responses without searching?
- Before tapping, can a person predict that Live Presence changes a public anonymous count for ten minutes?
- Do they understand that current use does not guarantee cooling effectiveness, capacity or seat availability?
- Does progressively revealing the optional Visit Report feel lightweight, or does it still feel like too much work?
- Can someone who only wants to report how it felt find the independent entry without first sharing that they are cooling off here?
- Can they distinguish Save, Live Presence, Visit Report and Place Information without learning those internal terms?
- Does **No cooling information yet** describe an unmatched Saved Location without implying that the physical location cannot provide cooling?

## Approved Required → Ready → Optional revision — 5 September 2026

Owner approved all four wireframes and all three proposed decisions in `.impeccable/review/shape-2026-09-05/SHAPE.md`. This revision supersedes earlier questionnaire layouts and Replay-only presence animation.

- The map and How this works use the same `CoolSpotPin(type:count:)`: place type plus a person/count badge for nonzero presence. Source stays in place text badges. The example loops 2 → 3 → hold → restart, with Pause/Resume; system Reduce Motion displays static 3 and its explanation. Restart is not a simulated expiry.
- Place Visitor reports has one preview, View all, retained stay distribution, then its independent contribution entry. Preview comes from available individual items, preferring dated submitted reports; fixtures remain labelled with missing dates. No aggregate records, author or temperature data are invented.
- Visitor report requires only relative experience. Selection opens Ready; optional helping features, stay and comment are separate native destinations that retain answers on Back. Ready keeps the original editable Visit time. Finish later, sheet dismissal, relaunch and indefinite completion use the existing persisted journey model.
- All place entries use one public draft: recognised place, Explore add, Saved Pin and existing Cool Spot. Saved-based matching uses its saved coordinate for map and distances. Search includes recognised places and published Cool Spots; a known Cool Spot opens update mode. Exact identity duplicates discovered at send require an explicit update review with proposed details retained.
- New named places need identity/location, setting, source-backed or chosen type, and a cooling feature. Unknown setting/type is not defaulted. Exact unnamed spots require confirmed coordinates, Outdoors, a feature, legal public access and a decodable photo plus an identification confirmation; no invented name or Park type. PhotosPicker now supports real local selection, removal and load errors.
- Existing-place updates require a real change; untouched data is not re-asked. Removing all cooling features needs an explicit explanation for review. Submitted prototype contributions retain their full public payload for this session; they do not mutate published facts, private pins, visit reports or presence.
- Optional public details are Entry/access, Seating/stay, Other facilities, Photo and Note. Drinking water belongs only to cooling features. Tables and formal stay limits belong to Seating/stay. Toilets, Wi-Fi, power and explicitly permitted laptop use belong to Other facilities. Not added is distinct from No; power never infers laptop permission.
- Source name/type are confirmation values; user-supplied setting/type are editable. Source corrections use an independent subpage. Back retains values. Close confirms discarding changed place answers; no new persistent place-draft feature. Changing identity requires confirmation and resets place-specific answers. Pin detail has private Name/Note and one Add cooling information entry, without private tags or premature place matching.

Real location/search, review services, account sync and publication remain simulated. Native UI and model checks are implementation evidence, not participant findings; the 30-second decision task still needs human validation.

### Owner feedback refinement — 6 September 2026

Keep the accepted native minimal public forms and Saved Places/Pins. Reports use one reading component with variable factual content and consistent provenance. The presence example now sits on MapKit with restrained count arrival motion. The MVP Before-you-go wheelchair row is removed. Public-form children use Back and specific titles; whole-flow Close remains on the main form. Optional same-page answers, unified place search/map entry, photo-switch removal and broader section order are proposals awaiting owner preference, as recorded in `.impeccable/review/feedback-2026-09-06/DECISIONS.md`.
