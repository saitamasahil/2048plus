#!/usr/bin/env bash
# test/portmaster.sh: Launch PortMaster handheld build in desktop Love2D
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDTH="${1:-640}"
HEIGHT="${2:-480}"

STAGE_DIR="/tmp/2048plus_pm_test_$$"
mkdir -p "$STAGE_DIR"
trap 'rm -rf "$STAGE_DIR"' EXIT INT TERM

# Link runtime assets and scripts into staging
for entry in "$PROJECT_ROOT"/*; do
    base=$(basename "$entry")
    if [ "$base" != "conf.lua" ] && [ "$base" != "build" ] && [ "$base" != "test" ]; then
        ln -s "$entry" "$STAGE_DIR/$base"
    fi
done

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
