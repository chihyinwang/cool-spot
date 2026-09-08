# Owner feedback verification — 7 September 2026

## Scope and evidence

The owner requested fixes for A05, A06, A09, B03–B07 and removal of the report-start deadline, plus agent-led D/E testing. Work extends the existing SwiftUI visual system. Native interaction uses a newly created **Cool Spot Journey QA** iPhone 17 Pro Max, iOS 26.4 (`8AA009D5-F5E5-4FA7-813D-51E129758BCA`). Test-only notes/reports are marked QA. The owner’s original simulator was not used to create or delete test data.

The final implementation passed **44 XCTest cases, 0 failures, 0 skipped** (`test-summary.json`, exported from the final xcresult). Native checks also covered an isolated iPad Pro 11-inch simulator. This is not a claim of a physical-device usability or full VoiceOver audit.

## Changes and product decisions

- A05: shared private-note editor gives a readable checkmark and saved acknowledgement; editing again restores Save. Saves persist locally. No blocking success alert.
- A06: Saved recognised places open the same recognised-place detail used by Explore, with direct Saved/Save and the same private-note editor used by existing Cool Spots and Pins. Pins remain a separate private coordinate screen. Café Directions is now a real walking-directions link.
- A09: removed fallback unrelated search results. Empty search explicitly says No places found, shows the query, suggests another search and offers Add cooling information at a location. Search remains fixture-backed, not live map search.
- B03/B04: a selected point is represented by a map preview and one Change location action. Public name/helper are a single form row. Indoor/outdoor/both follow the same rules: name optional; untrusted type optional; location directions can describe a fourth-floor corner. Without a name, a decoded photo and confirmed visitor entry are required. Named source locations retain their source facts; categorisation is not a quiz.
- B06: Time limit has Not added, Not sure, No stated limit, 30 minutes, 1 hour, 2 hours and Other duration. Other uses hours/minutes, including 90 minutes; no primary free-text entry.
- B07: Back/reselecting the same place keeps the current public form’s in-memory answers. Changing identity asks before clearing. Closing the public contribution discards that unsent form; private notes/visit drafts persist separately via the local UserDefaults JSON snapshot.
- C03/D: a confirmed visit has no start/finish deadline. Discard clears answers but preserves confirmation. A nearby user can explicitly Share a new visit after publishing; repeated Publish/opening cannot silently duplicate a visit. Visit time defaults to the original confirmation and can be corrected to a past date; future dates are rejected.
- D08: Your report and public Visitor reports share VisitorReportContent. Submission wording accurately describes local prototype visibility instead of promising unsupported comment-reporting.
- E: removed unsupported cross-device account promises, marked account/review/progress previews and made review explanations easier to read. Report a problem explicitly says it is not connected instead of offering a no-op Send report.

## D journey results

| Case | Native check | Result |
|---|---|---|
| D01 | Library Share how it felt, no presence action; Publish disabled until feeling selected | Pass. Not cooler is valid. Library remained at two shared presences. |
| D02 | QA REPORT comment, Air conditioning selected and group collapsed, 30–60 minutes chosen, date changed to September 6 | Pass. Optional answers remain; future calendar dates are disabled. |
| D03 | Finish later; set Away; terminate and relaunch app; You → Your reports → Continue | Pass. Feeling, helped feature, time here, comment and September 6 visit time restored. |
| D04 | Simulate a visit 7 days ago while Library already had a draft | Pass. Started draft’s answers/date remain unchanged and it can publish away. Seven-day report eligibility also has a relaunch regression test. |
| D05 | Gallery confirmed separately; create Much cooler draft; view Unfinished (2) alongside Library’s Not cooler draft | Pass. Independent dates and answers. Saved’s full-place report entry is the same view; it was verified structurally, not separately repeated in this run. |
| D06 | Open Gallery; cancel Discard and confirm Much cooler remains; then Discard; see Gallery in Visits you can report; reopen while away | Pass. Reopened form has no feeling selected and retains its August 31 visit date. No Library data lost. |
| D07 | Resume Library and Publish; Done; read Published; revisit Library | Pass. September 6 visit retained, September 7 publication separate; one published record; You’ve shared this visit; no presence increment. Duplicate and explicit-new-visit protection also passed model tests. |
| D08 | Open own report from You; tap newest preview from Library to public report list | Pass. Same content hierarchy; own report is first by visit date. Complete example below uses same layout and explicit Example provenance. |

