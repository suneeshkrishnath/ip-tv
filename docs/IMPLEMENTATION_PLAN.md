# IPTV Player - Implementation Plan

Version: 1.0

Author: Product & Engineering

Status: Planned

Target Platforms:

- Android
- iOS

Technology Stack:

- Flutter
- Dart
- Riverpod
- Go Router
- Dio
- Hive
- Media Kit
- Freezed
- Json Serializable

---

# 1. Vision

Build a modern IPTV application that allows users to:

- Load public IPTV playlists
- Manage custom playlists
- Watch live TV streams
- Search channels
- Organize favorites
- View EPG guide
- Continue watching channels
- Support Android and iOS from a single codebase

Future versions should support:

- Chromecast
- AirPlay
- User Accounts
- Cloud Synchronization
- Android TV
- Apple TV

---

# 2. Development Principles

## Clean Architecture

Every feature must follow:

```text
Presentation
    |
Application
    |
Domain
    |
Infrastructure
```

No UI layer should directly call network services.

---

## Feature First Structure

```text
features/
    channels/
    player/
    favorites/
    playlists/
    epg/
    settings/
```

Each feature owns:

```text
data/
domain/
presentation/
```

---

# 3. Repository Structure

```text
iptv-player/

docs/
    PROJECT_PLAN.md
    IMPLEMENTATION_PLAN.md

assets/
    images/
    icons/
    logos/

lib/

    app/

    core/

    shared/

    features/

test/

integration_test/

android/

ios/
```

---

# 4. Stage 0 - Foundation Setup

Goal:

Create a stable project foundation before development begins.

Estimated Duration:

1-2 Days

---

## Tasks

### Create Repository

```bash
git init
```

Branches:

```text
main
develop
```

Branch Naming:

```text
feature/*
bugfix/*
release/*
```

---

### Create Flutter Project

```bash
flutter create iptv_player
```

---

### Verify Environment

```bash
flutter doctor
```

All checks must pass.

---

### Configure Analysis Rules

Create:

```text
analysis_options.yaml
```

Enable:

- strict lints
- nullable safety checks

---

### Setup Project Packages

Add:

```yaml
flutter_riverpod
go_router
dio
hive
hive_flutter
freezed
freezed_annotation
json_annotation
json_serializable
build_runner
logger
media_kit
media_kit_video
media_kit_libs_video
cached_network_image
connectivity_plus
```

---

### Configure Git Ignore

Ignore:

```text
build/
.dart_tool/
.idea/
.vscode/
```

---

### Setup CI/CD Pipeline

GitHub Actions:

```yaml
flutter analyze
flutter test
```

Run for each Pull Request.

---

## Deliverables

- Repository created
- Flutter project generated
- Packages installed
- CI pipeline created

---

# 5. Stage 1 - Architecture Skeleton

Goal:

Create base architecture.

Estimated Duration:

1 Day

---

## Folder Structure

```text
lib/

app/
core/
shared/
features/
```

---

## Create Core Modules

```text
core/

config/
constants/
theme/
network/
storage/
exceptions/
utils/
```

---

## Create Shared Modules

```text
shared/

widgets/
models/
extensions/
```

---

## Setup Routing

Create:

```text
app/router.dart
```

Routes:

```text
/
home
player
favorites
settings
```

---

## Create Theme System

Themes:

```text
Light Theme
Dark Theme
```

Material 3 only.

---

## Deliverables

Running application with routing and theming configured.

---

# 6. Stage 2 - Domain Models

Goal:

Create reusable business entities.

Estimated Duration:

1 Day

---

## Channel Entity

```dart
class Channel
```

Properties:

```text
id
name
logo
group
country
language
streamUrl
```

---

## Playlist Entity

```dart
class Playlist
```

Properties:

```text
id
name
url
lastUpdated
```

---

## Favorite Entity

```dart
class Favorite
```

Properties:

```text
channelId
```

---

## Program Entity

```dart
class Program
```

Properties:

```text
title
description
startTime
