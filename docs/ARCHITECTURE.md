# Architecture Document

Version: 1.0

---

# Architecture Goals

The project must be:

- Maintainable
- Testable
- Modular
- Scalable
- Platform Independent

The architecture must support:

- Android
- iOS
- Future Android TV
- Future Apple TV

---

# Architectural Pattern

This application follows:

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

Dependency Direction:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Infrastructure
```

Never the opposite.

---

# Feature First Structure

Every feature owns its code.

```text
features/

    channels/
    player/
    favorites/
    playlists/
    epg/
    settings/
```

Each feature contains:

```text
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

---

# Layer Responsibilities

## Presentation Layer

Contains:

```text
Screens
Widgets
Providers
Controllers
```

Must NOT:

- Perform networking
- Access databases
- Parse responses

All business logic belongs elsewhere.

---

## Application Layer

Contains:

```text
Use Cases
Application Services
```

Examples:

```text
LoadChannelsUseCase

SearchChannelsUseCase

AddFavoriteUseCase
```

Responsibilities:

- Business workflows
- Coordination between repositories

---

## Domain Layer

Contains:

```text
Entities
Repository Contracts
Enums
Value Objects
```

Must:

- Have zero Flutter dependencies
- Have zero networking dependencies

---

## Infrastructure Layer

Contains:

```text
API Clients
Data Sources
Repositories
Parsers
Storage
```

Responsibilities:

- HTTP communication
- Playlist parsing
- Hive storage

---

# State Management

Official state management:

```text
Riverpod
```

Required packages:

```text
flutter_riverpod
riverpod_annotation
```

Avoid:

```text
Provider
GetX
MobX
```

---

# Navigation

Navigation package:

```text
GoRouter
```

Centralize routes inside:

```text
app/router.dart
```

No hardcoded routes.

---

# Networking

Networking package:

```text
Dio
```

All requests must pass through:

```text
core/network/
```

Direct HTTP calls are forbidden.

---

# Local Storage

Storage package:

```text
Hive
```

Store:

- Favorites
- Recent Channels
- Playlist Cache
- Settings

---

# Logging

Logging package:

```text
logger
```

Centralized logging only.

Location:

```text
core/logging/
```

---

# Error Handling

Create shared failure hierarchy.

Example:

```text
Failure

├── NetworkFailure
├── ParsingFailure
├── CacheFailure
├── UnknownFailure
```

Repository implementations must convert exceptions into failures.

---

# Dependency Injection

Use:

```text
Riverpod Providers
```

Avoid:

```text
GetIt
```

unless justified later.

---

# Testing Strategy

Every feature must contain:

```text
Unit Tests
Widget Tests
```

Critical services require:

```text
Integration Tests
```

---

# Performance Principles

Always:

- Lazy load lists
- Cache images
- Avoid rebuilding entire screens
- Use immutable state

---

# Future Extensions

Architecture must support:

- User Accounts
- Spring Boot Backend
- Chromecast
- AirPlay
- Android TV
- Apple TV

without major refactoring.
