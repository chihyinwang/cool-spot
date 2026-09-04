# Cool Spot visual-direction prototype

This is a throwaway Web prototype for comparing three iOS visual directions. It is not production UI and does not replace native interaction validation.

Run from the project root:

```sh
python3 -m http.server 4173 --directory design-prototype
```

Open one of the shareable variants:

- `http://localhost:4173/?variant=A`
- `http://localhost:4173/?variant=B`
- `http://localhost:4173/?variant=C`

Use the floating A/B/C switcher or the left and right arrow keys.

## Round 2: information hierarchy

Round 2 holds the palette, place photo, and data constant. It compares three structurally different detail hierarchies and includes an optional 30-second timer:

- `http://localhost:4173/round2.html?variant=A` — action first
- `http://localhost:4173/round2.html?variant=B` — evidence first
- `http://localhost:4173/round2.html?variant=C` — place first

## Round 3: scalable place detail

Round 3 fixes the visual direction and stress-tests one place with seven cooling features. It keeps visit-planning facts separate and progressively reveals the optional visitor report after live presence succeeds:

- `http://localhost:4173/round3.html`

## Presence disclosure comparison

This throwaway prototype compares the normal compact state, a one-time contextual tip, and the shared `How this works` bottom sheet:

- `http://localhost:4173/presence-disclosure.html?variant=A` — compact default
- `http://localhost:4173/presence-disclosure.html?variant=B` — first-time contextual tip
- `http://localhost:4173/presence-disclosure.html?variant=C` — bottom-sheet explanation
