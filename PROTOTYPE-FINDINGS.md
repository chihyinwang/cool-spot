# Cool Spot Prototype Findings

## Mission 1 — Find somewhere suitable

### Observed outcome

- The participant selected Riverside Library.
- They could identify that entry was free and seating was available.
- They noticed the GLA source badge.
- They saw the raw recent counts (18 felt cool / 3 did not) and considered the strong balance sufficient evidence that the place was likely to feel cool.
- They remained unsure about the *cause* of the cooling—air conditioning, shade, ventilation, or another condition—but did not consider that uncertainty a serious barrier to choosing the place.

### What worked

- **Task completion:** the participant could reach a plausible destination.
- **Basic decision information:** access and seating were findable and understandable.
- **Source visibility:** the source badge was noticed rather than overlooked.

### Problems

1. **Minor — “GLA” assumes prior knowledge.** The source badge was visible, but the acronym alone did not explain why the source should be trusted.
2. **Minor — Cooling mechanism is ambiguous.** “Cooler indoor space” and “Natural ventilation” did not establish whether the cooling came from air conditioning, shade, ventilation, or another condition. This did not block the decision because the recent visitor balance was persuasive.
3. **Minor — Missing versus absent is ambiguous.** The absence of an Air conditioning chip could mean “there is no AC” or “we do not know whether there is AC.”

### Confirmed learning

- The raw positive and negative counts can create useful cooling confidence without introducing a subjective “how cool” rating.
- Cooling mechanism and visitor evidence answer different questions: one explains *why it might be cool*; the other shows *whether visitors actually felt cool*.
- No extra cooling-intensity scale is justified by this test.

### Candidate changes to test later

- Replace the acronym-only badge with **Official Cool Space**, with secondary explanation: “Listed by the Greater London Authority (City Hall).”
- Avoid **Verified** on its own. It could imply that the app independently verified current temperature, air conditioning and every facility.
- State unknown facts explicitly, for example **Air conditioning not confirmed**, instead of silently omitting them.
- Keep the raw evidence summary visible; later tests can determine whether it needs to move closer to the title.
- Keep stable features, recent visitor experience and live presence visually distinct; they answer different questions.

### Follow-up result

- The participant saw the counts and considered the strong majority sufficient. The unresolved point was the cause of cooling, not confidence that the place would feel cool.

## Mission 2 — Save an ordinary map place

### Observed outcome

- The participant searched for “Riverside” using the main search field.
- They clearly understood “No cooling information yet” to mean that Riverside Café was a recognised place but not a published Cool Spot.
- They expected Save to put the place in the Saved tab for later use.

### What worked

- **Search matched the participant’s natural starting point.** No alternate entry point or instruction was needed.
- **Place status was unambiguous.** The empty cooling-information state successfully prevented an ordinary place from being mistaken for a Cool Spot.
- **Save matched the participant’s mental model.** The expected destination and purpose of the action were clear.

### Problems

- None observed in this mission.

### Confirmed learning

- General map places can safely appear in explicit search results when their lack of cooling information is stated clearly.
- Save should remain a private bookmarking action whose result lives in the Saved tab.

## Mission 3 — Remember an unnamed location quickly

### Observed outcome

- The participant could not see their current position on the map before saving.
- Their first instinct was the floating plus button, where they successfully found Save current location.
- The app gave immediate confirmation after saving.
- The only confirmation action was Undo; the participant questioned its usefulness and wondered whether saving should instead open the saved item.
- “Near Southwark Street · SE1” did not feel sufficient for recognising the location after a long delay.
- The Saved Location detail did not clearly state whether the location was already a public Cool Spot.
- The participant identified two location-identity cases that the same screen must support: an exact coordinate that cannot be matched to a named place, and a coordinate that can be linked to an existing recognised place.

### What worked

- **The plus button matched the participant’s mental model** for an action that creates or saves something.
- **Save current location was discoverable** within that action menu.
- **The save remained lightweight:** no contribution form interrupted the quick capture.
- **Immediate feedback confirmed the action.**

### Problems

