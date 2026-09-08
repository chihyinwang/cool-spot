# Cool Spot Prototype Test Guide

## Current owner feedback revision — 7 September 2026

This section supersedes older eligibility and form instructions below. The current owner walkthrough is [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md).

- Confirmed visits have no deadline to start or finish a report. Discard clears answers, keeping the visit eligible. A nearby person can explicitly choose Share a new visit after publishing; retries never create duplicates.
- Saved recognised places and existing Cool Spots open their normal place pages, with Save/Saved and shared private-note controls. Private save success is acknowledged in place.
- Indoor, outdoor and mixed settings use the same location-identification rule. Public names and untrusted place types are optional. An unnamed point needs a decodable identifying photo; optional location directions can identify a floor or corner. Who can use this spot is optional for every place: Everyone, Limited access (with students, members and residents as visible examples), or Not sure. Limited access and unknown eligibility do not block review. Eligibility and cost remain separate. The MVP form omits the Who is it limited to? and Tickets and booking text fields (owner decision, 2026-09-08). Cost to use offers Free to use, Purchase required, Entry fee and Not sure; a free ticket is not an entry fee.
- The public form uses a map preview with one Change location action. Name and helper text share one row. Time limit has presets and hours/minutes controls.
- Explore explicitly shows no matches and offers an optional contribution route. Your own published report reuses the public report layout. The review/account/moderation services remain prototype boundaries.

Older sections below record prior iterations; do not use their 24-hour cutoff, forced indoor name/type, mandatory public-entry confirmation, or free-text time-limit instructions.

## Current human-centred retest — 6 September 2026

These supersede the earlier named/unnamed picker, minimum/ready and photo-toggle scenarios.

1. From Explore +, search a name or select a nearby place. Both types of result show whether you will add cooling information or update an existing Cool Spot. There is only one map-selection route.
2. From a Saved Pin, check the original position, use it, leave the public name blank for an outdoor spot and choose a feature. Add a photo and public-entry confirmation; no photo-identification switch is required. Your private name/note must not become public fields.
3. From a known place, fill the unknown setting and one cooling feature. Send is available without opening optional groups. Expand Entry and seating, return via Back and reselect the same place; retain answers. Changing to a different place must first disclose clearing the previous answers.
4. Open Visitor reports and compare your report with an Example visitor report. Both use the same hierarchy. The list and place preview use latest visit time regardless of author. There is no standalone boxed place-name row or generic Before you go section.
5. Start a visit report, choose a feeling, type a comment and expand What helped in the same form. Finish later and reopen through You; retain the original visit time and answers.

## Earlier test rounds — historical reference

The scenarios below record previous builds. Use the five current tasks above for this build; older minimum/ready, separate optional pages, named/unnamed branches and photo-confirmation requirements no longer apply.

## Targeted retest — approved minimum-first flows

Use these tasks for the current implementation before older exploratory missions. No walkthrough labels should be given in advance.

1. **Interpret the marker:** compare 0, 2, 3 and 10. Ask whether it says anything about seats or temperature. Open How this works; pause, resume, and enable system Reduce Motion. Explain why the example returns to 2.
2. **Read versus contribute:** on Place, find all visitor reports, then independently share how a visit felt. Identify fixture provenance. There must be no invented date or author; the stay distribution remains readable.
3. **Send the shortest report:** choose one experience and publish with no optional answers. Separately add a helping feature, go Back, choose Finish later, relaunch and continue. Check original visit time and no added live presence. Use isolated test fixtures for publication.
4. **Use a saved coordinate:** start a public contribution from a pin away from the simulated current position. Verify suggestions/distances centre on the saved point, search can find an existing Cool Spot, and selecting it becomes an update. Try missing named and exact unnamed paths. Exact requires a real selected image and identification confirmation; private name/note remain unchanged.
5. **Revise and leave safely:** update only seating; add then revisit optional fields; clear an answer to Not added; change place; use Back and Close. Confirm source values versus editable values, reset of place-specific details only after confirmation, and public submission staying in review. Place drafts are session-only; Visitor report Finish later remains durable.

