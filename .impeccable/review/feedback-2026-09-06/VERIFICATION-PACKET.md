# Feedback refinement verification packet

This packet proposes bounded checks for the parent. It is not a completed test record. The reviewer did not run the app or mutate product source.

## Revised visual evidence

Provide actual native recaptures with declared paths, using the same paths again for subsequent scoring. Preserve user-1.png through user-7.png unchanged as owner evidence. Supply one full phone viewport and one full tablet viewport from the revised build, plus these focused states:

- Report Ready with only a feeling answered and Publish visible; accepted optional-details treatment collapsed and expanded, including a real filled comment. Maximum Dynamic Type must show the expanded fields and reachable Publish without overlap.
- Visitor reports with an own report and the existing incomplete fixture together; one short and one wrapped comment; verify equal field treatment and subordinate Demo thank-you. Capture Light and Dark across the packet.
- Accepted location entry with search/results and an exact map-point path; demonstrate one named new place and one unnamed spot branch. Show a saved-pin entry centered on the saved coordinate. Search no-result text must expose a usable next action rather than a jargon fork.
- Place section showing the final opening-hours guidance, report evidence, and clearly named place-information update action after wheelchair-row removal.
- Public-form child with an actual task title and native Back, plus selected-photo editor. Show the no-photo required state separately if the gate changes.
- Presence example on actual MapKit at count 2, count 3, paused, and Reduce Motion. A short recording or timed visual sequence is needed to assess gentle motion; stills alone cannot prove bounce quality, pause preservation, or loop timing. Retain Apple attribution. Verify full 10/100 badges if shared component geometry changes.

## Navigation semantics

ContributionFlow owns its dismiss environment outside NavigationStack. Its current Close action dismisses the whole sheet. It must not be reused for a child Done or Back. A child action should pop one path level or use a locally scoped navigation dismiss, preserving draft binding state. ContributionLocationEditor already has a local dismiss after “Use this location”; retain that pop behavior.

Removing every Close risks trapping users because interactive dismissal is disabled while a public proposal is dirty. Keep a clear root exit with existing discard confirmation. Test both entry shapes: direct known-place/update root and choose-place root with a selected destination pushed onto the path. Returning to choose-place must not erase entered details; selecting a different identity still requires the existing replacement confirmation. Avoid custom Back overlays that break native edge-swipe.

Visitor report Finish later has different semantics: its persisted answers survive sheet dismissal and app relaunch. Preserve that action and do not copy public-proposal discard handling into the report flow.

## Photo recommendation

If the owner accepts removing the switch, use instruction before selection such as “Choose a photo that helps someone recognise this exact spot,” then show the preview with Replace/Remove and “The photo and place will be reviewed together.” Selection establishes attached image data, not identity verification. A required decoded photo remains reasonable for an unnamed point that cannot otherwise be recognised from its name, but actual identification quality is a review concern.

Source dependencies at review time: PlaceContributionValues.photoIdentifiesSpot, canSend, requiredHint, photoSummary, Remove, replacement reset, and tests. Do not auto-fill the boolean to satisfy old validation. No image selected/undecodable must keep new exact submission disabled; a valid selected image plus the other required fields enables continuation; removal disables it again. Replacement failure must not destroy the prior valid image or other answers. Named known-place photos stay optional. Legacy updates keep changed-field validation and do not acquire a new mandatory-photo rule.

## Focused functional evidence

Record checks for private answers surviving optional collapse/Back/Finish later; feeling-only publication; no presence increment when reporting; saved-private identity/photo not copied into a proposal; update-only delta semantics; existing duplicate reconciliation; photo add/remove/replace gate; and no change in appearance preference. Reuse existing meaningful regression tests and add cases only for changed state or validation semantics. Report screenshot evidence separately from untested VoiceOver, hardware, or measured-contrast claims.
