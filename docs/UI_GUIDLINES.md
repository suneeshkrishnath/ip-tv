# UI Guidelines

Version: 1.0

---

# Design Philosophy

The application should feel:

- Modern
- Fast
- Minimal
- Media Focused

Users should be able to start watching content within a few taps.

---

# Design System

Framework:

```text
Material 3
```

---

# Primary Colors

Primary:

```text
#1E88E5
```

Secondary:

```text
#03DAC6
```

Background:

```text
#121212
```

Surface:

```text
#1E1E1E
```

---

# Theme

Default:

```text
Dark Theme
```

Supported:

```text
Dark
Light
System
```

---

# Typography

Font:

```text
Roboto
```

Hierarchy:

```text
Headline

Title

Body

Caption
```

Use Material Design text styles.

---

# Corner Radius

Cards:

```text
12
```

Dialogs:

```text
16
```

Buttons:

```text
12
```

---

# Spacing Scale

Use:

```text
4
8
12
16
24
32
48
```

Avoid arbitrary spacing.

---

# Shared Components

Must create reusable widgets.

```text
AppSearchBar

ChannelCard

FavoriteButton

LoadingWidget

ErrorView

EmptyStateView
```

---

# Lists

Always use:

```dart
ListView.builder
```

for dynamic lists.

Avoid:

```dart
Column
```

with large datasets.

---

# Images

Package:

```text
cached_network_image
```

All channel logos should be cached.

---

# Loading States

Every screen requires:

```text
Loading
Success
Error
Empty
```

states.

---

# Channel Card

Display:

- Logo
- Name
- Category
- Favorite state

---

# Player Screen

Layout:

```text
Video

Channel Info

Controls

EPG Information
```

Prioritize video content.

---

# Accessibility

Support:

- Dynamic font scaling
- Screen readers
- High contrast

Minimum touch target:

```text
48 x 48
```

---

# Responsive Design

Support:

```text
Phones
Tablets
Landscape
Portrait
```

No fixed dimensions where avoidable.

---

# Animations

Use subtle animations only.

Examples:

```text
Fade

Slide

Scale
```

Duration:

```text
150ms - 300ms
```

Avoid excessive motion.