Developer evidence and scope limits: `.impeccable/review/implementation-2026-09-05/VERIFICATION.md`. Debug-only `--shape-preview report|report-required|new-place|update|contribution|pin|place|markers|presence` opens actual production views in a native sheet with memory-only store. `--preview-dark` and `--preview-large` alter only the inspection appearance and Dynamic Type; Reduce Motion is tested with the OS preference. Do not use these preview controls as participant-facing product flows.


## Follow-up: Saved, visitor reports and popsicles

These are prototype comprehension tasks, not evidence that the real social network works.

1. In Saved, explain the difference between Places and Pins. Open **Save a pin here**, read the confirmation, then cancel. Does saving create a public place or start a report? It should do neither.
2. Open a Cool Spot → Visitor reports → **Read all visitor reports** (or tap the quote). Read everything available. Fixture aggregate totals may exceed the individually available reports; missing individual answers and dates are not invented.
3. On an example visitor report, choose **Send a popsicle**. Explain what it means before confirming. Check the Demo success message, Undo, then try again. It is a virtual thank-you, not a cooling vote; nobody is notified in this local prototype.
4. After publishing a test report, use **You → Settings → Prototype controls → Simulate receiving a popsicle**. Return to **You → Your reports → Published → that report**. Check whether the recipient understands the appreciation and which report it belongs to. It is explicitly an example, not a real sender.
5. Open a place → **How this works**. Watch/replay the schematic 2 → 3 example. Explain who sees what, for how long, and whether this demonstration actually shares presence (it does not). With Reduce Motion, the final state and text remain available.

## How we will test

Complete one mission at a time, in order, without reading later missions first. Use the app as naturally as possible rather than trying every button.

- Say what you expect to happen before tapping.
- If you are stuck for about 30 seconds, stop. Do not brute-force the interface: being stuck is an important finding.
- Capture a screenshot whenever something is confusing, surprising, reassuring or enjoyable.
- Saved locations, unfinished reports, reporting eligibility and submitted prototype reports now survive relaunch. Other contribution/review examples still reset; test them in the same session.
- Do not evaluate whether the visual style is final. Do evaluate hierarchy, readability, wording, information density and whether controls look tappable.

After each mission, send the feedback template at the bottom. We will discuss that mission before moving to the next one. Unless there is a blocking bug, changes should wait until the full test round is complete so later missions evaluate the same prototype.

## Mission 1 — Find somewhere suitable

### Situation

It is a hot afternoon and you are near Southwark. You want somewhere free, indoors, with a seat and drinking water.

### Goal

Choose the place you would visit and decide whether you have enough information to go there.

### Success means

You can identify one suitable Cool Spot and explain:

- why it may help you cool down;
- whether entry is free;
- whether seating is available;
- where the information came from;
- how confident you feel about making the journey.

Do not continue to Mission 2 yet. Send feedback for this mission first.

## Mission 2 — Save an ordinary map place

### Situation

A friend mentioned Riverside Café. It is a real map place, but you do not know whether Cool Spot has cooling information about it.

### Goal

Find Riverside Café, understand its status, and save it privately for later without claiming that it is cool.

### Things to evaluate

- Could you tell an ordinary place result from a published Cool Spot?
- Was it clear what Save would and would not do?
- Did you expect the café to appear on the public Cool Spot map after saving it?

## Mission 3 — Remember an unnamed location quickly

### Situation

Imagine you are standing beneath useful tree shade that has no searchable place name. You are in a hurry and do not want to submit anything now.

### Goal

Save your current location with as little effort as possible. Later, find it in Saved and give it a useful private name or note.

### Things to evaluate

- Could you discover how to save the current location?
- Did the app interrupt you with too many questions?
- Could you recognise the saved coordinate later from the landmark, postcode and time?
- Were the quick ideas helpful or restrictive?

## Mission 4 — Turn the saved location into a Cool Spot contribution

### Situation

You later decide the tree shade from Mission 3 could help other people. The app suggests nearby named places, but the shade is not part of either suggested business.

### Goal

Start from Saved, identify it as the exact spot, describe its cooling value and send it for review.

