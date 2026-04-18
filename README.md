# Offline-First Playlist Sync

Offline-first iOS playlist project focused on resilient sync behavior: local-first writes, durable operation logging, retry-safe reconciliation, and deterministic conflict handling.

## Tech Stack

- iOS / SwiftUI
- Swift concurrency (`async/await`, actors)
- Core Data (planned as local persistence layer)
- Mock-first sync adapter (backend integration deferred)
- XCTest (TDD)

## Current Status

- ✅ Day 1 scaffolding started with TDD
- ✅ Repository contract tests added
- ✅ Minimal in-memory repository implementation added
- ✅ App composition root + environment wiring added
- ⚠️ Simulator runtime instability observed locally (`launchd_sim` boot issue), so `build-for-testing` currently used as the green build gate

## Project Structure (Current)

```text
offline-first-playlist/
  offline-first-playlist/
    App/
      AppCompositionRoot.swift
      AppEnvironment.swift
    Domain/
      Models/
      Repositories/
    Data/
      Repositories/
  offline-first-playlistTests/
```

## Architecture Direction (Week 1)

- **Pattern:** MVVM + Repository
- **Data flow:** UI -> ViewModel -> Repository -> Local store
- **Offline behavior:** Full offline CRUD for playlists
- **Sync strategy:** Mock-first contracts now, real backend adapter later

## TDD Workflow

Each feature is delivered using strict red-green-refactor:

1. Write a failing test
2. Implement minimal code to pass
3. Refactor while preserving passing tests
4. Commit after successful validation

## Running the Project

### Build for testing (current reliable check)

```bash
xcodebuild build-for-testing \
  -project offline-first-playlist.xcodeproj \
  -scheme offline-first-playlist \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

### Run tests

```bash
xcodebuild test \
  -project offline-first-playlist.xcodeproj \
  -scheme offline-first-playlist \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

## Next Milestones (Week 1)

- Add Core Data model + stack (test-first)
- Replace in-memory repository with Core Data-backed local repository
- Add playlist list/editor view models and initial SwiftUI flows
- Add deterministic mock sync queue state transitions
