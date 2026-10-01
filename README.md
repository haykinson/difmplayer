# DI.FM Player for macOS

A sleek, native macOS player for **[DI.FM](https://www.di.fm)** (Digitally Imported) and the AudioAddict radio network, inspired by the modern **Spotify** aesthetic. Built with Swift, SwiftUI, and AVFoundation.

![App Icon](AppIcon.icns)

---

## ✨ Features

- **🎧 Native High-Quality Streaming**:
  - Direct integration with AudioAddict streams via native `AVPlayer`.
  - Supports DI.FM Premium tiers: **320k MP3 (Ultra HQ)**, **256k MP3**, **128k AAC**, and **64k AAC**.
  - Fallback to public streams if listening without an account.
- **✨ Spotify-Inspired Interface**:
  - Dark modern aesthetic with responsive grid layout.
  - Real-time animated audio equalizer bars for the active stream.
  - Quick-play hover buttons and glowing active playing badges.
- **🔍 Station Browsing & Discovery**:
  - Browse over 90+ curated electronic stations on DI.FM.
  - Live search across station names, descriptions, and currently airing songs/artists.
  - Genre quick-filters: *Trance, House, Techno, Chillout, D&B, Ambient, Club, and Favorites*.
  - Switch between all AudioAddict networks: **DI.FM**, **RadioTunes**, **RockRadio**, **JazzRadio**, **Classical Radio**, and **Zen Radio**.
- **🎶 Live Now-Playing Metadata & Track History**:
  - Live automatic polling of currently playing tracks and high-resolution album artwork.
  - Station Details view showing recently played tracks, duration, release name, and community upvotes.
- **🎛️ Compact Floating Mini Player Mode**:
  - Switch anytime to a compact floating widget (toggle via button or `Cmd+Shift+M`).
  - Displays high-res cover art, stream name, currently playing song, **Pause**, **Skip** station, and restore window buttons.
  - Window level stays on top (`floating`) for effortless background listening while working.
- **⌨️ Native macOS System Controls**:
  - Integrated with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`.
  - macOS **Control Center** and Lock Screen widget show track artwork, song title, and station name.
  - Hardware **media keys** on keyboard (Play/Pause, Next/Previous) control station playback.
  - Full keyboard shortcuts:
    - `Space`: Play / Pause
    - `Cmd + Right Arrow`: Skip to Next Station
    - `Cmd + Left Arrow`: Previous Station
    - `Cmd + Shift + M`: Toggle Mini Player Mode

---

## 🔐 DI.FM Premium Authentication

DI.FM uses a unique **Listen Key** for external player streaming. The app supports two seamless ways to authenticate:

1. **Listen Key (Instant & Recommended)**:
   - Copy your Listen Key from your [DI.FM Player Settings](https://www.di.fm/settings).
   - Click **Log In** in the sidebar or bottom player bar, paste your key, and click **Save Listen Key**.
   - No password stored, instant access to 320k MP3 / 128k AAC streams.
2. **Account Login**:
   - Enter your DI.FM / AudioAddict email and password in the login modal.
   - The app securely retrieves your Listen Key via the AudioAddict API and stores it locally.

---

## 🛠️ Building & Running

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 14+ or Swift 5.9+

### Build the `.app` Bundle
Run the build script in the terminal:
```bash
./build_app.sh
```

This compiles a release binary, packages `build/DIFMPlayer.app` with icons and Info.plist, and signs it.

### Launch the App
```bash
open build/DIFMPlayer.app
```
You can also drag `build/DIFMPlayer.app` to your `/Applications` folder!

### Open in Xcode
To open and edit the project in Xcode:
```bash
open Package.swift
```

---

## 🏗️ Project Architecture

```
difmplayer/
├── Package.swift                    # Swift Package manifest
├── build_app.sh                     # Release build & app packager script
├── AppIcon.icns                     # High-res macOS icon bundle
├── Sources/DIFMPlayer/
│   ├── App.swift                    # Application entry point & menu shortcuts
│   ├── Models/
│   │   ├── Network.swift            # AudioAddict networks (DI.FM, RockRadio, etc.)
│   │   ├── Channel.swift            # Channel metadata & artwork URL resolution
│   │   ├── Track.swift              # Track history & now-playing models
│   │   └── AudioQuality.swift       # 320k, 256k, 128k quality tiers
│   ├── Services/
│   │   ├── AudioAddictAPI.swift     # REST client for channels, tracks & .pls parser
│   │   ├── PlayerManager.swift      # AVPlayer streaming engine & MPNowPlayingInfo
│   │   └── AuthManager.swift        # Credentials & Favorites persistence
│   ├── ViewModels/
│   │   └── AppViewModel.swift       # App state, search, filters & mini-mode toggle
│   └── Views/
│       ├── MainWindowView.swift     # Main window container (Full vs Mini Mode)
│       ├── SidebarView.swift        # Spotify-style dark sidebar & network picker
│       ├── StationGridView.swift    # Search bar, category chips, station card grid
│       ├── StationCardView.swift    # Station card with hover play button & badges
│       ├── StationDetailSheet.swift # Track history & station info modal
│       ├── BottomPlayerBar.swift    # Persistent bottom bar with controls & volume
│       ├── MiniPlayerView.swift     # Floating mini mode widget
│       ├── LoginSheet.swift         # Listen Key and Account login dialog
│       └── Components/
│           ├── AsyncImageView.swift # Memory-cached asynchronous image view
│           └── EqualizerView.swift  # Animated audio waveform bars
```

---

## 📜 Credits & Prior Art
Model inspired by the DI.FM API interaction patterns from Adriano Caloiaro's [di-tui](https://github.com/acaloiaro/di-tui).