### Success means

You understand:

- why nearby places are suggested;
- whether you are contributing a named place or an exact outdoor spot;
- which place type and cooling features to choose;
- why a photo is required in this case;
- what happens after submission and when it becomes public.

### Things to evaluate

- Did any field feel impossible to answer?
- Was the form too long or broken into sensible steps?
- Were Access and Seating clearly separate questions?
- Did the completion feedback feel rewarding without encouraging spam?

## Mission 5 — Visit an existing Cool Spot

### Situation

Imagine you are physically at Riverside Library. You want to tell others that someone is currently cooling off there. After leaving, you want to report that it felt cool, you stayed for 1–2 hours, and leave a short useful comment.

### Goal

Complete both the temporary check-in and the Visit Report.

### Things to evaluate

- Was “Cool off here” understandable?
- Did the people indicators communicate live self-reports without implying guaranteed capacity?
- Was the ten-minute duration and privacy behaviour clear?
- Did the Visit Report feel different from editing permanent place information?
- Did immediate publication of the comment feel acceptable?
- Was the stay-duration question useful, intrusive or difficult to answer?

## Mission 6 — Understand identity, progress and review outcomes

### Situation

You want to know what happened to your contribution, what signing in would do, and whether the app recognises your help without suggesting that you own a public place.

### Goal

Use the You tab to understand your impact, Cool Hunt progress, contribution status and the benefit of signing in. Use Prototype controls to inspect the possible review outcomes.

### Things to evaluate

- Is the hierarchy of account, impact, Cool Hunt and contributions sensible?
- Does “Published” sound like your information became public, or like the place belongs to you?
- Do “Action needed”, “Added to an existing Cool Spot” and “Not published” explain what happened?
- Is Cool Hunt motivating, childish, irrelevant or promising?
- Does the sign-in card explain the benefit without mixing the action and benefit together?

## Feedback template — send this after every mission

Copy this block and answer in fragments if that is easier:

```text
Mission:
Outcome: Completed / Completed by guessing / Stuck

1. My first instinct was:
2. Easy or pleasant:
3. Confusing or unexpected:
4. Information I trusted / did not trust:
5. Missing information:
6. Information or UI that felt unnecessary:
7. Wording I would change:
8. How I felt during the task:
9. One change I would make first:

Findability: 1–5
Clarity: 1–5
Confidence in the information: 1–5
Effort: 1–5 (1 = very easy, 5 = exhausting)
```

Attach screenshots or a short screen recording where useful. Voice-dictated feedback is fine; it does not need to be polished.

## Severity labels I will apply to the feedback

- **Blocker:** the mission cannot be completed.
- **Major:** it can only be completed by guessing or recovering from a serious misunderstanding.
- **Minor:** noticeable friction that does not change the outcome.
- **Preference:** a subjective visual or wording preference rather than a usability failure.

## Targeted retest after Revision 1

Do not repeat all six missions. Only recheck the interactions that failed:

1. **Save a current location:** confirm that the point and accuracy are visible before saving, then use View to open it.
2. **Resolve and contribute the saved location:** try a nearby named place, search for a different place, and inspect the exact unnamed-spot route. Confirm that the shortest useful submission no longer feels like a questionnaire.
3. **Use Riverside Library details:** without prior instruction, find the actions for (a) sharing a past visit that felt cool, (b) sharing ten-minute live presence, and (c) correcting whether it has air conditioning.
4. **Open You:** explain the page’s purpose, the three contribution counts, sign-in benefit, current review outcomes and the new Cool Hunt goal. Confirm that long history has a separate destination.

For each interaction, stop as soon as the intended action is either obvious or cannot be found. The retest is intended to validate the corrections, not begin another open-ended feature-discovery round.

## Information-first retest

Run this before further contribution-flow design. Do not coach the participant with interface labels.