1. **Major — The saved coordinate is invisible before capture.** The prototype allows a person to save a simulated current location without showing which point will be saved.
2. **Major — Long-term recognition is weak.** A nearby street and postcode alone may not reconstruct the memory later.
3. **Major — Location identity and cooling status are conflated.** The detail page does not independently explain whether the coordinate is linked to a recognised place and whether that place has public cooling information.
4. **Minor — The confirmation action does not support the likely next step.** Undo is recoverable but less useful than viewing or adding private context to the saved item.
5. **Minor — Public status is implicit.** A person must infer that a Saved Location is not automatically a Cool Spot.

### Candidate interaction model

The Saved Location detail should present two independent sections:

1. **Location match**
   - Unlinked coordinate with a small map preview, saved date/time, nearest landmarks and possible nearby place matches.
   - Linked recognised place with its name and address, plus an option to change or remove the match.
   - “Keep as exact spot” when none of the candidates describe the location.
2. **Cooling information**
   - Existing public Cool Spot: display its cooling information directly and offer Suggest an update.
   - No public cooling information: state “Not on the Cool Spot map” and offer Add cooling information.
   - Contribution in review: display the review status without publishing it on the map.

### Candidate changes to test later

- Make the simulated current position visible when location access is in use. In the real app, the blue location marker can only appear after permission is granted.
- Keep saving in the current map context; replace the confirmation’s primary Undo action with **View saved location** rather than navigating away automatically.
- Add a map thumbnail, absolute saved date/time, nearby landmarks and an invitation to add a private label or photo for long-term recall.
- Add a factual status message: **Private saved location · Not on the Cool Spot map**. This does not claim that the physical location is not cool; it only describes the app’s data state.
- Surface possible place matches on the Saved Location detail before contribution, while retaining the same match step as duplicate protection during contribution.

## Mission 4 — Turn a saved coordinate into a Cool Spot contribution

### Observed outcome

- The participant considered the individual screens visually acceptable.
- They identified that a GPS coordinate and its accuracy radius cannot determine which adjacent venue they visited.
- Nearby candidates may omit the correct existing place, so the current choice between suggested places and “This exact spot” is incomplete.
- The full contribution flow felt long and questionnaire-like.
- There was no positive feedback while progressing, so the effort did not feel rewarded until submission.

### What worked

- The prototype recognised that place identity needs explicit user confirmation.
- “This exact spot” provides a route for genuinely unnamed outdoor locations.
- Breaking the form into screens kept each individual screen readable.

### Problems

1. **Major — Candidate generation is being mistaken for place resolution.** GPS proximity can rank possibilities but cannot establish identity, especially for adjacent businesses or multiple venues inside one building.
2. **Major — There is no route to an existing place omitted from nearby suggestions.** Choosing “This exact spot” in that case would create a duplicate or misclassify a recognised business as an unnamed location.
3. **Major — The minimum contribution is too long.** Place identity, type, cooling features, access, seating, photo and note are presented as one continuous obligation.
4. **Major — Progress feels like a survey rather than creating something useful.** The interface does not show the public value being assembled or acknowledge useful choices along the way.

### Recommended place-resolution model

Treat the saved coordinate as evidence, never as identity. Preserve its timestamp and horizontal accuracy, then ask the contributor to confirm one of four explicit outcomes:

1. Choose one of the nearby suggested places.
2. Search all recognised map places by name, landmark or address.
3. Add a missing named place when the real venue is not in the map provider’s results.
4. Keep it as an exact unnamed spot when it is genuinely a tree, bench, shaded corner or similar sub-location.

Show the saved point and its accuracy circle on a movable map. Distance should rank candidates, not select one automatically.

### Recommended shorter contribution model

- **Known place:** confirm the place, select at least one cooling feature, then submit. Access, seating, photo and note become optional “Add more details” contributions.
- **Exact unnamed spot:** adjust the pin, add one cooling feature and the required photo, then submit. Other information remains optional.
- Maintain review before map publication.
- Show a live preview of the contribution becoming useful, such as “People will know there is tree shade here,” rather than only a progress bar.
- Give immediate submission acknowledgement, but reserve Cool Hunt unlocks and formal achievements for publication or merge approval.

### Relevant Google Maps pattern

