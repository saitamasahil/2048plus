#!/usr/bin/env bash
# test/portmaster.sh: Launch PortMaster handheld build in desktop Love2D
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDTH="${1:-640}"
HEIGHT="${2:-480}"

STAGE_DIR="/tmp/2048plus_pm_test_$$"
mkdir -p "$STAGE_DIR"
trap 'rm -rf "$STAGE_DIR"' EXIT INT TERM

# Configure isolated test save directory inside test folder
SAVE_DIR="$PROJECT_ROOT/test/saves"
mkdir -p "$SAVE_DIR"
mkdir -p "$STAGE_DIR/xdg/love"
ln -s "$SAVE_DIR" "$STAGE_DIR/xdg/love/2048plus"
export XDG_DATA_HOME="$STAGE_DIR/xdg"

# Link runtime assets and scripts into staging
for entry in "$PROJECT_ROOT"/*; do
    base=$(basename "$entry")
    if [ "$base" != "conf.lua" ] && [ "$base" != "build" ] && [ "$base" != "test" ] && [ "$base" != "static" ]; then
        ln -s "$entry" "$STAGE_DIR/$base"
    fi
done
ln -s "$SAVE_DIR" "$STAGE_DIR/static"

# Copy base configuration and enable resizable window for desktop testing
cp "$PROJECT_ROOT/conf.lua" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.title = .*/t.window.title = \"2048 Plus - PortMaster Test\"/" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.width = .*/t.window.width = $WIDTH/" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.height = .*/t.window.height = $HEIGHT/" "$STAGE_DIR/conf.lua"
sed -i "s/t.window.resizable = .*/t.window.resizable = true/" "$STAGE_DIR/conf.lua"
sed -i "s/t.modules.mouse = .*/t.modules.mouse = true/" "$STAGE_DIR/conf.lua"

echo "Starting 2048 Plus PortMaster handheld build: ${WIDTH}x${HEIGHT}"
echo "Pass custom resolutions if testing other handheld displays, for example: ./portmaster.sh 720 720"

love "$STAGE_DIR" "$WIDTH" "$HEIGHT"
