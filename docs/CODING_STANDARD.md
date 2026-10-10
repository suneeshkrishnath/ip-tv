# Coding Standards

Version: 1.0

---

# Language

Use:

```text
Dart 3
```

Flutter:

```text
Stable Channel
```

---

# General Principles

Code must be:

- Readable
- Testable
- Consistent
- Maintainable

Always prefer:

```text
Clarity over cleverness
```

---

# Naming Conventions

## Classes

```dart
ChannelRepository
PlayerScreen
PlaylistParser
```

Use:

```text
PascalCase
```

---

## Variables

```dart
channelName
playerController
selectedChannel
```

Use:

```text
camelCase
```

---

## Constants

```dart
const defaultPageSize = 20;
```

Use:

```text
camelCase
```

---

## Files

```text
channel_repository.dart

player_screen.dart

playlist_parser.dart
```

Use:

```text
snake_case
```

---

# Widgets

Keep widgets small.

Maximum:

```text
300 lines
```

If larger:

Extract widgets.

---

# State Management

Only use:

```text
Riverpod
```

Avoid:

```text
setState
```

Except:

- Dialogs
- Local UI-only interactions

---

# Models

Models must use:

```text
Freezed
```

Example:

```dart
@freezed
class Channel with _$Channel
```

Avoid manually creating immutable models.

---

# Repository Pattern

Every repository requires:

```text
Interface
Implementation
```

Example:

```text
ChannelRepository

ChannelRepositoryImpl
```

---

# Dependency Rules

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

# Error Handling

Do NOT:

```dart
catch (e) {}
```

Always:

```dart
catch (e, stackTrace)
```

Log meaningful details.

---

# Logging

Use:

```text
Logger
```

Avoid:

```dart
print()
```

in production code.

---

# Async Programming

Always prefer:

```dart
async
await
```

Avoid:

```dart
.then()
```

unless necessary.

---

# Comments

Write comments only when needed.

Bad:

```dart
// increment i
i++;
```

Good:

```dart
// Playlist format contains duplicate identifiers.
// Use URL hash to guarantee uniqueness.
```

---

# Documentation

Every public class must contain documentation.

Example:

```dart
/// Manages IPTV channel retrieval.
class ChannelRepository {}
```

---

# Testing Requirements

New features require:

- Unit tests
- Happy path test
- Error path test

Minimum coverage:

```text
80%
```

---

# Pull Request Rules

Every PR must:

- Compile successfully
- Pass tests
- Pass flutter analyze
- Include documentation updates if needed

No direct commit to:

```text
main
```
