# Cool Spot iPhone Flow Prototype

## Question

Can someone discover a useful place to cool down in London, understand why it may help, privately save either a recognised place or their current coordinate, and later turn that saved location into reviewed public cooling information without confusing saving, visiting, and contributing?

## Flows to exercise

1. Browse reviewed Cool Spots on a map and in a compact result sheet.
2. Search for a recognised place that does not yet have cooling information.
3. Open a Cool Spot and distinguish GLA-sourced information from community information.
4. Save a recognised place without making a public claim about it.
5. Save the current coordinate immediately, without completing a form.
6. Open a Saved Location and add cooling information later.
7. Match a coordinate to a nearby recognised place or keep it as a specific unnamed location.
8. Submit a new place or place update for review and understand its status.
9. Publish a time-specific Visit Report immediately, with reactive reporting/moderation.
10. Create a ten-minute, proximity-checked “cooling off here” presence without retaining location history.
11. Understand private contribution history and the lightweight Cool Hunt collection.

## Prototype data and simulated behaviour

- Fixed example Cool Spots representing GLA and community sources.
- Fixed Apple Maps-style search candidates that are visually distinct from Cool Spots.
- Simulated current location, proximity checks, review outcomes, sign-in, and notifications.
- All state is in memory and resets when the app relaunches.

## Deliberately out of scope

- Real GLA import, Apple Maps search, directions, geocoding, or location permission prompts.
- Accounts, syncing, backend persistence, push notifications, admin tooling, or moderation services.
- Photo picker/upload and image moderation; the prototype only exercises photo placement and requirement messaging.
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
9. The You tab prioritises account state and current contribution outcomes; long history moves to a separate list.
10. Cool Hunt adds a small exploration goal rather than relying only on a static place-type grid.
11. All custom colour roles adapt to Light and Dark Mode, and selection is not communicated by colour alone.
