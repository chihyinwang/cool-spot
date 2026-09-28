# Working on Cool Spot

## Start here

1. Read [PRODUCT.md](PRODUCT.md) for the current product contract and prototype limits.
2. For validation or navigation changes, read the relevant A–E cases in [OWNER-JOURNEY-WALKTHROUGH.md](OWNER-JOURNEY-WALKTHROUGH.md). Keep those IDs stable for owner feedback.
3. Inspect the working tree and the relevant Swift implementation before editing. Source establishes what the app currently does; it does not prove usability or turn an implementation defect into an approved requirement.

README is the public project introduction. These three files are the active agent documents. Do not create another handoff, context, brief, or parallel test guide by default.

## Current handoff

- App-code baseline: `4ad70e3`, the 2026-09-26 checkpoint titled `Add local Cool Spots API handler and replace catalogue naming`, based on parent `4b8f828`. It includes the local TypeScript handler/tests, Cool Spot naming across Swift/data/tooling, the v4 read contract with legacy compatibility, placeholder configuration and environment-file exclusions. The earlier discovery implementation remains from `42c0905`. The owner-authorized 2026-09-28 checkpoint on `Prototyping`, titled `Add local Cool Spot database foundation and design notes` with parent `4ad70e3`, records five local migrations, two database tests, Supabase configuration, the active design documents and Git-hygiene cleanup. App/API implementation is unchanged. No fetch or push is authorized. Resolve the checkpoint hash from Git rather than treating the app-code baseline as current HEAD. Existing test evidence is in the walkthrough; unchanged tests are not rerun solely for committing or resuming.
- Owner assessment: the current version is usable enough to continue, but still needs validation. Validate journeys and resolve feedback before beginning a broad visual redesign. Follow any newer user instruction that changes this scope.
- Current focus, 2026-09-28: the owner requested recording the extended place/report/query discussion; [PRODUCT's backend conclusion](PRODUCT.md#場所後端設計結論) owns the design. Core direction: places identity/adopted facts, zero or one current Cool Spot per Place, many visitor_reports, and parent/child relationships on Places. Preserve raw sources, field-level provenance and accepted map identities. Initialize from the existing 250 GLA records plus three labelled community examples without automatic Apple replacement. Keep existing Cool Spot IDs and v4 response compatibility. New UUID generation, exact columns, scope/place_type ownership, provenance/history, constraints and grants still need design. Next define the smallest places/cool_spots field-and-ID migration batch before tests; no sixth migration or next-batch tests exist. Independent toilet/sports search remains undecided; do not implement a general-purpose platform.
- Backend implementation evidence, last verified 2026-09-27: only the local Docker database was started, not API/Auth/Studio. Five owner-written migrations are applied, ending with 20260927151756. Storage DB-C01–C12 passed 78 assertions; permissions DB-C13–C15 passed 24 after a test-only SET ROLE setup correction. No owner SQL changed; the table was empty and temporary test grants were rolled back. The custom API is the sole client read entry, with public reads requiring no sign-in; actual backend login/connection and HTTP integration are pending. Raw-coordinate input checks, complete schema, seed and API-C05 remain unimplemented. Seven API/eleven Python/88 Swift results are earlier evidence, not new runs. The walkthrough retains source-field and Apple identity audits. Documentation changes do not authorize SQL application, iOS/JSON changes, cloud work, deployment, commit or push; ViewCoolSpots remains separate.
- Retained discovery evidence: the ten-case validation is committed in 42c0905. There are 136 automatic same-place links, 7 reviewed same-place links, 1 containing-venue link, 87 needs-review and 19 no-candidate records. Horniman duplicate identity and the pharmacy museum's missing Apple identity remain unresolved. See the walkthrough and discovery-audit.json for the dated seven Swift/eleven Python test results and native evidence. DATA-DISCUSSION-2026-09-23.md remains an unchanged historical snapshot, including its former file names; use this code map and PRODUCT for current paths. Current accepted backend scope is recorded in PRODUCT and the walkthrough.
- Documentation reconciliation, 2026-09-23: current A–E steps use normal-launch Cool Spot list records and persistent storage. The 40 case IDs and dated historical evidence are retained. This was a source/document review, not a new native walkthrough or test run; outstanding owner checks remain outstanding. The app-code baseline above is separate from later documentation commits.
- No app-code change, new feature, deployment, or production rewrite is authorized merely by opening a new session.

- Large-place/report discussion, 2026-09-28: [PRODUCT's park-point discussion](PRODUCT.md#園內點位與地圖收合) records the current recommendation: reports target one public Place, optional precise visit location does not create a child Place, and a parent page aggregates reports while retaining each actual target. The parent need not be a Cool Spot. Allowing qualified reports on confirmed public Places without cooling information is a proposal, not implemented eligibility; current Swift reports still target CoolSpot through spotID. Public-place intake, location sharing, parent/child visit entitlement, compatibility and moderation rules remain unresolved. Same-place reconciliation and optional containment are separate choices; a parent choice must not replace a child's point or publish a private Pin. The owner tentatively accepts collapsed internal markers; proposed spot counts remain separate from Cooling here people. UI/copy/zoom/count scope and relationship safeguards need design and validation before implementation.
- Query/performance discussion, 2026-09-28: support the core separation with spatial filtering, indexed identity joins, bounded results and batched related reads; nearby Cool Spots use each child Place's own point, regardless of whether its parent has cooling information. Do not fetch all reports/raw sources for each map result or introduce N+1 reads. One SQL may join tables within one API request. Spatial/foreign-key/report indexes, plans and load tests are recommendations, not completed migrations or capacity evidence. The first reader still preserves the complete 253-item v4 contract. These documentation conclusions authorize no SQL application, API/iOS/JSON change, deployment or new performance claim.

## Working with the owner

- Use concise Traditional Chinese; preserve the app's English control labels when giving click paths. Group related learning cases into manageable batches and accept journey feedback by its A–E ID.
- Ask necessary questions in ordinary text. The owner reported that structured question widgets were not visible; never tell them to select an unseen option “above.”
- Connected-slice teaching agreement, updated 2026-09-25: use the personal essential-tdd skill with this explicit owner override: group cases teaching the same concept into one manageable batch, explain their purpose together, write the batch tests and necessary helpers, and verify Red together rather than waiting for a separate understanding confirmation after every test. Provide the exact file/location and one complete minimum Green implementation for the owner to type, including SQL and TypeScript. Faster batching does not itself delegate production Green or refactoring to the agent; honor subsequent explicit delegation, including the completed 2026-09-25 naming refactor. Ask only about a material unresolved decision or when the owner requests more explanation. Keep cases and actual evidence in the walkthrough; do not repeat the completed grilling interview or silently expand the connected slice.
- Owner clarification, 2026-09-26, reaffirmed 2026-09-27: keep the causal sequence visible during work. Before each meaningful operation, explain its purpose and which files or local database state it changes; afterwards explain the result and its limits. Distinguish saving a migration file from applying it, and local database work from cloud changes. Explicitly identify decisions the owner needs to make, with a recommendation and concrete tradeoffs, before encoding an unresolved rule. Continue already authorized work without adding routine permission or per-test comprehension gates.
- Owner clarification, 2026-09-27: the owner asked to personally apply a migration once; this was completed for 20260927101339 using the provided Mac Terminal command with --local and the prototype workdir. Agent did not apply or reset it, and independently checked history and focused tests after the owner's success report. Keep explaining where operations happen and distinguish writing a file, applying it and testing it. This exercise does not authorize cloud operations or change the owner-written core Green agreement.
- Make independent product/UX judgments and explain material disagreements. Preserve the distinction between owner feedback, design hypotheses, source inspection, automated tests and native interaction evidence.
- Proceed with work already authorized. Use one agent by default; do not reopen the earlier subagent permission discussion unless the user asks for parallel work.
- Preserve the existing SwiftUI, teal/mint palette, system typography and native navigation for scoped changes. If using Impeccable, use PRODUCT's iOS context and native evidence; a web detector does not validate SwiftUI layout.

## Code map

| File | Main responsibility |
|---|---|
| `cool-spot/ContentView.swift`, `cool_spotApp.swift` | App entry, tabs, store setup, appearance and DEBUG inspection routes |
| `cool-spot/CoolSpotsResponse.swift`, `cool-spot/Resources/CoolSpots.prototype.json`, `cool-spot/Resources/CommunityCoolSpots.prototype.json` | Typed v4 mock response with v1/v2/v3 compatibility, 250 GLA records, source adapter and three-state comparison fixtures |
| `cool-spot/PrototypeModels.swift` | Fixtures, shared colors, domain types, persistence, eligibility, publishing and contribution records |
| `cool-spot/ExploreView.swift` | Map/search/filter UI, discovery and quick-save/add entry points |
| `cool-spot/PlaceSearch.swift` | MapKit search, cancellation/debounce/state, result mapping and search feedback |
| `cool-spot/PlaceDetailView.swift` | Cool Spot and ordinary-place detail, presence, report form and explainer |
| `cool-spot/ContributionView.swift` | Public place selection, form, location/photo handling and review validation |
| `cool-spot/SavedYouViews.swift` | Saved/private notes, You, report history, contribution outcomes, account and settings |
| `cool-spot/PlacePhotos.swift`, `cool-spot/PrototypePublication.swift`, `cool-spot/PrototypePhotoStorage.swift`, `data/cool-spots/`, `scripts/cool_spots/` | Published photo strip/gallery/viewer, source snapshots, producer schema, mapping audit and reproducible reconciliation |
| `cool-spot/VisitorReportsView.swift` | Shared report rendering and popsicle UI |
| `cool-spot/PrototypeSharedViews.swift` | Shared native visual components |
| `cool-spotTests/cool_spotTests.swift` | XCTest model and persistence coverage |
| `supabase/functions/cool-spots/handler.ts`, `handler_test.ts` | Local HTTP 200/500/405 handler with seven passing tests; database reader and hosted integration remain pending |
| `supabase/tests/database/cool_spots.test.sql`, `cool_spots_permissions.test.sql`, `supabase/migrations/` | Five owner-written migrations applied; DB-C01–C12: 78 Green; DB-C13–C15: 24 Green after a test-only SET ROLE setup correction |
| `supabase/config.toml`, `supabase/.gitignore` | CLI-generated local configuration for project cool-spot-prototype and local-state exclusions; no cloud project link |
| `.gitignore`, `.env.example` | Exclude real environment values, private/signing keys, local database files/backups and Supabase CLI state; keep migrations and placeholder client configuration trackable |

Some legacy cases, fields, comments and test names still exist. Trace the reachable UI and actual assertions before inferring behavior from a name. Removed form fields must not reappear just because the model retains compatibility data. Avoid unrelated cleanup while addressing a bounded request.

## Build and verify

Backend local environment: Supabase CLI 2.118.0, Docker Engine 29.8.0 and PostgreSQL 17.6 were verified on 2026-09-26. The cloud database version has not been checked. Run the following commands from this prototype checkout's root after confirming branch `Prototyping`; `--workdir .` refers to that root. The isolated container is `supabase_db_cool-spot-prototype`; run `SUPABASE_TELEMETRY_DISABLED=1 supabase db start --workdir .` to start only this local database. Use `supabase stop --workdir .` to stop while retaining data; do not use `--all` or `--no-backup` for routine stopping. No host psql installation is needed: local read-only inspection can use `docker exec supabase_db_cool-spot-prototype psql -U postgres -d postgres -X --no-password -v ON_ERROR_STOP=1`. The generated configuration retains CLI defaults; cool_spots now has verified local grants/RLS from the fifth migration. New domain tables still need their own explicit access design and tests before exposure. Do not run status/start output containing credentials into chat or Git; capture and filter it. No Supabase login/link, cloud SQL, deploy or push is authorized by local setup.

Prototype worktree: this `cool-spot-prototype` checkout, branch `Prototyping`. The separate sibling checkout `../cool-spot` uses `ViewCoolSpots`; do not copy prototype code into it for this task. Always resolve and verify the checkout before executing commands. Open `cool-spot.xcodeproj`; scheme `cool-spot`, test target `cool_spotTests`. Deployment target is iOS 18; iPhone and iPad are supported. Use the installed Xcode/Simulator SDK, not a hard-coded future version.

```sh
xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/cool-spot-build build
xcrun simctl list devices available
```

For model/persistence changes, select an isolated QA simulator from that inventory and replace `QA_SIMULATOR_UDID` before running:

```sh
xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=QA_SIMULATOR_UDID' -derivedDataPath /tmp/cool-spot-tests test
```

Owner clarification, 2026-09-15: this is a prototype. Use only iPhone 17 Pro Max for a brief native interaction check and necessary compilation. Do not run iPad, multiple screen sizes, Dynamic Type or appearance matrices, or spend time on broad polishing. Let the owner judge feel through direct use. Run focused model checks only when changed behavior warrants them. A build or source review is not an interaction test. Documentation-only edits need no rebuild.

DEBUG inspection uses `--shape-preview` followed by `contribution`, `contribution-pin`, `new-place`, `update`, `report`, `report-required`, `visitor-reports`, `place`, `pin`, `markers` or `presence`; `--preview-large` and `--preview-dark` alter the preview. These routes use memory-only stores; the `place`/`visitor-reports` previews may read existing local reports for display. `--reports-test-fixtures` supplies disposable report examples. `--example-cool-spots` opens the older example Cool Spot list in memory only; normal launches use 250 GLA records, three labelled community examples, the British Museum ordinary-place seed and device-local journeys/contributions/publications. Run the current A–E walkthrough without these fixture/preview flags. Do not use memory-only preview outcomes as proof that normal-launch persistence works.

## Protect the working state

- Check `git status` before changes; preserve unrelated edits and staging. Do not commit, reset, or discard user work unless requested.
- `AGENTS.md` and `OWNER-JOURNEY-WALKTHROUGH.md` are tracked in this prototype worktree. The separate rebuild checkout’s local/excluded-document policy does not apply here. Include authorized documentation changes when committing; do not force-add or reset files based on assumptions about the other checkout.
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
