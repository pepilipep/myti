# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make dev             # Debug build, bundle .app, and open it
make build           # Release build (swift build -c release)
make run             # Release build, bundle .app, and open it
make clean           # swift package clean
make install         # Build, bundle, copy to /Applications, add to Login Items
make uninstall       # Remove from /Applications and Login Items
```

No test framework is configured.

## Architecture

macOS tray-only time-tracking app built with Swift and AppKit. Prompts the user at a configurable interval (default 20 min) to log what they're working on.

**Project structure:**
- `Sources/App/` — App entry point and AppDelegate
- `Sources/Database/` — GRDB database layer, migrations, queries
- `Sources/Models/` — Data models
- `Sources/Services/` — Timer, notifications, and other services
- `Sources/Theme/` — Colors and styling
- `Sources/Views/` — SwiftUI or AppKit views
- `Sources/Windows/` — Window management (popup, reports, settings)
- `Resources/` — Assets (tray icon images)

**Dependencies:** Swift Package Manager with GRDB.swift for SQLite database access.

**Build system:** SPM for compilation, Makefile for bundling into .app and installing to /Applications.

**Database:** GRDB.swift with SQLite. Schema managed via migrations in `Sources/Database/`.

## Key Conventions

- macOS 14+ (Sonoma) minimum deployment target
- Tray-only app (no dock icon)
- `Info.plist` at repo root configures the app bundle (LSUIElement=true for menu bar app)
