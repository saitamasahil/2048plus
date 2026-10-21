#!/usr/bin/env bash
# test/android.sh: Launch Android edition in desktop Love2D with portrait phone resolution
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDTH="${1:-390}"
HEIGHT="${2:-844}"

STAGE_DIR="/tmp/2048plus_android_pc_$$"
mkdir -p "$STAGE_DIR"
trap 'rm -rf "$STAGE_DIR"' EXIT INT TERM

# Configure isolated test save directory inside test folder
SAVE_DIR="$PROJECT_ROOT/test/saves"
mkdir -p "$SAVE_DIR"
mkdir -p "$STAGE_DIR/xdg/love"
ln -s "$SAVE_DIR" "$STAGE_DIR/xdg/love/2048plus"
export XDG_DATA_HOME="$STAGE_DIR/xdg"

# Link project files into staging directory
for entry in "$PROJECT_ROOT"/*; do
    base=$(basename "$entry")
    if [ "$base" != "conf.lua" ] && [ "$base" != "main.lua" ] && [ "$base" != "build" ] && [ "$base" != "test" ] && [ "$base" != "static" ]; then
        ln -s "$entry" "$STAGE_DIR/$base"
    fi
done
ln -s "$SAVE_DIR" "$STAGE_DIR/static"

# Copy base configuration and main for Android patching
cp "$PROJECT_ROOT/conf.lua" "$STAGE_DIR/conf.lua"
cp "$PROJECT_ROOT/main.lua" "$STAGE_DIR/main.lua"

# Apply Android patch
(cd "$STAGE_DIR" && patch -p1 < "$PROJECT_ROOT/android/android.patch" > /dev/null)

# Customize window bounds for desktop testing
sed -i "s/t.window.width = .*/t.window.width = $WIDTH/" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.height = .*/t.window.height = $HEIGHT/" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.fullscreen = .*/t.window.fullscreen = false/" "$STAGE_DIR/conf.lua"

echo "Starting 2048 Plus Android edition in phone window: ${WIDTH}x${HEIGHT}"
echo "Use mouse to tap buttons or swipe tiles, or use keyboard arrows and enter"

love "$STAGE_DIR"
