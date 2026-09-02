# Cool Spot Prototype Test Guide

## How we will test

Complete one mission at a time, in order, without reading later missions first. Use the app as naturally as possible rather than trying every button.

- Say what you expect to happen before tapping.
- If you are stuck for about 30 seconds, stop. Do not brute-force the interface: being stuck is an important finding.
- Capture a screenshot whenever something is confusing, surprising, reassuring or enjoyable.
- Keep the app open between Missions 3–6. Prototype data is in memory and resets if the app is relaunched.
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
