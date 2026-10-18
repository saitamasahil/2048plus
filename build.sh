#!/bin/bash
# ==============================================================================
# 2048 Plus - Unified Build Script
# ==============================================================================
# Usage:
# ./build.sh            Interactive build menu
# ./build.sh muos       Build muOS package
# ./build.sh portmaster Build PortMaster package
# ./build.sh linux      Build Linux AppImage
# ./build.sh windows    Build Windows package
# ./build.sh all        Build all packages
# ==============================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
CACHE_DIR="$BUILD_DIR/.cache"
PM_SOURCE_DIR="$PROJECT_ROOT/portmaster"
PC_SOURCE_DIR="$PROJECT_ROOT/pc"

# Read version from globals.lua
MAJOR=$(grep -oP 'major = \K\d+' "$PROJECT_ROOT/globals.lua")
MINOR=$(grep -oP 'minor = \K\d+' "$PROJECT_ROOT/globals.lua")
PATCH=$(grep -oP 'patch = \K\d+' "$PROJECT_ROOT/globals.lua")

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
    echo "Error: Could not determine version from globals.lua"
    exit 1
fi

TAG="v${MAJOR}.${MINOR}.${PATCH}"
mkdir -p "$BUILD_DIR" "$CACHE_DIR"

# Helper function to download files to cache
download_cached() {
    local url="$1"
    local output="$CACHE_DIR/$2"
    if [ ! -f "$output" ]; then
        echo "Downloading $2..."
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$output" "$url"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$output" "$url"
        else
            echo "Error: Neither curl nor wget is installed."
            exit 1
        fi
    fi
    chmod +x "$output" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Helper: Prepare Staged PC .love Package
# ------------------------------------------------------------------------------
prepare_pc_love() {
    LOVE_FILE="$BUILD_DIR/2048plus.love"
    if [ -f "$LOVE_FILE" ]; then
        return 0
    fi

    echo "Staging PC build..."
    TMP_STAGE="/tmp/pc_stage_$$"
    rm -rf "$TMP_STAGE"
    mkdir -p "$TMP_STAGE"

    # Stage runtime assets and scripts from project root
    rsync -av \
      --exclude=".git*" \
      --exclude="*.sh" \
      --exclude="*.md" \
      --exclude="build*" \
      --exclude="bin" \
      --exclude="portmaster" \
      --exclude="pc" \
      --exclude="mux_*" \
      "$PROJECT_ROOT/" "$TMP_STAGE/" > /dev/null

    # Apply PC patch cleanly to staged copy without touching source repository
    if [ -f "$PC_SOURCE_DIR/pc.patch" ]; then
        echo "Applying PC patch to staged build..."
        (cd "$TMP_STAGE" && patch -p1 < "$PC_SOURCE_DIR/pc.patch" > /dev/null)
    fi

    (
        [ -f "$PROJECT_ROOT/LICENSE" ] && cp "$PROJECT_ROOT/LICENSE" "$TMP_STAGE/"
        cd "$TMP_STAGE"
        zip -9 -q -r "$LOVE_FILE" .
    )
    rm -rf "$TMP_STAGE"
    echo "[OK] 2048plus.love created ($(du -h "$LOVE_FILE" | cut -f1))"
}

# ------------------------------------------------------------------------------
# Function: Build muOS Package
# ------------------------------------------------------------------------------
build_muos() {
    echo ""
    echo "Building muOS Package..."
    
    APP_NAME="2048 Plus"
    OUTPUT="$BUILD_DIR/${APP_NAME}_${TAG}.muxapp"
    WORKDIR="$BUILD_DIR/pkg_${MAJOR}${MINOR}${PATCH}"

    rm -rf "$WORKDIR" "$OUTPUT"
    mkdir -p "$WORKDIR/$APP_NAME/.game"

    # Copy launcher script and language file
    cp "$PROJECT_ROOT/mux_launch.sh" "$WORKDIR/$APP_NAME/"
    [ -f "$PROJECT_ROOT/mux_lang.ini" ] && cp "$PROJECT_ROOT/mux_lang.ini" "$WORKDIR/$APP_NAME/"

    # Copy all Lua source files
    cp "$PROJECT_ROOT/"*.lua "$WORKDIR/$APP_NAME/.game/"

    # Copy licenses
    cp -r "$PROJECT_ROOT/licenses" "$WORKDIR/$APP_NAME/.game/"

    # Copy all assets
    cp -r "$PROJECT_ROOT/assets" "$WORKDIR/$APP_NAME/.game/"

    # Copy helper scripts
    cp -r "$PROJECT_ROOT/scripts" "$WORKDIR/$APP_NAME/.game/"

    # Copy LÖVE binary and libs
    cp -r "$PROJECT_ROOT/bin" "$WORKDIR/$APP_NAME/.game/"
    mkdir -p "$WORKDIR/$APP_NAME/.game/static"

    # Copy glyph for muOS menu icon
    mkdir -p "$WORKDIR/$APP_NAME/glyph"
    if [ -f "$PROJECT_ROOT/assets/logo/logo_2048.svg" ]; then
        cp "$PROJECT_ROOT/assets/logo/logo_2048.svg" "$WORKDIR/$APP_NAME/glyph/"
    elif [ -f "$PROJECT_ROOT/assets/glyph/logo_2048.svg" ]; then
        cp "$PROJECT_ROOT/assets/glyph/logo_2048.svg" "$WORKDIR/$APP_NAME/glyph/"
    fi

    # Create the .muxapp package
    (cd "$WORKDIR" && zip -qr "package.muxapp" ./"$APP_NAME" && mv "package.muxapp" "$OUTPUT")
    rm -rf "$WORKDIR"

    MUX_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "[OK] muOS package created: build/${APP_NAME}_${TAG}.muxapp ($MUX_SIZE)"
}

# ------------------------------------------------------------------------------
# Function: Build PortMaster Package
# ------------------------------------------------------------------------------
build_portmaster() {
    echo ""
    echo "Building PortMaster Package..."

    TMP_STAGE="/tmp/pm_stage_$$"
    mkdir -p "$TMP_STAGE/gamedata"

    # Stage runtime assets and scripts
    rsync -av \
      --exclude="music" \
      --exclude=".git*" \
      --exclude="*.sh" \
      --exclude="*.md" \
      --exclude="build*" \
      --exclude="bin" \
      --exclude="banner.png" \
      --exclude="licenses" \
      --exclude="portmaster" \
      --exclude="pc" \
      --exclude="mux_*" \
      "$PROJECT_ROOT/" "$TMP_STAGE/gamedata/" > /dev/null

    tar -czf "$TMP_STAGE/gamedata.tar.gz" -C "$TMP_STAGE" gamedata
    rm -rf "$TMP_STAGE/gamedata"

    TAR_SIZE=$(du -h "$TMP_STAGE/gamedata.tar.gz" | cut -f1)
    echo "[OK] gamedata.tar.gz created ($TAR_SIZE)"

    # Build standalone PortMaster release zip
    ZIP_STAGE="/tmp/pm_zip_$$"
    mkdir -p "$ZIP_STAGE/2048plus/gamedata/assets/music"
    mkdir -p "$ZIP_STAGE/2048plus/licenses"

    if [ -f "$PM_SOURCE_DIR/2048 Plus.sh" ]; then
        cp "$PM_SOURCE_DIR/2048 Plus.sh" "$ZIP_STAGE/"
    fi

    [ -f "$PM_SOURCE_DIR/README.md" ] && cp "$PM_SOURCE_DIR/README.md" "$ZIP_STAGE/2048plus/2048plus.md"
    [ -f "$PM_SOURCE_DIR/gameinfo.xml" ] && cp "$PM_SOURCE_DIR/gameinfo.xml" "$ZIP_STAGE/2048plus/"
    [ -f "$PM_SOURCE_DIR/port.json" ] && cp "$PM_SOURCE_DIR/port.json" "$ZIP_STAGE/2048plus/"
    [ -f "$PM_SOURCE_DIR/screenshot.png" ] && cp "$PM_SOURCE_DIR/screenshot.png" "$ZIP_STAGE/2048plus/"

    cp "$TMP_STAGE/gamedata.tar.gz" "$ZIP_STAGE/2048plus/"
    cp "$PROJECT_ROOT/assets/music/"*.mp3 "$ZIP_STAGE/2048plus/gamedata/assets/music/"
    cp -r "$PROJECT_ROOT/licenses/"* "$ZIP_STAGE/2048plus/licenses/"

    RELEASE_ZIP="$BUILD_DIR/2048plus.zip"
    rm -f "$RELEASE_ZIP" "$BUILD_DIR/gamedata.tar.gz"
    (cd "$ZIP_STAGE" && zip -r -q "2048plus.zip" "2048 Plus.sh" "2048plus" && mv "2048plus.zip" "$RELEASE_ZIP")
    rm -rf "$ZIP_STAGE" "$TMP_STAGE"

    ZIP_SIZE=$(du -h "$RELEASE_ZIP" | cut -f1)
    echo "[OK] PortMaster package created: build/2048plus.zip ($ZIP_SIZE)"
}

# ------------------------------------------------------------------------------
# Function: Build Linux AppImage
# ------------------------------------------------------------------------------
build_linux() {
    echo ""
    echo "Building Linux AppImage..."

    prepare_pc_love

    WORKSPACE_DIR="/tmp/linux_workspace_$$"
    rm -rf "$WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"

    download_cached "https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage" "love-x86_64.AppImage"
    download_cached "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" "appimagetool-x86_64.AppImage"

    (
        cd "$WORKSPACE_DIR"
        cp "$CACHE_DIR/love-x86_64.AppImage" .
        cp "$CACHE_DIR/appimagetool-x86_64.AppImage" .
        export APPIMAGE_EXTRACT_AND_RUN=1
        ./love-x86_64.AppImage --appimage-extract >/dev/null

        # Fuse Linux binary
        cat squashfs-root/bin/love "$LOVE_FILE" > squashfs-root/bin/love-fused
        mv squashfs-root/bin/love-fused squashfs-root/bin/love
        chmod +x squashfs-root/bin/love

        # Desktop entry and metadata
        [ -f "$PC_SOURCE_DIR/2048plus.desktop" ] && cp "$PC_SOURCE_DIR/2048plus.desktop" squashfs-root/love.desktop
        [ -f "$PC_SOURCE_DIR/2048plus.desktop" ] && cp "$PC_SOURCE_DIR/2048plus.desktop" squashfs-root/share/applications/love.desktop
        [ -f "$PROJECT_ROOT/LICENSE" ] && cp "$PROJECT_ROOT/LICENSE" squashfs-root/LICENSE
        [ -f "$PROJECT_ROOT/licenses/ClearSans.LICENSE" ] && cp "$PROJECT_ROOT/licenses/ClearSans.LICENSE" squashfs-root/ClearSans_LICENSE.txt

        local icon_src="$PROJECT_ROOT/assets/logo/logo_2048.png"
        if [ -f "$icon_src" ]; then
            cp "$icon_src" squashfs-root/love.png
            mkdir -p squashfs-root/share/pixmaps
            cp "$icon_src" squashfs-root/share/pixmaps/love.png
            cp "$icon_src" squashfs-root/.DirIcon
            rm -f squashfs-root/love.svg squashfs-root/share/pixmaps/love.svg
        fi

        OUTPUT_APPIMAGE="$BUILD_DIR/2048_Plus-x86_64.AppImage"
        ARCH=x86_64 ./appimagetool-x86_64.AppImage squashfs-root "$OUTPUT_APPIMAGE" >/dev/null
        echo "[OK] Linux AppImage created: build/2048_Plus-x86_64.AppImage ($(du -h "$OUTPUT_APPIMAGE" | cut -f1))"
    )

    rm -rf "$WORKSPACE_DIR"
}

# ------------------------------------------------------------------------------
# Function: Build Windows 64-bit Package
# ------------------------------------------------------------------------------
build_windows() {
    echo ""
    echo "Building Windows 64-bit Package..."

    prepare_pc_love

    WORKSPACE_DIR="/tmp/win_workspace_$$"
    rm -rf "$WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"

    download_cached "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip" "love-11.5-win64.zip"

    (
        cd "$WORKSPACE_DIR"
        unzip -q "$CACHE_DIR/love-11.5-win64.zip" -d win_extract
        WIN_DIST_DIR="$WORKSPACE_DIR/2048_Plus-win64"
        mkdir -p "$WIN_DIST_DIR"

        # Fuse Windows binary
        cat win_extract/love-11.5-win64/love.exe "$LOVE_FILE" > "$WIN_DIST_DIR/2048 Plus.exe"

        # Patch Windows icon if Wine & Pillow available
        local icon_src="$PROJECT_ROOT/assets/logo/logo_2048.png"
        if command -v wine >/dev/null 2>&1; then
            download_cached "https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe" "rcedit-x64.exe"
            if python3 -c "from PIL import Image" >/dev/null 2>&1 && [ -f "$icon_src" ]; then
                python3 -c "from PIL import Image; img = Image.open('$icon_src'); img.save('$WORKSPACE_DIR/logo_2048.ico', format='ICO', sizes=[(256,256), (128,128), (64,64), (48,48), (32,32), (16,16)])"
                wine "$CACHE_DIR/rcedit-x64.exe" "$WIN_DIST_DIR/2048 Plus.exe" --set-icon "$WORKSPACE_DIR/logo_2048.ico" >/dev/null 2>&1 || true
            fi
        fi

        cp win_extract/love-11.5-win64/*.dll "$WIN_DIST_DIR/"
        cp win_extract/love-11.5-win64/license.txt "$WIN_DIST_DIR/love_license.txt"
        [ -f "$PROJECT_ROOT/LICENSE" ] && cp "$PROJECT_ROOT/LICENSE" "$WIN_DIST_DIR/LICENSE"
        [ -f "$PROJECT_ROOT/licenses/ClearSans.LICENSE" ] && cp "$PROJECT_ROOT/licenses/ClearSans.LICENSE" "$WIN_DIST_DIR/ClearSans_LICENSE.txt"

        OUTPUT_WIN_ZIP="$BUILD_DIR/2048_Plus-win64.zip"
        (cd "$WORKSPACE_DIR" && zip -9 -q -r "$OUTPUT_WIN_ZIP" "2048_Plus-win64")
        echo "[OK] Windows package created: build/2048_Plus-win64.zip ($(du -h "$OUTPUT_WIN_ZIP" | cut -f1))"
    )

    rm -rf "$WORKSPACE_DIR"
}

# ------------------------------------------------------------------------------
# Interactive Menu / Argument Parsing
# ------------------------------------------------------------------------------
echo "2048 Plus $TAG"

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Select build target:"
    echo "  1) muOS Package"
    echo "  2) PortMaster Package"
    echo "  3) Linux AppImage"
    echo "  4) Windows Package"
    echo "  5) All"
    echo ""
    read -r -p "Enter choice [1/2/3/4/5] (Press Enter for All): " CHOICE
    case "$CHOICE" in
        1|muos|MUOS)
            TARGET="muos"
            ;;
        2|portmaster|pm|PM|PortMaster)
            TARGET="portmaster"
            ;;
        3|linux|Linux|LINUX|appimage|AppImage)
            TARGET="linux"
            ;;
        4|windows|win|win64|Windows|WINDOWS)
            TARGET="windows"
            ;;
        5|all|ALL|both|BOTH|"")
            TARGET="all"
            ;;
        *)
            echo "Invalid choice '$CHOICE'. Defaulting to All."
            TARGET="all"
            ;;
    esac
fi

case "$TARGET" in
    1|muos|MUOS)
        build_muos
        ;;
    2|portmaster|pm|PM|PortMaster)
        build_portmaster
        ;;
    3|linux|Linux|LINUX|appimage|AppImage)
        build_linux
        rm -f "$BUILD_DIR/2048plus.love"
        ;;
    4|windows|win|win64|Windows|WINDOWS)
        build_windows
        rm -f "$BUILD_DIR/2048plus.love"
        ;;
    5|all|ALL|both|BOTH)
        build_muos
        build_portmaster
        build_linux
        build_windows
        rm -f "$BUILD_DIR/2048plus.love"
        ;;
    *)
        echo "Unknown target '$TARGET'. Valid options: muos, portmaster, linux, windows, all"
        exit 1
        ;;
esac

echo ""
echo "Build Completed Successfully!"
ls -lh "$BUILD_DIR"