- Google separates adding a missing place, editing an existing place, writing a review, adding a photo and answering place questions into distinct contribution actions.
- When choosing a place for a review or photo, Google permits search/selection rather than treating the suggested location as authoritative.
- Google provides a separate Add place path for a real place that is missing.
- Google’s Local Guides feedback system awards contribution points when content is published and exposes contribution/impact history.

## Mission 5 — Share a live presence and a past visit

### Observed outcome

- Dark Mode exposed unreadable text and controls because the prototype reused a fixed dark teal as foreground text on dark system surfaces.
- The participant questioned whether the past-visit entry point should remain a general **Share how it felt when you visited** button or expose the primary **Felt cool / Didn’t feel cool** choice directly on the place detail.
- **Cool off here** was understandable to this participant because they already knew the product concept, but they did not consider it equivalent to Directions and Save.
- The people dots became understandable with the nearby explanation, although they were not immediately self-explanatory.
- The dots did not imply seat availability, which is the intended interpretation.
- The ten-minute duration could be found in the active-presence card, but it was not explained before the participant initiated the action.
- Completion feedback for the Visitor Report felt appropriate.
- The question comparing a Visitor Report with editing place information was too abstract to answer and needs to be tested with concrete examples.
- When given the concrete case “It felt cool during my visit today,” the participant said the current screen would not lead them to Visitor Report.
- When given the concrete case “This place has air conditioning,” the participant would not consider **Suggest an update**, because the label does not say what can be updated.

### What worked

- **Live presence did not imply availability.** The participant read it as people rather than free seats.
- **The people count was recoverable.** Supporting copy made the dot meaning understandable.
- **Visitor Report completion feedback was sufficient.** No additional reward is currently justified at report submission.

### Problems

1. **Blocker — Dark Mode contrast fails.** Fixed light-mode brand colours made some text effectively invisible and weakened selected states.
2. **Major — Live presence has the wrong information hierarchy.** Directions and Save are place utilities; **Cool off here** changes shared live state and has privacy and duration consequences. Giving all three equal action-bar treatment hides that distinction.
3. **Major — The check-in commitment is disclosed too late.** People should know before tapping that the action shares one anonymous presence for ten minutes and requires a nearby location check.
4. **Major — Visitor Report entry hides the user’s intended action.** In a concrete past-visit scenario, the participant could not identify the current CTA as the place to report how it felt.
5. **Minor — Dot-only encoding needs nearby language.** The marks can remain compact, but the detail view should pair them with a plain count such as “3 people cooling off here.”
6. **Major — “Suggest an update” has no visible object.** The participant did not know whether it meant editing the place, the map, the live status or their report, so they would not use it to add a stable fact such as air conditioning.

### Immediate blocker fix

- Separate the fixed dark brand fill used behind white button labels from an adaptive brand foreground colour.
- Make mint, blue, yellow-tinted and grouped surfaces adapt to the current appearance.
- Replace the light-only white filter surface with a semantic system surface.
- Add a checkmark and border to report choices so selection is not communicated by colour alone.

This blocker was fixed during the test round and the prototype was rebuilt successfully in Dark Mode.

### Candidate changes to test later

- Remove **Cool off here** from the Directions / Save utility row.
- Introduce a dedicated live-presence section near the top of place details. Before the action, state: **Share one anonymous presence here for 10 minutes**. The button can then read **I’m cooling off here**.
- Keep the exact dot count compact on the map, but use a textual count in place details.
- Prototype an inline past-visit prompt: **Did it feel cool when you visited?** with **Felt cool** and **Didn’t feel cool**. Choosing either opens the Visitor Report with that answer preselected; it must not publish immediately.
- Replace the generic **Suggest an update** link with a concrete action attached to stable place information, such as **Add or correct place details**, with supporting examples: cooling features, access, seating and photo.
- Use a contextual action beside unknown data—for example **Air conditioning not confirmed · Edit cooling features**—so the object of the action is explicit. **Add what you know** was rejected as too vague.

### Confirmed learning

- The current screen does not communicate either contribution path without prior explanation.
- Renaming alone is insufficient. Past experience belongs inside **Recent experiences**, while stable corrections belong next to **place information**.
- The next iteration should expose the action and its object together rather than requiring users to learn the internal terms Visitor Report and Place update.

