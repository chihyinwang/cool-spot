# Working on Cool Spot

## Start here

1. Read [PRODUCT.md](PRODUCT.md) for the current product contract and prototype limits.
2. For validation or navigation changes, read the relevant A–E cases in [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md). Keep those IDs stable for owner feedback.
3. Inspect the working tree and the relevant Swift implementation before editing. Source establishes what the app currently does; it does not prove usability or turn an implementation defect into an approved requirement.

README is the public project introduction. These three files are the active agent documents. Do not create another handoff, context, brief, or parallel test guide by default.

## Current handoff

- Code baseline inspected: `3b8bf457f39e50bdbd650efb3fd4bb2f29f71e8a` plus the 2026-09-08 working changes to ContributionView, contribution tests and these active documents. The form refinement is not committed; preserve the existing working tree and dated review evidence.
- Owner assessment: the current version is usable enough to continue, but still needs validation. Validate journeys and resolve feedback before beginning a broad visual redesign. Follow any newer user instruction that changes this scope.
- Current focus: Add cooling information now requires descriptive names and photos for unlisted-location proposals, uses consistent question labels/picker rows and submit-attempt validation. Scoped agent native checks and 48 passing tests are recorded in the walkthrough. Start the owner retest with **B04**, then affected B03/B05/B06/B10 branches; do not treat agent interaction as owner usability acceptance.
- No app-code change, new feature, deployment, or production rewrite is authorized merely by opening a new session.

## Working with the owner

- Use concise Traditional Chinese; preserve the app's English control labels when giving click paths. Give one small test task at a time and accept feedback by its A–E ID.
- Ask necessary questions in ordinary text. The owner reported that structured question widgets were not visible; never tell them to select an unseen option “above.”
- Make independent product/UX judgments and explain material disagreements. Preserve the distinction between owner feedback, design hypotheses, source inspection, automated tests and native interaction evidence.
- Proceed with work already authorized. Use one agent by default; do not reopen the earlier subagent permission discussion unless the user asks for parallel work.
- Preserve the existing SwiftUI, teal/mint palette, system typography and native navigation for scoped changes. If using Impeccable, use PRODUCT's iOS context and native evidence; a web detector does not validate SwiftUI layout.

## Code map

| File | Main responsibility |
|---|---|
| `cool-spot/ContentView.swift`, `cool_spotApp.swift` | App entry, tabs, store setup, appearance and DEBUG inspection routes |
| `cool-spot/PrototypeModels.swift` | Fixtures, shared colors, domain types, persistence, eligibility, publishing and contribution records |
| `cool-spot/ExploreView.swift` | Map/search/filter UI, discovery and quick-save/add entry points |
| `cool-spot/PlaceDetailView.swift` | Cool Spot and ordinary-place detail, presence, report form and explainer |
| `cool-spot/ContributionView.swift` | Public place selection, form, location/photo handling and review validation |
| `cool-spot/SavedYouViews.swift` | Saved/private notes, You, report history, contribution outcomes, account and settings |
| `cool-spot/VisitorReportsView.swift` | Shared report rendering and popsicle UI |
| `cool-spot/PrototypeSharedViews.swift` | Shared native visual components |
| `cool-spotTests/cool_spotTests.swift` | XCTest model and persistence coverage |

Some legacy cases, fields, comments and test names still exist. Trace the reachable UI and actual assertions before inferring behavior from a name. Removed form fields must not reappear just because the model retains compatibility data. Avoid unrelated cleanup while addressing a bounded request.

## Build and verify

Repository on this workstation: `/Users/chihyinwang/Desktop/cool-spot`. Open `cool-spot.xcodeproj`; scheme `cool-spot`, test target `cool_spotTests`. Deployment target is iOS 18; iPhone and iPad are supported. Use the installed Xcode/Simulator SDK, not a hard-coded future version.

```sh
xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/cool-spot-build build
xcrun simctl list devices available
```

For model/persistence changes, select an isolated QA simulator from that inventory and replace `QA_SIMULATOR_UDID` before running:

```sh
xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=QA_SIMULATOR_UDID' -derivedDataPath /tmp/cool-spot-tests test
```

For UI changes, build and inspect the affected real SwiftUI flow on iPhone and iPad; include narrow width, large Dynamic Type and dark appearance where relevant. Use native interaction/screenshot tools. A build or source review is not an interaction test. Run only checks appropriate to the change; documentation-only edits need content, link and scope checks, not an app rebuild.

DEBUG inspection uses `--shape-preview` followed by `contribution`, `contribution-pin`, `new-place`, `update`, `report`, `report-required`, `visitor-reports`, `place`, `pin`, `markers` or `presence`; `--preview-large` and `--preview-dark` alter the preview. These routes use memory-only stores; the `place`/`visitor-reports` previews may read existing local reports for display. `--reports-test-fixtures` supplies disposable report examples. Do not use preview outcomes as proof that production persistence works.

## Protect the working state

- Check `git status` before changes; preserve unrelated edits and staging. Do not commit, reset, or discard user work unless requested.
- Normal launches use device-local saved data. Use isolated simulators for destructive/reset scenarios; never erase the owner's reports, notes, pins, preferences or photo library to prepare a test.
- Before replacing the app on the owner's simulator, inspect its current state, protect any in-progress input, back up app data and verify persisted values afterwards. Do not leave the owner's app in a memory-only preview.
- Simulation controls can alter local test records. Use the walkthrough's prerequisites and only act on designated test data.

## Keep the documents consistent

- **PRODUCT:** define each current rule and limitation here once. Include the source symbol for non-obvious rules. Update this file when implemented behavior changes; flag discrepancies with user intent instead of silently endorsing them.
- **Walkthrough:** update affected click paths, expected outcomes and dated verification status when flows change. Expected outcomes are checks of PRODUCT, not a competing specification. Do not mark a case passed because code exists or an older test passed.
- **AGENTS:** update environment/workflow guidance and the handoff's current focus when the stage changes. Keep detailed results in the walkthrough.
- **README:** keep it a public introduction and setup guide, without session progress or agent instructions.

Do not append another “current revision supersedes the sections below.” Replace obsolete active text. Check active Markdown links, A–E IDs and contradictory requirements after documentation edits. Record the source commit plus relevant working changes when refreshing the baseline.

Historical `.impeccable/` reports and screenshots are evidence of their dated runs, not current requirements or permission. Read only evidence relevant to the task. Old root documents can be retrieved from Git when history is explicitly needed, for example `git show 3b5a8ca:PROTOTYPE-BRIEF.md`; do not restore them as active instructions.
