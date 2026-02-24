#!/usr/bin/env bash
# Generate light/dark screenshots for README, Flatpak metainfo, F-Droid.
# Run from project root: ./scripts/generate-screenshots.sh
set -e

cd "$(dirname "$0")/.."

echo "Generating golden screenshots (light + dark)..."
flutter test test/screenshot_test.dart --update-goldens

echo "Copying to flatpak/screenshots/..."
mkdir -p flatpak/screenshots
cp test/goldens/*.png flatpak/screenshots/

echo "Copying to fdroid metadata (F-Droid store)..."
FDROID_IMG="fdroid/metadata/com.d0dg3r.gitsyncmarks/en-US/images/phoneScreenshots"
mkdir -p "$FDROID_IMG"
cp test/goldens/bookmark-list.png "$FDROID_IMG/1.png"
cp test/goldens/bookmark-list-dark.png "$FDROID_IMG/2.png"
cp test/goldens/settings-github.png "$FDROID_IMG/3.png"

echo "Done. Screenshots: flatpak/screenshots/ + fdroid/.../phoneScreenshots/"
ls -la flatpak/screenshots/
ls -la "$FDROID_IMG"
