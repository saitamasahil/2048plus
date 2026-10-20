#!/usr/bin/env python3
import os
import sys
import shutil
import subprocess
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_DIR = os.path.join(PROJECT_ROOT, "build")
LOVE_PATH = os.environ.get("LOVE_PATH") or os.path.join(BUILD_DIR, "2048plus_android.love")
APK_OUT = os.path.join(BUILD_DIR, "2048plus.apk")
CACHE_DIR = os.path.expanduser("~/.cache/love_android")
BASE_APK = os.path.join(CACHE_DIR, "love-embed.apk")
# Keystore configuration for signing updates
KEYSTORE = os.environ.get("KEYSTORE_PATH") or os.environ.get("KEYSTORE")
if not KEYSTORE:
    project_release = os.path.join(PROJECT_ROOT, "android/release.keystore")
    project_debug = os.path.join(PROJECT_ROOT, "android/debug.keystore")
    cache_debug = os.path.join(CACHE_DIR, "debug.keystore")
    if os.path.isfile(project_release):
        KEYSTORE = project_release
    elif os.path.isfile(project_debug):
        KEYSTORE = project_debug
    else:
        KEYSTORE = cache_debug

KEY_ALIAS = os.environ.get("KEY_ALIAS", "androiddebugkey" if "debug" in os.path.basename(KEYSTORE) else "release")
KS_PASS = os.environ.get("KEYSTORE_PASS") or os.environ.get("KS_PASS") or ("android" if "debug" in os.path.basename(KEYSTORE) else "")
KEY_PASS = os.environ.get("KEY_PASS", KS_PASS)
ICON_SRC = os.path.join(PROJECT_ROOT, "assets/logo/logo_2048.png")
PACKAGE_NAME = os.environ.get("PACKAGE_NAME", "com.saitamasahil.plus2048")

# Read version dynamically from globals.lua
globals_lua = os.path.join(PROJECT_ROOT, "globals.lua")
major, minor, patch = 7, 0, 2
if os.path.isfile(globals_lua):
    import re
    with open(globals_lua, "r", encoding="utf-8") as f:
        content = f.read()
        m_major = re.search(r'major\s*=\s*(\d+)', content)
        m_minor = re.search(r'minor\s*=\s*(\d+)', content)
        m_patch = re.search(r'patch\s*=\s*(\d+)', content)
        if m_major and m_minor and m_patch:
            major = int(m_major.group(1))
            minor = int(m_minor.group(1))
            patch = int(m_patch.group(1))

VERSION_NAME = f"v{major}.{minor}.{patch}"
VERSION_CODE = major * 10000 + minor * 100 + patch

# Find Android build tools: zipalign, apksigner
ZIPALIGN = shutil.which("zipalign")
APKSIGNER = shutil.which("apksigner")

if not ZIPALIGN or not APKSIGNER:
    candidate_sdk_dirs = []
    if os.environ.get("ANDROID_HOME"):
        candidate_sdk_dirs.append(os.path.join(os.environ["ANDROID_HOME"], "build-tools"))
    if os.environ.get("ANDROID_SDK_ROOT"):
        candidate_sdk_dirs.append(os.path.join(os.environ["ANDROID_SDK_ROOT"], "build-tools"))
    candidate_sdk_dirs.append(os.path.expanduser("~/Android/Sdk/build-tools"))
    candidate_sdk_dirs.append("/usr/lib/android-sdk/build-tools")

    for sdk_dir in candidate_sdk_dirs:
        if os.path.isdir(sdk_dir):
            versions = sorted([os.path.join(sdk_dir, d) for d in os.listdir(sdk_dir) if os.path.isdir(os.path.join(sdk_dir, d))], reverse=True)
            for v_dir in versions:
                z = os.path.join(v_dir, "zipalign")
                a = os.path.join(v_dir, "apksigner")
                if not ZIPALIGN and os.path.isfile(z):
                    ZIPALIGN = z
                if not APKSIGNER and os.path.isfile(a):
                    APKSIGNER = a
                if ZIPALIGN and APKSIGNER:
                    break
        if ZIPALIGN and APKSIGNER:
            break

if not ZIPALIGN or not APKSIGNER:
    print("Error: Android build-tools (zipalign and apksigner) not found.")
    print("Please install Android SDK build-tools or ensure zipalign/apksigner are in PATH.")
    sys.exit(1)

if not os.path.isfile(LOVE_PATH):
    print(f"Error: {LOVE_PATH} does not exist.")
    sys.exit(1)

# 1. Ensure love-embed.apk exists
os.makedirs(CACHE_DIR, exist_ok=True)
if not os.path.isfile(BASE_APK):
    print("Downloading love-11.5-android-embed.apk template...")
    url = "https://github.com/love2d/love-android/releases/download/11.5a/love-11.5-android-embed.apk"
    subprocess.run(["curl", "-sL", url, "-o", BASE_APK], check=True)

