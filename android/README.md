# 2048 Plus - Android Virtual Retro Console Edition

This folder contains all Android-specific assets, runtime console controller module, and build patch to run 2048 Plus in portrait orientation styled as a retro handheld console.

---

## Architecture

The main codebase remains 100% untouched and clean for muOS, handhelds, and desktop. All mobile adaptations are handled through a self-contained runtime wrapper and patch:

```
Phone Screen (Portrait)
+------------------------------------+
|                                    |
|   +----------------------------+   |  Virtual Display (Top 44%)
|   |                            |   |  - Native 640x480 resolution canvas
|   |      2048 PLUS GAME        |   |  - Screen bezel with real battery LED
|   |                            |   |  - Glossy lens highlight & rim
|   +----------------------------+   |
|            2048 PLUS               |  - Embossed retro branding
|     [ L ]                [ R ]     |  - Shoulder triggers (L1/Swap & R1/Bomb)
|                                    |
|      ▲                     ( X )   |  - Tactile Controls:
|   ◄  ┼  ►           ( Y )         ( A )  - D-Pad (directional pressed states)
|      ▼                     ( B )   |    - A (Confirm), B (Undo/Back)
|                                    |    - X (Quit/Menu), Y (Theme Cycle)
|         [SELECT]   [START]         |    - Select (Coins), Start (Pause)
+------------------------------------+
```

---

## Hybrid Touch & Gesture Control Scheme

- **In Gameplay (`GAME` state)**:
  - **Swipe Gestures**: Swipe anywhere on screen (virtual display or console body) to slide tiles up, down, left, or right.
  - **Direct Tile Targeting**: When using Swap or Bomb powerups, you can tap the target tile directly on the virtual screen.
  - **D-Pad Dimming**: The D-Pad dims to subtle opacity during gameplay to keep the screen elegant while remaining fully responsive if pressed.
  - **Tactile Shortcuts**: Tap `B` for Undo, `L` for Swap powerup, `R` for Bomb powerup.
- **In Menus & Overlays (Store, Jukebox, Settings, Play Select)**:
  - The D-Pad and Action buttons shine at full opacity.
  - Navigating carousel cards, playlists, and menus operates with tactile retro controller inputs.
- **Haptic Feedback**:
  - Microscopic vibration (`love.system.vibrate(0.015)`) on button taps, D-Pad presses, and swipe moves.

---

## Directory Contents

- `android_console.lua`: The virtual console controller and canvas viewport module.
- `android.patch`: Clean patch for `conf.lua`, `input.lua`, and `main.lua` to enable portrait mode and hook the virtual console.
- `assets/dpad/`: 8-way directional D-Pad cross sprites with pressed states (`cross.png`, `cross_u.png`, etc.).
- `assets/buttons/`: Round action buttons (`a`, `b`, `x`, `y`), shoulders (`l`, `r`), and pills (`select`, `start`).

---

## Building the Android Package

1. Apply `android.patch` and copy `android_console.lua` and `assets/` into a staged package.
2. Package the staged directory as `2048plus_android.love`.
3. Embed into the official `love-android` wrapper at `app/src/main/assets/game.love` and build with `./gradlew assembleRelease`.