## Mission 6 — Understand identity, progress and review outcomes

### Observed outcome

- The participant’s first reading of the You tab was “places I visited where I can collect badges.” Account state, private saved data and public contributions did not define the page strongly enough.
- **Keep your progress** suggested that saved places or contributions currently live only on the device and would become associated with an account after signing in.
- The word **sync** sounded technical and potentially troublesome. The participant also noted that a person with no saved places or contributions should not be told that existing activity will be synced.
- **Places mapped** was not understood at all.
- **Helpful updates** and **Visit reports** did not communicate a meaningful distinction.
- The place-type-only Cool Hunt grid felt boring rather than motivating.
- The review outcome text was understandable, but the participant questioned whether every past status deserves ongoing prominence.
- The participant anticipated that Past contributions would become an unwieldy table-like list as history grows.

### What worked

- **The sign-in concept was recoverable.** The participant inferred the important underlying benefit: protect activity currently stored on the device and associate it with an account.
- **Review outcome wording was acceptable.** Once visible, the participant could understand what happened.
- **Review outcomes can remain private operational feedback.** They do not need to become public identity or ownership claims.

### Problems

1. **Major — The You tab’s primary purpose is misread.** Cool Hunt appears early and visually dominates, so the page reads as a visited-place badge collection rather than account, contribution and personal-progress space.
2. **Major — Contribution labels use internal language.** **Places mapped**, **Helpful updates** and **Visit reports** require knowledge of the app’s data model and do not explain how each action helped people.
3. **Moderate — Sign-in copy is not state-aware.** It promises sync even when there may be nothing on the device, and “sync” introduces technical anxiety.
4. **Major — Cool Hunt has collection without play.** A static checklist of place categories offers no meaningful goal, surprise, progression or choice.
5. **Moderate — Contribution history will not scale.** Rendering every completed item on the overview page will bury current actions and produce an indefinitely growing list.
6. **Minor — Past statuses have limited lasting value.** Review details matter when action is required or an outcome is new; they can become compact history afterward.

### Confirmed learning

- Replace internal metrics with concrete language: **Cool Spots added**, **Place details improved**, and **Visits shared**.
- Make sign-in copy conditional. With local activity, explain that signing in keeps specific saved places, contributions and Cool Hunt progress with the account. Without activity, explain cross-device and future-history benefits without claiming anything needs syncing.
- Avoid the word **sync** in the primary explanation.
- Put contributions requiring attention ahead of collection/game content.
- Limit recent history on the You overview and provide a separate **See all contributions** destination.
- Cool Hunt needs a separate design question. The next prototype should add a small goal or quest, not merely decorate the same category grid.

### Review-outcome hierarchy

- **Action needed** remains prominent and says what the contributor must do.
- **In review** appears as compact current activity.
- Newly **Published**, **Added to an existing Cool Spot**, or **Not published** outcomes can appear in recent activity.
- Older completed outcomes move to the full contribution history.
- Prototype controls remain testing instrumentation only; they are not part of the intended user-facing product.

## Follow-up hypothesis — progressive live presence

**Status: selected for the next prototype; not yet validated by usability testing.**

After reviewing three interaction structures, the project selected a progressive live-presence hypothesis for the next test:

1. A dedicated **I'm cooling off here** action sits after reviewed cooling features. On first encounter, a dismissible contextual tip explains the public anonymous ten-minute effect; a compact permanent privacy line and **How this works** sheet keep the explanation recoverable without leaving a large instruction block on every visit.
2. A successful action updates Live Presence, then reveals an optional relative-experience shortcut on the same place detail rather than presenting two competing actions up front. A separate **Share how it felt** entry remains in **Recent visitor reports**; sharing Live Presence is never a prerequisite for reporting an experience.
3. The public count describes people using the place to cool down; it must not be presented as proof that the place feels cooler, has capacity or has seats available.
4. The optional Visit Report asks **How did it feel compared with outside?** using **Not cooler**, **A little cooler**, and **Much cooler**, followed by optional concrete causes. The selected answer is carried into the report form and nothing publishes until the person confirms.
5. A Saved Location remains a private memory aid. Its detail may show **No cooling information yet** and offer **Add cooling information**, but saving does not imply an intention to contribute or confirm a visit.

