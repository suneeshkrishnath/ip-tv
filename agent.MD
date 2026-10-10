# AGENTS.md

Version: 1.0

This file defines how AI coding assistants should operate within this repository.

Applicable To:

- GitHub Copilot
- Copilot Coding Agent
- Claude Code
- Cursor
- Roo Code
- OpenHands
- Any autonomous coding assistant

---

# Project Overview

Project Name:

IPTV Player

Description:

A production-grade Flutter IPTV application supporting Android and iOS.

Capabilities:

- Playlist Management
- IPTV Streaming
- Channel Search
- Favorites
- EPG Guide
- Offline Caching
- Multiple Playlists

Future Features:

- User Accounts
- Cloud Synchronization
- Chromecast
- AirPlay
- Android TV
- Apple TV

---

# Source Of Truth

Before implementing any feature, read the following documents in order:

1.

```text
docs/PRODUCT_REQUIREMENTS.md
```

2.

```text
docs/IMPLEMENTATION_PLAN.md
```

3.

```text
docs/ARCHITECTURE.md
```

4.

```text
docs/CODING_STANDARDS.md
```

5.

```text
docs/UI_GUIDELINES.md
```

6.

```text
docs/TASK_TRACKER.md
```

If there is a conflict:

```text
PRODUCT_REQUIREMENTS.md
takes precedence.
```

---

# Development Workflow

For every implementation task:

Step 1

Understand requirements.

Step 2

Identify affected feature.

Step 3

Follow architecture rules.

Step 4

Implement code.

Step 5

Create or update tests.

Step 6

Update documentation if required.

Step 7

Update TASK_TRACKER.md.

---

# Architecture Rules

This project follows:

```text
Clean Architecture
```

Layers:

```text
Presentation
    |
Application
    |
Domain
    |
Infrastructure
```

Always respect dependency direction.

Forbidden:

```text
Presentation -> Infrastructure
```

Allowed:

```text
Presentation -> Application

Application -> Domain

Infrastructure -> Domain
```

---

# Feature Structure

Each feature must follow:

```text
feature/

    data/

    domain/

    presentation/
```

Example:

```text
features/

    channels/

        data/

        domain/

        presentation/
```

Do not create alternative structures.

---

# State Management

Required:

```text
Riverpod
```

Packages:

```text
flutter_riverpod
riverpod_annotation
```

Avoid:

```text
Provider
GetX
MobX
Bloc
```

unless explicitly requested.

---

# Routing

Use:

```text
GoRouter
```

All routes must be centralized inside:

```text
lib/app/router.dart
```

Do not hardcode route strings throughout the application.

---

# Dependency Injection

Use:

```text
Riverpod Providers
```

Do not introduce:

```text
GetIt
Injectable
Service Locator patterns
```

unless approved.

---

# Networking

HTTP Client:

```text
Dio
```

Rules:

- No direct network calls from widgets.
- No direct networking inside screens.
- All requests pass through repositories.

Location:

```text
core/network/
```

---

# Storage

Use:

```text
Hive
```

Storage Targets:

- Favorites
- Recent Channels
- Playlist Cache
- Settings

---

# Models

All models must use:

```text
Freezed
```

and

```text
Json Serializable
```

Example:

```dart
@freezed
class Channel with _$Channel {
}
```

Do not write mutable DTOs.

---

# Error Handling

Never swallow exceptions.

Forbidden:

```dart
catch (e) {}
```

Required:

```dart
catch (e, stackTrace)
```

Convert exceptions into:

```text
Failure
```

objects.

Failure Types:

```text
NetworkFailure

ParsingFailure

CacheFailure

ValidationFailure

UnknownFailure
```

---

# Logging

Use:

```text
logger
```

Never use:

```dart
print()
```

for production code.

---

# UI Standards

Follow:

```text
docs/UI_GUIDELINES.md
```

Requirements:

- Material 3
- Responsive Layouts
- Reusable Components
- Dark Theme Support

---

# Shared Components

Prefer existing shared widgets.

Before creating a widget verify whether it already exists.

Common shared widgets:

```text
AppSearchBar

LoadingWidget

ErrorView

EmptyStateView

ChannelCard

FavoriteButton
```

---

# Testing Requirements

Every new feature must include tests.

Minimum:

```text
Unit Test
```

Required for:

```text
Repositories

Services

Parsers

Use Cases
```

Widget Tests:

```text
Screens
Reusable Widgets
```

Coverage Goal:

```text
80%
```

or greater.

---

# Performance Rules

Always:

- Use const constructors when possible.
- Avoid unnecessary rebuilds.
- Use immutable state.
- Cache remote images.
- Use lazy loading.

Never:

- Build large widget trees in a single file.
- Use Column for large dynamic lists.

Prefer:

```dart
ListView.builder
```

---

# File Naming

Use:

```text
snake_case.dart
```

Examples:

```text
playlist_repository.dart

player_screen.dart

channel_provider.dart
```

---

# Class Naming

Use:

```text
PascalCase
```

Examples:

```text
ChannelRepository

ChannelController

PlayerScreen
```

---

# Documentation Rules

Public APIs require documentation.

Example:

```dart
/// Loads channels from a playlist URL.
class LoadChannelsUseCase {}
```

---

# Task Tracking Rules

Whenever a stage is completed:

Update:

```text
docs/TASK_TRACKER.md
```

Change:

```text
[ ]
```

to

```text
[x]
```

for completed items.

Update status accordingly.

---

# Definition Of Done

A task is only complete when:

- Code Compiles
- flutter analyze Passes
- Tests Pass
- Documentation Updated
- Task Tracker Updated

---

# Forbidden Actions

Do NOT:

- Introduce new state management libraries.
- Skip architecture layers.
- Create networking logic inside widgets.
- Bypass repositories.
- Commit generated secrets.
- Commit API keys.
- Add packages without justification.
- Refactor unrelated code.

---

# Commit Message Convention

Use:

```text
feat: add channel search

fix: resolve playlist parsing issue

refactor: simplify player controller

test: add channel repository tests

docs: update implementation plan
```

---

# MVP Goal

The initial release is complete when the application can:

✅ Load M3U Playlists

✅ Parse IPTV Channels

✅ Display Channel List

✅ Search Channels

✅ Play Streams

✅ Save Favorites

✅ Run On Android

✅ Run On iOS

At this point the MVP is considered production-ready for internal testing.

---

# Agent Execution Priority

For every task:

1. Understand requirement
2. Follow architecture
3. Reuse existing code
4. Write tests
5. Update task tracker
6. Minimize complexity
7. Prefer maintainability

Primary objective:

```text
Generate production-quality Flutter code that adheres strictly to Clean Architecture and the project standards.
```
