#!/usr/bin/env bash
# test/pc.sh: Launch PC edition with PC patch in desktop Love2D
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FULLSCREEN=false
WIDTH=960
HEIGHT=720

if [ "$1" = "--fullscreen" ] || [ "$1" = "-f" ]; then
    FULLSCREEN=true
elif [ -n "$1" ] && [ -n "$2" ]; then
    WIDTH="$1"
    HEIGHT="$2"
elif [ -n "$1" ]; then
    WIDTH="$1"
    HEIGHT="$1"
fi

TEMP_ROOT="${TMPDIR:-/tmp}"
[ ! -w "$TEMP_ROOT" ] && TEMP_ROOT="$PROJECT_ROOT/build/.tmp"
STAGE_DIR="$TEMP_ROOT/2048plus_pc_test_$$"
mkdir -p "$STAGE_DIR"
trap 'rm -rf "$STAGE_DIR"' EXIT INT TERM

# Configure isolated test save directory inside test folder
SAVE_DIR="$PROJECT_ROOT/test/saves"
mkdir -p "$SAVE_DIR"
mkdir -p "$STAGE_DIR/xdg/love"
ln -s "$SAVE_DIR" "$STAGE_DIR/xdg/love/2048plus"
export XDG_DATA_HOME="$STAGE_DIR/xdg"

# Link project assets and untouched modules into staging
for entry in "$PROJECT_ROOT"/*; do
    base=$(basename "$entry")
    if [ "$base" != "conf.lua" ] && [ "$base" != "globals.lua" ] && [ "$base" != "input.lua" ] && [ "$base" != "main.lua" ] && [ "$base" != "renderer.lua" ] && [ "$base" != "save.lua" ] && [ "$base" != "build" ] && [ "$base" != "test" ] && [ "$base" != "static" ]; then
        ln -s "$entry" "$STAGE_DIR/$base"
    fi
done
ln -s "$SAVE_DIR" "$STAGE_DIR/static"

# Copy files modified by PC patch
cp "$PROJECT_ROOT/conf.lua" "$STAGE_DIR/conf.lua"
cp "$PROJECT_ROOT/globals.lua" "$STAGE_DIR/globals.lua"
cp "$PROJECT_ROOT/input.lua" "$STAGE_DIR/input.lua"
cp "$PROJECT_ROOT/main.lua" "$STAGE_DIR/main.lua"
cp "$PROJECT_ROOT/renderer.lua" "$STAGE_DIR/renderer.lua"
cp "$PROJECT_ROOT/save.lua" "$STAGE_DIR/save.lua"

# Apply PC patch
(cd "$STAGE_DIR" && patch -p1 < "$PROJECT_ROOT/pc/pc.patch" > /dev/null)

# Configure window dimensions and fullscreen mode
if [ "$FULLSCREEN" = true ]; then
    sed -i "s/t.window.fullscreen = .*/t.window.fullscreen = true/" "$STAGE_DIR/conf.lua"
    echo "Starting 2048 Plus PC edition in fullscreen mode"
else
    sed -i "s/t.window.fullscreen = .*/t.window.fullscreen = false/" "$STAGE_DIR/conf.lua"
    sed -i "s/t.window.width = .*/t.window.width = $WIDTH/" "$STAGE_DIR/conf.lua"
    sed -i "s/t.window.height = .*/t.window.height = $HEIGHT/" "$STAGE_DIR/conf.lua"
    echo "Starting 2048 Plus PC edition in windowed mode: ${WIDTH}x${HEIGHT}"
fi

echo "Press F11 in game to toggle fullscreen at any time"

love "$STAGE_DIR"