The next test must determine whether people understand the live action before tapping, whether the first-time tip is useful without making the screen feel instructional, whether the persistent **How this works** route is discoverable, whether a disabled nearby-only action creates frustration, whether the progressive question feels lightweight, and whether the distinction between current use and cooling effectiveness survives the combined flow. Until that test runs, these statements remain design hypotheses rather than confirmed findings.

### Implementation review correction — report access

The first SwiftUI translation exposed the report form only after sharing Live Presence. Project review identified this as an unintended prerequisite: someone reporting an ineffective visit should not first have to publicly state that they are cooling off there. The correction restores an independent report entry while retaining the post-presence shortcut and the same proximity / 24-hour eligibility rule. This is a confirmed implementation gap, not a usability-test result; discoverability of the independent entry still needs testing.

## Information-first revision — 3 September 2026

**Status: implemented after owner prioritisation and expert critique; not yet participant-validated.**

The owner clarified that providing understandable information is the app’s primary value; gathering new reports is secondary. This supersedes the earlier hypothesis that placed the full live-presence invitation before visit-planning information.

### Confirmed implementation defects addressed

- The fixed “Most visitors said” label overstated agreement in the 6/14 park fixture. The summary now uses an exact fraction, with explicit tied and zero-report states.
- A submitted report changed counts without updating Latest. Submitted reports now carry a timestamp and freshness is derived from the same place’s available reports.
- The two-column utility bar and unconstrained feature pills broke at the largest accessibility text size. Actions now stack at accessibility sizes, and individual flow items are measured and placed within the available width.
- Custom primary buttons looked enabled when disabled. Both shared button styles now represent disabled state, with an explicit selection requirement before report publication.

### New layout hypothesis to test

- Entry cost, seating and unverified opening hours appear with place identity.
- All three experience counts sit directly under the cooling summary, so contrary responses are not buried below contribution UI.
- Cooling features retain the three-item preview and complete expandable list, without invented per-feature vote counts.
- The current-use count remains near the cooling information, while the live-presence contribution action moves below the visitor details and is visually secondary.
- Photo, palette, Directions/Save, the independent report path and post-presence shortcut remain. The questionnaire has not been redesigned in this pass.

Success still needs a timed participant test: can someone explain whether they would go, why, and what is unknown in 30 seconds? A correct decision not to go also counts. Native runtime verification and unit tests are not evidence of improved participant comprehension or completion rates.

## Readability pass — 4 September 2026

**Status: implemented after owner feedback; reduced reading effort is not yet participant-validated.**

The owner found the current information generally understandable but described the page as text-heavy and crowded. They approved a bounded layout cleanup only if none of the previously discussed meanings became unclear or disappeared.

- Chose zero wording changes for this pass. Source comparison confirms all 131 string literals in PlaceDetailView.swift are unchanged; evidence and report/presence logic blocks are also unchanged.
- Introduced local spacing roles to distinguish major section breaks from related text and grouped information, without changing section order.
- Kept cooling evidence prominent; reduced the relative weight of planning/report headings and the width of the independent report button, retaining its outline, icon, label and disabled behavior.
- Removed enclosing boxes around visitor quotations, not the quotations or their attribution. Tightened correction-action/helper grouping and enlarged three local text-action hit targets.
- Preserved the photo, full three-way evidence, source/freshness/uncertainty, all-features expansion, current-use count, persistent Directions/Save, both report entries and every anonymity/duration/eligibility explanation. No model, Saved, Settings, real-location or expiry behavior changed.

Developer verification: 14 existing tests passed; native iPhone Light/Dark and iPad captures; expanded features; independent report opens with no preselection and does not change the people count; presence success still reveals the optional three-way question; maximum Dynamic Type retains the remote-disabled explanation and How this works route. These are implementation checks, not proof of improved usability or a complete accessibility audit.

Next: let first-time users run the same 30-second decision task and observe whether they can find evidence with less reading/search effort. Do not remove protected explanation text merely to make the page shorter.
