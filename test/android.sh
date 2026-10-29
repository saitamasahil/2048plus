#!/usr/bin/env bash
# test/android.sh: Launch Android edition in desktop Love2D with phone resolution
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$1" = "landscape" ] || [ "$1" = "land" ] || [ "$1" = "-l" ] || [ "$1" = "--landscape" ]; then
    WIDTH="${2:-844}"
    HEIGHT="${3:-390}"
elif [ "$1" = "portrait" ] || [ "$1" = "port" ] || [ "$1" = "-p" ] || [ "$1" = "--portrait" ]; then
    WIDTH="${2:-390}"
    HEIGHT="${3:-844}"
elif [ -n "$1" ] && [ -n "$2" ]; then
    WIDTH="$1"
    HEIGHT="$2"
else
    WIDTH="${1:-390}"
    HEIGHT="${2:-844}"
fi

TEMP_ROOT="${TMPDIR:-/tmp}"
[ ! -w "$TEMP_ROOT" ] && TEMP_ROOT="$PROJECT_ROOT/build/.tmp"
STAGE_DIR="$TEMP_ROOT/2048plus_android_pc_$$"
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
sed -i "s/t.window.resizable = .*/t.window.resizable = true/" "$STAGE_DIR/conf.lua"

if [ "$WIDTH" -gt "$HEIGHT" ] 2>/dev/null; then
    sed -i "s/t.window.orientation = .*/t.window.orientation = \"landscape\"/" "$STAGE_DIR/conf.lua"
fi

cat << 'EOF' >> "$STAGE_DIR/main.lua"

-- Test helper: F6 hotkey to toggle orientation on desktop
local orig_keypressed = love.keypressed
function love.keypressed(key, scancode, isrepeat)
    if key == "f6" then
        local cur_w, cur_h = love.graphics.getDimensions()
        love.window.setMode(cur_h, cur_w, {resizable = true})
        return
    end
    if orig_keypressed then orig_keypressed(key, scancode, isrepeat) end
end
EOF

echo "Starting 2048 Plus Android edition in window: ${WIDTH}x${HEIGHT}"
echo "Press F6 to toggle between portrait and landscape at any time"
echo "You can also drag window borders to resize freely"
echo "Use mouse to tap buttons or swipe tiles, or use keyboard arrows and enter"

love "$STAGE_DIR"
