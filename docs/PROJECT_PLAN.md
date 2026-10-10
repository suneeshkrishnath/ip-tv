# IPTV Flutter App - Project Plan

## 1. Project Overview

Build a cross-platform IPTV application using Flutter that allows users to:

- Watch publicly available IPTV channels
- Browse channels by category
- Search channels
- Save favorites
- Display EPG (TV Guide)
- Continue watching previous channels
- Support Android and iOS
- Optional user authentication
- Optional cloud synchronization

Target Platforms:

- Android
- iPhone (iOS)
- Android TV (Future)
- Apple TV (Future)

---

# 2. Goals

## MVP (Version 1)

Users can:

- Load IPTV playlist
- Browse channels
- Search channels
- Play video streams
- Save favorites

## Version 2

Users can:

- View EPG schedule
- Continue watching
- Create account
- Sync favorites

## Version 3

Users can:

- Chromecast support
- AirPlay support
- Categories
- Recently watched

---

# 3. High Level Architecture

```text
+-----------------------+
|       Flutter App     |
+-----------------------+
            |
            |
            V
+-----------------------+
|     IPTV Service      |
|   Playlist Parser     |
+-----------------------+
            |
            |
            V
+-----------------------+
|      M3U Playlist     |
+-----------------------+
            |
            |
            V
+-----------------------+
|     Video Streams     |
+-----------------------+
```

Future:

```text
Flutter App
      |
      |
Spring Boot Backend
      |
      |
 DynamoDB
```

---

# 4. Technology Stack

## Mobile

- Flutter
- Dart

## Video

- media_kit
or

- better_player

Recommended:

- media_kit

Reason:
- Android
- iOS
- HLS support
- IPTV friendly

## State Management

Recommended:

- Riverpod

Alternatives:

- Bloc
- Provider

## Navigation

- go_router

## Local Storage

- Hive

## Network

- Dio

## Dependency Injection

- Riverpod

---

# 5. Project Structure

```text
lib/

├── app/
│   ├── app.dart
│   ├── routes.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   ├── utils/
│
├── features/
│
│   ├── channels/
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │
│   ├── player/
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │
│   ├── favorites/
│   │
│   ├── search/
│   │
│   ├── settings/
│   │
│   ├── epg/
│
├── shared/
│   ├── widgets/
│   ├── models/
│
└── main.dart
```

---

# 6. Screen Design

## Splash Screen

Responsibilities:

- Initialize app
- Load playlist cache
- Check connectivity

---

## Home Screen

Shows:

- Categories
- Trending channels
- Favorites

Sections:

```text
Favorites
News
Movies
Sports
Kids
Music
```

---

## Channel List Screen

Displays:

- Channel Logo
- Channel Name
- Group Name

Actions:

- Search
- Favorite

---

## Player Screen

Displays:

- Video Player
- Channel Name
- Current Programme
- Favorite Button

Controls:

- Fullscreen
- Play
- Pause
- Volume

---

## Favorites Screen

Shows:

- Favorite channels

---

## Settings Screen

Options:

- Dark Mode
- Refresh Playlist
- Clear Cache
- App Version

---

# 7. Data Models

## Channel

```dart
class Channel {
  String id;
  String name;
  String logo;
  String category;
  String streamUrl;
}
```

---

## Favorite

```dart
class Favorite {
  String channelId;
}
```

---

## EPG Program

```dart
class Program {
  String title;
  DateTime start;
  DateTime end;
}
```

---

# 8. Development Stages

---

## Stage 1

Project Setup

Duration:

1 Day

Tasks:

- Create Flutter project
- Configure folders
- Setup Riverpod
- Setup Theme

Deliverable:

Application launches

---

## Stage 2

Playlist Loader

Duration:

2 Days

Tasks:

- Download M3U file
- Parse channels
- Map to models

Deliverable:

Show channel list

---

## Stage 3

Video Playback

Duration:

2 Days

Tasks:

- Install media_kit
- Create player page
- Stream playback

Deliverable:

Channels play successfully

---

## Stage 4

Favorites

Duration:

1 Day

Tasks:

- Hive storage
- Add favorite
- Remove favorite

Deliverable:

Favorites persisted

---

## Stage 5

Search

Duration:

1 Day

Tasks:

- Channel search
- Filtering

Deliverable:

Instant search

---

## Stage 6

Caching

Duration:

1 Day

Tasks:

- Cache playlists
- Offline support

Deliverable:

Faster startup

---

## Stage 7

UI Polish

Duration:

2 Days

Tasks:

- Material 3
- Responsive layouts
- Dark theme

Deliverable:

Production-quality UI

---

# 9. Version 2 Features

## EPG

Tasks:

- Parse XMLTV
- Link channel to programs

Features:

- Current programme
- Next programme

---

## Continue Watching

Store:

```text
Channel
Timestamp
Duration
```

---

## Recently Watched

Store:

Last 20 channels

---

# 10. Backend Phase (Optional)

## Why Backend?

To support:

- Login
- User Profiles
- Sync Favorites

---

## Technology

Backend:

- Spring Boot

Database:

- DynamoDB

Hosting:

- AWS ECS
or
- EC2

---

## APIs

### Get Favorites

```http
GET /api/favorites
```

### Add Favorite

```http
POST /api/favorites
```

### Remove Favorite

```http
DELETE /api/favorites/{id}
```

---

# 11. Security

Never:

- Store premium streams
- Re-host video streams
- Bypass authentication

Only consume streams that users are authorized to access.

---

# 12. CI/CD

GitHub Actions

Pipeline:

```text
Build
 |
Test
 |
Analyze
 |
Release
```

Android:

- Play Store

iOS:

- App Store

---

# 13. Testing Strategy

Unit Tests

- Playlist parser
- Search

Widget Tests

- Channel screens
- Favorites

Integration Tests

- Video playback
- Playlist loading

Coverage Goal:

80%

---

# 14. Performance Targets

App Startup:

< 2 Seconds

Channel Open:

< 3 Seconds

Memory:

< 250 MB

Crash Free Rate:

99.5%

---

# 15. Future Roadmap

Version 3

- Chromecast
- AirPlay
- Android TV
- Apple TV
- Multiple playlists
- User accounts
- Cloud sync
- Downloadable EPG

Version 4

- AI-powered recommendations
- Voice Search
- Personalized categories

---

# Estimated Timeline

Stage 1-7 (MVP)

Approx:

10 - 14 Days

Version 2

Additional:

1 Week

Production Release

Approx:

3 Weeks Total
