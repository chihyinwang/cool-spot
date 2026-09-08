# Cool Spot

Cool Spot is a native iOS prototype for finding places in London where people could cool down. It explores how a map can combine place information, visitor experiences and a short-lived indication that someone is cooling off there.

## Features

- Explore example places and read their cooling features and visitor reports.
- Save places or private map pins, with personal names and notes.
- Contribute cooling information through a review flow.
- Share a visit report or a temporary anonymous presence count.

## Prototype status

The app uses example London places, simulated search/proximity and review outcomes. It is not a live cooling-place directory. Accounts and moderation are demonstrations; there is no backend or cross-device sync.

MapKit displays real map tiles. Directions open an external Apple Maps walking link. Photo selection works locally, but photos are not uploaded. Saved items and visit reports can persist on the device; public place proposals currently last only for the running session.

## Run locally

1. Open `cool-spot.xcodeproj` in Xcode.
2. Select the `cool-spot` scheme and an iPhone or iPad simulator with iOS 18 or later.
3. Run the app.

The project uses SwiftUI, MapKit and PhotosUI. Unit tests are in the `cool_spotTests` target and can be run with Xcode's Test action.

See [PRODUCT.md](PRODUCT.md) for the product concepts and current prototype scope.
