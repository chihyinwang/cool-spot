# Report journey verification — 4 September 2026

## Delivered behavior

- Align the detail's source badge and place type; use Museum or cultural venue instead of Culture. Let the row stack when its natural width does not fit.
- Keep report answers private and persistent, including interrupted forms and app relaunches. Finish later and You → Your visits provide explicit continuation.
- Route Saved Cool Spots to the complete place detail, retaining independent reporting and evidence.
- Preserve the original 24-hour deadline through leaving, restarting, presence and repeated opening. Expired answers remain viewable; a new visit starts without carrying over old answers.
- Separate visit time from submission time and use visit time for public freshness. Block duplicate publication for the same confirmation.
- Persist the original local ten-minute presence deadline across relaunch; Stop sharing and natural expiry do not revoke report eligibility.
- Keep the no-prior-action remote restriction visible with a recoverable explanation. Location itself remains simulated.

## Verification

- 23 XCTest cases passed, 0 failures. `/tmp/cool-spot-journeys-test.log`; result bundle `/tmp/cool-spot-tests-information/Logs/Test/Test-cool-spot-2026.09.04_23-21-24-+0100.xcresult`.
- Final UI-only accessibility changes built successfully: `/tmp/cool-spot-journeys-build.log`. No additional model behavior changed after the 23-test pass.
- Native iPhone 16 Pro / iOS 18.2: source/category alignment; nearby independent report initially unselected; Not cooler + Drinking water retained through Finish later, leaving and two relaunches; Saved opens full detail; remote continuation publishes successfully; people count remains 2.
- Native presence shortcut: Gallery count changes from 1 to 2; actual sharing end time and report deadline shown; Much cooler opens the form selected but does not publish. Your visits survives relaunch.
- Native expiry: prototype control changes the return action to View this visit. Expired sheet shows the private time and answer, states that nothing was published, and offers no Publish control while away.
- iPad 11-inch / iOS 18.2 Dark Mode: place-detail layout and report unavailability checked. This is a device-class layout check, not a complete iPad journey test.
- Maximum accessibility Dynamic Type on iPhone in Dark Mode: choices remain legible without decorative leading symbols; the selection marker remains. Deadline/privacy text moves into the scrollable form to keep the fixed Publish bar usable. Visit time stacks its label above the date controls. Scrolling reaches the retained deadline and date controls.
- Restored the test iPhone's original large text size, removed process-only Dark Mode overrides by relaunch, and shut down the two test devices that were initially shut down. Installed the final build on the user's already-booted iPhone 17 Pro Max for testing; report examples created during QA remain confined to the separate iPhone 16 test device.
- `git diff --check` passes. No web prototype CSS or generated imagery used. No external report was published.

## Captures

- `place-type.png`: final source/type alignment on iPhone.
- `you-resume.png`: final private return entry.
- `report-form.png`: preserved selected answer and explicit publication; the subsequent accessibility-only layout changes do not change the normal-size structure.
- `report-unavailable.png`: no-prior-action explanation.
- `expired-answers.png`: no publication after expiry, retained private answer.
- `large-type-dark.png`: final maximum-type date controls and persistent Publish bar.
- `tablet-dark.png`: iPad Dark Mode layout.

## Limits

Agent operation and tests do not establish first-time comprehension. Real location permission, inaccurate-location recovery, background/server synchronization, editing a published report, and distinguishing repeated visits within a day remain unimplemented. Other visitors' counts and historic reports are fixtures. The genuine visitor who did nothing in the app while nearby still cannot report remotely; this is a product-policy limitation, not a completed reporting journey.
