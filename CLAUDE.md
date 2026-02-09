# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev          # Start dev mode with hot reload
npm run build        # Production build (electron-vite build)
npm run lint         # ESLint (flat config)
npm run lint:fix     # ESLint with auto-fix
npm run format       # Prettier format all source files
npm run format:check # Prettier check without writing
npm run pack         # Package as macOS .app directory
make install         # Build, package, copy to /Applications, add to Login Items
make uninstall       # Remove from /Applications and Login Items
```

After `npm install`, native modules (better-sqlite3) are rebuilt automatically via `electron-rebuild`.

No test framework is configured.

## Architecture

macOS tray-only time-tracking app. Prompts the user at a configurable interval (default 20 min) to log what they're working on.

**Three Electron processes:**
- **Main** (`src/main/`) — app lifecycle, tray, timer, database, IPC handlers
- **Preload** (`src/preload/index.ts`) — context bridge exposing `window.api` to renderer
- **Renderer** (`src/renderer/`) — React UI with three hash-routed views

**Window-per-route pattern:** Each window (popup, reports, settings) loads the same `index.html` with a different hash route (`#/popup`, `#/reports`, `#/settings`). Windows are lazy-created singletons managed in `src/main/windows.ts`.

**IPC pattern:** Renderer calls `window.api.methodName()` → preload bridges to `ipcRenderer.invoke(channel)` → main handles in `src/main/ipc-handlers.ts`. Main-to-renderer push uses `webContents.send()` (e.g., `popup:show`, `tracking:status-changed`).

**Database:** better-sqlite3 with raw SQL via `db.prepare()`. Schema auto-migrated on startup in `src/main/db/database.ts`. Three tables: `categories`, `entries`, `settings`. DB modules split by domain under `src/main/db/`.

**Timer flow:** `src/main/timer.ts` runs a `setInterval`. On tick, it opens the popup window and registers `Ctrl+1..9` global shortcuts for quick category selection. Day boundary detection resets the timer on new days.

## Key Conventions

- Shared TypeScript interfaces live in `shared/types.ts` (aliased as `@shared/types`)
- Inline CSS-in-JS styling, dark theme, no CSS framework
- Dev mode uses separate app name (`myti-dev`) and userData path so dev/prod coexist
- Popup window uses `type: 'panel'` (NSPanel) — required for keyboard focus in dock-hidden tray apps on macOS
