# MeshCore SAR

Field-ready Search and Rescue app for teams using [MeshCore](https://github.com/meshcore-dev) over Bluetooth Low Energy.

MeshCore SAR helps teams coordinate in low-connectivity and no-connectivity environments.

## Highlights

- Mesh messaging for direct and group coordination
- On-demand voice and image sharing optimized for low bandwidth
- Offline-first maps with field overlays and tactical markers
- GPS tracking, trails, and shareable map drawings

## Feature Overview

| Area | What you get |
|---|---|
| Messaging | Direct and group chat over mesh, with contact/room awareness from live telemetry |
| Voice | Push-to-talk voice clips, fetched on demand when play is pressed, auto-play on completion |
| Images | Camera/gallery image sending, auto-compression, tap-to-load receiving, full-screen viewer |
| Maps | Street/topo/satellite/terrain layers, offline tile downloads, optional MBTiles import |
| SAR Operations | Team markers with freshness indicators, SAR markers for incidents and staging points |
| Tracking | Continuous GPS updates, personal trails, distance/duration trail stats |
| Trail Interop | GPX export/import for trail sharing and reuse |
| Tactical Drawing | Line/rectangle drawing, distance measurement, drawing sharing to channel/room |

## Voice, Image, and Maps

### Voice
- Designed for short, urgent field communication
- Playback requests are on-demand to reduce unnecessary mesh traffic
- Useful when typing is impractical during operations

### Images
- Built for constrained links with pre-send optimization
- Receiver controls when to fetch payload by tapping the placeholder
- Supports quick visual verification in the field

### Maps
- Supports online and offline workflows
- Adds SAR context with markers, overlays, and orientation tools
- Combines location, messaging, and tactical layers in one workflow

## Permissions (App Use)

- Bluetooth: mesh device communication
- Location: team tracking and map position updates
- Microphone: voice clip recording
- Camera / Photos: image messaging