1. **Decision, 30 seconds:** Open Riverside Library. “You are hot and want to cool down. Would you go here? Tell me what you based that on and what you still need to know.” Record whether they notice experience, sample size, features, entry/seating and unknown hours. Do not require a Directions tap: a well-supported decision not to go is valid.
2. **Conflicting evidence:** Open Shade beside the playground. Ask what the reports tell them, without mentioning “majority.” Check whether 6/14 is understood alongside the 5 Not cooler responses rather than interpreted as broad agreement.
3. **Complete information:** Ask them to find every cooling feature and explain whether the people count proves that it feels cool or has seats available.
4. **Secondary contribution regression:** Ask them to report an ineffective visit at the nearby library without first sharing presence. Verify a blank initial choice, explicit Publish, updated count and Latest, and unchanged people count. Separately verify the preselected shortcut after sharing presence.

Developer checks: empty and tied response sets; single-report grammar; timestamp isolation by place; proximity/24-hour rules; disabled controls; normal and largest Dynamic Type; Light and Dark Mode. Data and location remain simulated; saved items and report journeys survive relaunch. Do not treat these checks as participant findings.

For repeatable native inspection, `--detail-preview` opens the library; `--detail-preview --detail-spot shade` opens the conflicting-evidence / away fixture. These are prototype launch arguments, not user-facing controls.

## Return-to-report test

Moderator setup only: use **You → Settings → Prototype controls → Nearby place** to choose a place or **Away from all Cool Spots**. These controls simulate location, not real permission/GPS. Do not teach participants the product's return path in advance. Debug launch arguments `--you-tab --reports-test-fixtures` provide three memory-only example reports without replacing the user's stored data.

1. **Start without presence:** “You visited and it did not feel cooler. Tell another person what it felt like.” Observe whether the independent entry is found and the person avoids the public-presence action.
2. **Interrupt naturally:** After they choose an answer, say “You need to leave now, but want to finish later.” Record whether they find Finish later and can predict what remains private and where to return.
3. **Leave and relaunch:** Set the location to Away, then relaunch. “Now finish what you started.” You → Your reports must lead to preserved answers and the original visit time, with no completion deadline. Saved is an alternative only if the place was independently saved; saving alone is not eligibility.
4. **Share only presence first:** At a different nearby place, share presence and stop it. Set Away. Your reports → Visits you can report should offer Share how it felt within the existing 24-hour start window, without requiring Save or adding presence again. This visit must not count as an unfinished report until a report is started.
5. **No earlier action:** Use an unconfirmed place while Away. “You just left, but did not use the app while there.” Record whether the explanation is understood and how disappointing this limitation feels; successful explanation does not count as successful reporting.
6. **Late completion:** Started reports still resume after the old 24-hour cutoff. Publishing must retain the original visit time rather than treating submission as a new visit. Simulate leaving after 24 hours must not alter started answers; it expires only unused presence confirmations.
7. **Choose among three reports:** You shows one Your reports entry and the unfinished count, no individual preview. The list names each place and visit time. Publish one; verify the count drops from three to two and only that item moves to Published, where the submitted answers can be opened.

Record intended action, expected result, actual result, hesitation, recovery and emotional response. Avoid asking only “Is this clear?” Compare whether the extra Visit time row is useful when returning, or feels unnecessary when reporting immediately.

Developer capture note: `--shape-preview report --preview-large --preview-bottom` positions the native Form at its publish row; `--shape-preview place --preview-bottom` positions the native detail at Visitor reports. These DEBUG-only positioning flags are screenshot aids, not proof of manual scrolling or VoiceOver traversal. The markers preview with `--preview-bottom` puts 100 and 10 first to inspect full-digit badge rendering.

## Targeted owner retest — 6 September 2026

1. Read your existing report and the example in Visitor reports: can you distinguish the feeling, comment, supporting details and provenance without mistaking missing fixture data for actual answers?
2. Open How this works: watch 2→3 on the map, pause and resume; confirm the animation reads as one new share, not a moving location or an expiring share.
3. Open an existing place update, edit a Note, use Back, and check the retained summary. Main Close must offer discard/keep editing; child pages should not expose a competing whole-flow Close.

The optional-answer, place-selection and photo-toggle alternatives are discussion proposals until the owner selects them; do not instruct participants to expect those changes in this build.