# 2. Ensure keystore exists
if not os.path.isfile(KEYSTORE):
    if "debug" in os.path.basename(KEYSTORE):
        print(f"Generating debug keystore: {KEYSTORE}...")
        os.makedirs(os.path.dirname(KEYSTORE), exist_ok=True)
        keytool = shutil.which("keytool") or "keytool"
        subprocess.run([
            keytool, "-genkeypair", "-keystore", KEYSTORE,
            "-alias", KEY_ALIAS, "-keyalg", "RSA", "-keysize", "2048",
            "-validity", "10000", "-storepass", KS_PASS or "android", "-keypass", KEY_PASS or "android",
            "-dname", "CN=Android Debug,O=Android,C=US"
        ], check=True, stdout=subprocess.DEVNULL)
    else:
        print(f"Error: Release keystore '{KEYSTORE}' not found.")
        sys.exit(1)

# 3. Decompile with apktool
WORK_DIR = f"/tmp/apk_build_{os.getpid()}"
shutil.rmtree(WORK_DIR, ignore_errors=True)
os.makedirs(WORK_DIR, exist_ok=True)
decomp_dir = os.path.join(WORK_DIR, "decompiled")
print("Decompiling Love Android template...")
subprocess.run(["apktool", "d", "-s", BASE_APK, "-o", decomp_dir], check=True, stdout=subprocess.DEVNULL)

# 4. Replace launcher icons with official 2048 Plus icon
src_im = Image.open(ICON_SRC).convert("RGBA")
icon_sizes = {
    "res/drawable-mdpi/love.png": 48,
    "res/drawable-hdpi/love.png": 72,
    "res/drawable-xhdpi/love.png": 96,
    "res/drawable-xxhdpi/love.png": 144,
    "res/drawable-xxxhdpi/love.png": 192,
}
for rel_path, sz in icon_sizes.items():
    dst = os.path.join(decomp_dir, rel_path)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    src_im.resize((sz, sz), Image.LANCZOS).save(dst)

# 5. Modify AndroidManifest.xml and apktool.yml version info
apktool_yml = os.path.join(decomp_dir, "apktool.yml")
if os.path.isfile(apktool_yml):
    import re
    with open(apktool_yml, "r", encoding="utf-8") as f:
        yml_text = f.read()
    yml_text = re.sub(r'versionCode:\s*.*', f'versionCode: {VERSION_CODE}', yml_text)
    yml_text = re.sub(r'versionName:\s*.*', f"versionName: '{VERSION_NAME}'", yml_text)
    with open(apktool_yml, "w", encoding="utf-8") as f:
        f.write(yml_text)

manifest_path = os.path.join(decomp_dir, "AndroidManifest.xml")
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = f.read()

manifest = manifest.replace('android:label="LÖVE for Android"', 'android:label="2048 Plus"')
manifest = manifest.replace('android:screenOrientation="landscape"', 'android:screenOrientation="portrait"')
manifest = manifest.replace('package="org.love2d.android"', f'package="{PACKAGE_NAME}"')
manifest = manifest.replace('org.love2d.android.DYNAMIC_RECEIVER', f'{PACKAGE_NAME}.DYNAMIC_RECEIVER')
manifest = manifest.replace('org.love2d.android.androidx-startup', f'{PACKAGE_NAME}.androidx-startup')

with open(manifest_path, "w", encoding="utf-8") as f:
    f.write(manifest)

# 6. Copy game.love into assets
assets_dir = os.path.join(decomp_dir, "assets")
os.makedirs(assets_dir, exist_ok=True)
shutil.copyfile(LOVE_PATH, os.path.join(assets_dir, "game.love"))

# 7. Rebuild APK
unsigned_apk = os.path.join(WORK_DIR, "unsigned.apk")
print("Compiling APK with apktool...")
subprocess.run(["apktool", "b", decomp_dir, "-o", unsigned_apk], check=True, stdout=subprocess.DEVNULL)

# 8. Zipalign and sign
print("Zipaligning and signing APK...")
aligned_apk = os.path.join(WORK_DIR, "aligned.apk")
subprocess.run([ZIPALIGN, "-p", "-f", "4", unsigned_apk, aligned_apk], check=True)
sign_cmd = [
    APKSIGNER, "sign",
    "--v4-signing-enabled", "false",
    "--ks", KEYSTORE,
    "--ks-pass", f"pass:{KS_PASS}",
    "--key-pass", f"pass:{KEY_PASS}",
    "--ks-key-alias", KEY_ALIAS,
    "--out", APK_OUT, aligned_apk
]
subprocess.run(sign_cmd, check=True)

idsig_file = APK_OUT + ".idsig"
if os.path.exists(idsig_file):
    try:
        os.remove(idsig_file)
    except OSError:
        pass

shutil.rmtree(WORK_DIR, ignore_errors=True)
apk_mb = os.path.getsize(APK_OUT) // (1024 * 1024)
print(f"[OK] Android APK created: build/2048plus.apk ({apk_mb}M)")
