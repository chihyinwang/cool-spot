[![Cool Spot app icon: a person sitting in shade beside sunlight.](https://github.com/user-attachments/assets/0bcf60f3-ff72-476b-b5d8-a5b2cb6ac318)](https://github.com/user-attachments/assets/fee31127-3365-4584-860a-3701fa45d53d)

# Cool Spot

**Find a place to cool down in London.**

Cool Spot is a native iOS prototype for finding places to cool down in London. It integrates the Greater London Authority's (GLA) [2025 Cool Spaces data](https://data.london.gov.uk/dataset/cool-space-data-2025-2z19p) with Apple Maps search, so people can check cooling and access information before they go.

| Explore | Place detail · Example photos | Report · Quick entry |
| :---: | :---: | :---: |
| [![Explore a London map with cooling filters and a place preview.](https://github.com/user-attachments/assets/f9e21ae6-059c-49a9-ae3c-cda93694e8d2)](https://github.com/user-attachments/assets/8e3261d8-692a-41ec-b979-82b4b8ae8daf) | [![Example Community Room detail showing illustrative photos, facilities and additional place information.](https://github.com/user-attachments/assets/932c31db-665e-4a88-bb2b-44497442878f)](https://github.com/user-attachments/assets/ea52e133-c560-42c1-962b-dafb0ce51d8f) | [![Example Community Room detail with seating information and three direct visit-experience choices.](https://github.com/user-attachments/assets/d96ca2cf-ee54-4daf-a6a5-6f0df4ed028b)](https://github.com/user-attachments/assets/87c89e7e-300c-4b25-bef1-38c30fa56c1a) |

## Features

- **Find a cooling place.** Browse the map or place list; filter for indoor spaces, outdoor shade, air conditioning, free entry or water. Search places with Apple Maps.
- **See where people are cooling off.** View recent anonymous shares on the map and use **I’m cooling off here** to share for 10 minutes. Presence and proximity are simulated in this prototype.
- **Check the details.** See cooling features, cost, access restrictions and available photos, then open directions.
- **Save places for later.** Keep places and private notes in **Saved**.
- **Report a visit.** For an eligible visit, choose **Not cooler**, **A little cooler** or **Much cooler**. Add optional details or use **Finish later** to keep a private draft.
- **Add or update a place.** Register cooling information or use **Suggest an edit**. **Your changes** shows added and removed cooling features.
- **Find your activity.** Return to drafts, completed visit reports and place proposal records in **You**.

Reports and place proposals are saved on the device in this prototype.

| Suggest an edit | How this works · Simulated example |
| :---: | :---: |
| [![Suggest an edit showing a note field and an Add Fans / Remove Air conditioning change summary.](https://github.com/user-attachments/assets/49adadc7-cbc5-41ce-b767-b3a827c30331)](https://github.com/user-attachments/assets/335c2f07-7a59-44ab-a568-b228150f61a9) | [![The app’s How this works screen: anonymous ten-minute sharing and an example map count increasing from two to three.](https://github.com/user-attachments/assets/8b7590d2-42c8-4636-b5aa-103f92c6e339)](https://github.com/user-attachments/assets/af200391-cf8d-4e77-a786-d6d4e2d0ffe9) |

## Engineering

```mermaid
flowchart LR
    DB["PostgreSQL"] --> API["TypeScript API"] --> App["Swift / SwiftUI · iOS"]
```

Shared SwiftUI components define spacing, fact rows and button styles. The same cooling-feature selector serves Report, Register and Suggest an edit.

