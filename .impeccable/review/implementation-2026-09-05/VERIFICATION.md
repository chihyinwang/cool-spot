# Cool Spot — approved SwiftUI implementation verification

2026-09-05. Owner approval: “都同意”, covering four wireframes and three proposals in ../shape-2026-09-05/SHAPE.md. This is implementation verification, not participant validation.

## Build and regression checks

- `xcodebuild -project cool-spot.xcodeproj -scheme cool-spot -destination 'platform=iOS Simulator,id=59F1EEA8-6D00-4920-B014-DA49728E6197' -derivedDataPath /tmp/cool-spot-approved-build test` succeeded: **38 tests passed**, zero failing cases. Log: `/tmp/cool-spot-approved-tests.log`.
- Includes the existing 28 journey/evidence/reaction tests and 10 focused public-contribution tests. Coverage includes saved-coordinate privacy, truthful missing requirements, valid exact-spot photo/access, valid meaningful updates, duplicate rebasing, preservation of private state and report/presence evidence, and submission deduplication.
- `git diff --check` passed. Existing worktree modifications were retained; this-turn source snapshots are in before/.

## Native capture matrix

All images are unedited `simctl io screenshot` captures from the rebuilt native app. DEBUG previews use production SwiftUI views inside native sheets and memory-only stores.

| Evidence | Device / appearance | What it establishes |
|---|---|---|
| phone-report-light.png | iPhone 17 Pro Max, Light | Ready summary, retained visit time, optional items and enabled full-width Publish |
| tablet-report-dark.png | iPad Pro 11-inch M5, Dark | Native sheet layout and pinned action |
| phone-report-large-dark.png | iPhone, Dark, accessibility5 | Largest text reflow |
| phone-report-large-footer-dark.png | iPhone, Dark, accessibility5 | Full publish label after positioning to bottom |
| phone-report-published-large-dark.png | iPhone, Dark, accessibility5 | Successful explicit publication in memory-only prototype |
| phone-newplace-light.png | iPhone, Light | Source name/type; missing Setting remains unselected |
| tablet-update-large-light.png | iPad, Light, accessibility5 | Existing place starts in update mode; native wrap |
| phone-pin-light.png | iPhone, Light | Private memory separated from one public contribution entry |
| phone-saved-anchor-light.png | iPhone, Light | Actual Add cooling information entry opens suggestions centred on saved pin |
| tablet-markers-light.png | iPad, Light | Shared component: no badge at 0, person/count at 2/3 |
| tablet-markers-digits-light.png | iPad, Light | Full 10/100 labels without dots or caps |
| phone-presence-reduce-dark.png | iPhone, Dark, OS Reduce Motion enabled | Static 3, equivalent explanatory text, no looping control |
| phone-presence-paused-light.png | iPhone, Light | User pause retains count and offers Resume |
| phone-place-reports-light.png | iPhone, Light | One truthful example preview, View all, retained stay distribution, contribution below reading |

The devices run iOS/iPadOS 26.4. Phone capture resolution 1320×2868; tablet 1668×2420. Ordinary previews use Dynamic Type large; accessibility previews use accessibility5 without a production size cap.

## Interaction checks

- Chose a required feeling, reached Ready, entered What helped, selected Drinking water, and returned with the answer retained. Finish later dismissed the report.
- After simulator reboot restored its accessibility tree, actual native Scroll Up and Scroll Down accessibility actions traversed the maximum-type Form. Clicking Publish reached the success screen. Initial coordinate drag/wheel attempts had no observable movement; the later accessibility-action check resolved that verification gap.
- Saved Pin → Add cooling information opened the shared chooser at the saved coordinate.
- Presence example displayed 2 and 3. Pause changed to Resume and held 3; Resume returned to Pause. Real OS Reduce Motion was enabled for its static capture, then restored to its original false value.
- Report/footer and visitor-section captures can use DEBUG `--preview-bottom` positioning; marker digit inspection changes only the inspection list order. These aids are not themselves proof of manual navigation. Full VoiceOver traversal, contrast measurement, hardware/GPS behavior and first-time comprehension remain untested.

## State preservation and scope

Device preferences were backed up outside the repository at `/Users/chihyinwang/.codex/cool-spot-device-backup-2026-09-05/device-preferences.plist`. Existing protected preference values were compared unchanged; absent persisted report/reaction keys stayed absent. Preview publication uses memory-only storage. The existing persistence schema and start-window rules were preserved and exercised by regression tests.

Public place additions and updates remain session-only proposals for review, with no real service submission or photo upload. Exact unnamed spots use a real decodable image plus legal public-access and identification confirmations; the image is kept only with that session proposal. No new private draft persistence or provider/GPS integration was introduced.

## Independent finish review

See FINISH-REVIEW.md for the initial `fix` verdict: meaningful update validation, selective duplicate rebasing, and removal of a redundant private-pin eyebrow. Those three changes were implemented in one batch and returned with recaptures for scoped scoring. Final disposition is recorded in VERDICT-PASS.md. Design documentation is in DESIGN-NOTES.md.

Final verdict: **ship**, scoped to all three listed fixes being resolved, with no fix-batch regression in the recaptures. Full VoiceOver remains untested. iPhone was returned to normal app launch with no preview flags, Reduce Motion restored to false, and the previously shut-down iPad returned to shutdown. The three protected storage keys were compared again after normal relaunch and remained unchanged.
