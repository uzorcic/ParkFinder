# 🅿 ParkFinder — iOS App

An iOS app that shows your **current location** on a map and **nearby parking spaces** in the neighborhood.

## Features

- 📍 Real-time GPS location with auto-centering
- 🅿 Parking spots from OpenStreetMap (no API key needed, free)
- 🗺 Color-coded annotations by parking type:
  - 🔵 **Blue** — Surface parking
  - 🟣 **Purple** — Underground
  - 🟠 **Orange** — Multi-storey
  - 🟢 **Green** — Street side
  - ⬜ **Gray** — Unknown/general
- 💬 Tap any annotation to see details (name, capacity, fee, access)
- 📋 List view sorted by distance with search
- 🔄 Manual refresh button
- ↩ Re-center button to snap back to your location

## Requirements

- Xcode 15+
- iOS 16+ deployment target
- iPhone or Simulator (location works best on a real device)

## Setup

### 1. Create the Xcode project

1. Open Xcode → **Create a new Xcode project**
2. Choose **iOS → App**
3. Set:
   - **Product Name:** `ParkingApp`
   - **Bundle Identifier:** `com.yourname.ParkingApp` (change to your own)
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Choose a location and click **Create**

### 2. Add the source files

Replace the auto-generated files and add these from this folder:

```
ParkingApp/
├── ParkingAppApp.swift         ← entry point (replace existing)
├── ContentView.swift           ← main map view (replace existing)
├── LocationManager.swift       ← GPS tracking
├── ParkingManager.swift        ← Overpass API fetching
├── ParkingAnnotationView.swift ← map pin UI
├── ParkingListView.swift       ← list sheet
├── Models/
│   └── ParkingSpot.swift       ← data models
└── Info.plist                  ← merge privacy keys into yours
```

> **Info.plist:** In Xcode 14+, Info.plist is managed via project settings.
> Add these two keys manually:
> - **Privacy – Location When In Use Usage Description**
> - **Privacy – Location Always and When In Use Usage Description**

### 3. Build & Run

- Select your **iPhone** or the **iOS Simulator**
- Press **⌘R** to build and run
- Accept the location permission prompt
- The map zooms to your location and loads parking spots!

## How It Works

1. `LocationManager` uses `CoreLocation` to get GPS fix
2. On location update, `ParkingManager` fires an **Overpass API** query:
   ```
   node/way/relation["amenity"="parking"](around:1000m)
   ```
3. Results are decoded into `ParkingSpot` objects and shown as map annotations
4. Tapping an annotation shows a callout with parking details

## Customization

| What | Where | How |
|------|-------|-----|
| Search radius | `ParkingManager.swift` | Change `searchRadius` (default: 1000m) |
| Re-fetch threshold | `ParkingManager.swift` | Change `minimumDistanceForRefetch` (default: 300m) |
| Default map center | `ContentView.swift` | Change the default `region` coordinates |
| Overpass server | `ParkingManager.swift` | Change `overpassURL` to a closer mirror |

### Overpass API Mirrors (if default is slow)
- `https://overpass.kumi.systems/api/interpreter`
- `https://maps.mail.ru/osm/tools/overpass/api/interpreter`

## Limitations

- Parking data depends on **OpenStreetMap** coverage — better in cities, sparse in rural areas
- No real-time occupancy (OSM doesn't track that)
- App requires internet connection to fetch parking data
- Simulator shows a fixed location (Apple HQ) — use a real device for best results

## License

MIT — use it, fork it, build on it.