The C03 correction was additionally checked in the native UI: Gallery had only shared presence, no draft; the test control backdated it seven days and set Away. It remained in Visits you can report and opened a new report with the original backdated visit. See `c03-seven-days-later.png`.

## E journey results and gaps

| Case | Native check | Result / remaining gap |
|---|---|---|
| E01 | Submit a Library feature update; see In review; run each of Needs clarification, Publish, Merge, Do not publish and return to history | State display passes. **Incomplete product flow:** no follow-up editing/resubmission, no link to merged destination, no map mutation or review service. Place proposals/review outcomes reset after app relaunch. Current UI labels these as prototype outcomes. |
| E02 | Public example → Send a popsicle → Cancel; repeat and confirm; see sent; Undo | Local demo passes. Own report has no self-thank button. No other person is notified. |
| E03 | Settings names the target Library report; simulate receipt; open Published report | Pass. Correct report shows received badge and explicit Example copy. Receipt persistence is covered by model tests; the receipt screen was not separately reopened after the final installation. |
| E04 | Sign in entry, preview account, return; Cool Hunt after Gallery presence | **Prototype only.** Local account flag changes; no authentication/sync/sign-out service. Culture unlock is reflected (3/12); Shade finder and some totals remain fixed. False cross-phone retention wording has been removed. |
| E05 | Switch Dark; set simulator’s real Dynamic Type to accessibility-extra-extra-extra-large; open Gallery report and scroll to Publish; Report a problem | Large/Dark layout passes: fields wrap and Publish is reachable at the end of Form. Problem reporting is explicitly unavailable. Reduce Motion/tablet/final-color results are recorded below. |

## Evidence files

- `b03-location-and-name.png`: initial native location/name grouping. Final short helper wording is confirmed after correction.
- `b06-duration.png`: actual Other duration → 1 hr 30 min controls.
- `c03-seven-days-later.png`: old unstarted visit still reportable alongside an unrelated draft.
- `d08-published-report.png`: own published report using the common reader.
- `e05-large-dark-publish.png`: real maximum Dynamic Type, Dark, reachable Publish.
- `a05-saved-feedback-final.png`: final readable saved acknowledgement in Light appearance.
- `e05-reduce-motion.png`: actual system Reduce Motion enabled; static final count of three.
- `tablet-location-dark.png`: selected map, grouped name/helper and optional location directions on iPad.
- `tablet-report-large-light.png`: maximum text-size preview on iPad, scrolled to the fully visible Publish button.
- `test-summary.json`: authoritative final XCTest result, 44 passed.

## Final confirmation

Final test run: **44 passed, 0 failed, 0 skipped**. Log: `/tmp/cool-spot-owner-feedback-20260907-tests-final.log`. Result bundle: `/tmp/cool-spot-owner-feedback-20260907/Logs/Test/Test-cool-spot-2026.09.07_01-16-18-+0100.xcresult`. No source edits followed this test run; only evidence documentation was completed.

Final native checks confirmed readable saved feedback after editing a Pin, explicit account-preview/no-sync copy and readable review reasons in Dark appearance. iPad contribution layout in Dark and the report form at maximum preview text size in Light were checked; form controls remain scrollable and Publish is fully visible. On the phone, the actual iOS Reduce Motion setting produced a static count of three with no Pause action. **Small remaining copy issue:** its illustration footer still mentions a restarting loop even though motion is disabled. This is a wording gap, not a failing animation setting.

The test phone’s actual Dynamic Type and Reduce Motion settings were restored. Both agent-created QA simulators were shut down. The final app was installed and normally launched on the owner’s original iPhone 17 Pro Max simulator (`59F1EEA8-6D00-4920-B014-DA49728E6197`). Checksums for the existing journey snapshot (including Saved/private notes, visit drafts and reports), popsicle snapshot and appearance preference were unchanged across installation. The original simulator was left open on Explore; no owner records were created, edited or deleted for testing.

Product gaps remain: published visit reports have no edit/delete UI; review outcomes have no follow-up submission/merge destination/map update service; accounts and some progress totals are demonstrations; problem reporting is not connected. Failed network requests, real location permissions and physical-device/VoiceOver usability remain outside this prototype verification.

## Sources informing UX choices

[Apple Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback?changes=__4_8): status acknowledgement should be proportionate; local saved feedback avoids interrupting the task. [Apple Text fields](https://developer.apple.com/design/human-interface-guidelines/text-fields?changes=_7): persistent labels and clear label/field relationships informed the grouped name/helper row. Indoor naming rules and the reporting deadline are product decisions, not Apple requirements.
