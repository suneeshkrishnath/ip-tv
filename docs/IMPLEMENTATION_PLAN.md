# Copilot Implementation Plan

Use this document as the concise execution guide. Follow the existing plan; do not add, reorder, or broaden work unless the user asks.

## Sources of Truth

- `PROJECT_PLAN.md`: product goals, MVP, version scope, and future features.
- `TASK_TRACKER.md`: implementation stage order, tasks, and completion status.
- `ARCHITECTURE.md`: feature structure, layer boundaries, and technical architecture.
- `CODING_STANDARD.md`: Dart conventions, packages, errors, and test expectations.
- `UI_GUIDLINES.md`: visual, responsive, accessibility, and UI-state requirements.

Use the filenames above exactly. Do not assume missing documents exist. If documents conflict, follow the user's latest direction; otherwise keep product scope from `PROJECT_PLAN.md`, stage order from `TASK_TRACKER.md`, and implementation rules from the relevant standards document. Ask before making a decision that materially changes scope or architecture.

## Copilot Rules

1. Read the relevant source documents and inspect the existing code before each task.
2. Identify the requested feature and its current `TASK_TRACKER.md` stage. Work only on the requested stage and its necessary dependencies.
3. Preserve Clean Architecture: presentation calls application/domain APIs, never infrastructure directly. Use Riverpod, GoRouter, Dio, Hive, Freezed, and the documented shared modules; do not introduce alternatives without approval.
4. Implement the smallest complete, testable change. Reuse existing code and widgets; avoid unrelated refactors and speculative future features.
5. Add or update tests for changed behavior. Cover success and failure paths; follow the documented unit/widget/integration split and 80% coverage goal.
6. Run relevant tests and `flutter analyze`. Update the tracker and docs only when the work is verified; never mark unfinished work complete.
7. Report what changed, checks run and their results, and any blocker or decision needed. Do not commit, publish, or submit releases unless asked.

## Stages

Complete stages in `TASK_TRACKER.md` order. Each stage is done only when its tasks are implemented, required tests pass, analysis is clean, and the tracker is accurately updated.

| Stage | Status | Copilot work | Completion check |
|---|---|---|---|
| 0 - Foundation | IN PROGRESS | Create/verify the Flutter project, packages, analysis rules, repository setup, CI, docs, and development environment. | Flutter environment is verified; project builds and CI runs analysis/tests. |
| 1 - Architecture Skeleton | COMPLETE | Establish feature-first folders, centralized GoRouter, Material 3 themes, Riverpod, logging, and the Dio network layer. | App launches with routing and shared foundations configured. |
| 2 - Domain Models | COMPLETE | Define immutable Channel, Playlist, Favorite, and Program models using Freezed/JSON serialization as appropriate. | Model unit tests cover expected values and serialization. |
| 3 - Playlist Engine | COMPLETE | Implement download and parsing for both initial M3U sources below, preserving each channel's stream URL; validate data and cache it through the repository. | Each source can be fetched and parsed into channels with usable stream URLs; malformed/network/cache failures are handled and tested. |
| 4 - Channel Browser | COMPLETE | Show channels and categories; add search, loading/error/empty states, and documented reusable UI. Selecting a channel opens the in-app player. | Browser, filtering, search, and states work; selecting a channel passes the correct channel to the player. |
| 5 - Video Player | IN PROGRESS | Integrate media_kit, in-app stream startup, playback controls, fullscreen/orientation behavior, and stream error handling. | A known reachable authorized stream plays inside the app on Android and iOS; loading, playback, and failure states are tested. |
| 6 - Favorites | COMPLETE | Persist add/remove operations in Hive and provide the favorites view. Selecting a favorite opens its stream in the in-app player. | Favorites survive restart; selecting one plays the matching channel in-app; repository/UI behavior is tested. |
| 7 - Recently Watched | IN PROGRESS | Record playback history and display the most recent 20 channels. | History ordering, limit, persistence, and view are verified. |
| 8 - Playlist Management | NOT STARTED | Add, edit, delete, and refresh user playlists. | Changes persist; refresh and failure cases are covered. |
| 9 - EPG Integration | NOT STARTED | Parse XMLTV data, associate programs with channels, and show current/next programs and schedules. | Time/channel matching and parser edge cases are tested. |
| 10 - Offline Support | NOT STARTED | Support cached startup and the planned channel, logo, and EPG caches. | Cached data is usable offline and cache failures are handled. |
| 11 - Settings | NOT STARTED | Implement theme selection, playlist refresh, cache clearing, and app information. | Settings persist where applicable and actions have clear success/error states. |
| 12 - Production Hardening | NOT STARTED | Complete performance and security review, required analytics/crash reporting, and release-candidate checks. | Build, tests, analysis, privacy/security review, and release-candidate checks pass. |
| 13 - Store Deployment | NOT STARTED | Prepare Android AAB and iOS IPA, testing tracks, and store submissions. | Deliverables are ready; submit or publish only with explicit user authorization. |

## Initial Playlist Sources

- Language-specific playlist: <https://iptv-org.github.io/iptv/languages/mal.m3u>
- Full playlist index: <https://iptv-org.github.io/iptv/index.m3u>

Use these as the initial remote M3U inputs for Stage 3. Fetch them through the documented Dio/network and repository layers; do not place network or parsing logic in widgets. Test successful parsing and network/invalid-playlist failures for both sources.

## Scope Boundaries

- The core MVP journey is: load a playlist, select a channel or favorite, and watch its live stream in the in-app player on Android or iOS. A visible channel list or external-player handoff does not satisfy playback.
- Validate playback with known reachable, authorized test streams on Android and iOS. Individual third-party streams may be unavailable or incompatible; report those failures clearly rather than treating an inaccessible stream as proof the player works.
- MVP also includes playlist loading, channel browsing/search, favorites, and Android/iOS builds as listed in `PROJECT_PLAN.md` and `TASK_TRACKER.md`.
- EPG, recently watched, offline enhancements, and other later-stage work must wait for their tracker stage or an explicit user request.
- Accounts, cloud sync/backend, Chromecast, AirPlay, Android TV, and Apple TV are future/optional scope. Do not build them speculatively.
- Consume only streams the user is authorized to access. Never bypass authentication, store premium streams, or re-host video streams.
