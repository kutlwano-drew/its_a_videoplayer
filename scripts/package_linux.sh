#!/usr/bin/env bash
set -euo pipefail

APP_NAME="its_a_videoplayer"
DISPLAY_NAME="Its A Video Player"
VERSION="${APP_VERSION:-1.0.0}"
RELEASE_TAG="${RELEASE_TAG:-v1.0.0}"
BUILD_DIR="build/linux/x64/release/bundle"
DIST_DIR="dist/linux"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Error: Linux build directory not found at $BUILD_DIR"
  exit 1
fi

mkdir -p "$DIST_DIR"
mkdir -p build/packaging

# ---------------------------------------------------------
# 1. Tarball (.tar.gz)
# ---------------------------------------------------------
echo "Packaging Tarball..."
tar -czvf "$DIST_DIR/${APP_NAME}-${RELEASE_TAG}-linux-x64.tar.gz" -C "$BUILD_DIR" .

# ---------------------------------------------------------
# 2. DEB (.deb via FPM)
# ---------------------------------------------------------
echo "Packaging DEB..."
fpm -s dir -t deb \
  -p "$DIST_DIR/its_a_videoplayer_${VERSION}_amd64.deb" \
  -n "$APP_NAME" \
  -v "$VERSION" \
  --architecture amd64 \
  --description "A lightweight desktop-first video player built with Flutter." \
  -d "libgtk-3-0" -d "libmpv2" -d "libepoxy0" \
  --prefix "/usr/lib/$APP_NAME" \
  -C "$BUILD_DIR" .

# ---------------------------------------------------------
# 3. RPM (.rpm via FPM)
# ---------------------------------------------------------
echo "Packaging RPM..."
fpm -s dir -t rpm \
  -p "$DIST_DIR/its_a_videoplayer-${VERSION}-1.x86_64.rpm" \
  -n "$APP_NAME" \
  -v "$VERSION" \
  --architecture x86_64 \
  --description "A lightweight desktop-first video player built with Flutter." \
  -d "gtk3" -d "mpv-libs" -d "libepoxy" \
  --prefix "/usr/lib/$APP_NAME" \
  -C "$BUILD_DIR" .

# ---------------------------------------------------------
# 4. AppImage (.AppImage)
# ---------------------------------------------------------
echo "Packaging AppImage..."
wget -q https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O appimagetool
chmod +x appimagetool

APP_DIR="build/packaging/AppDir"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"

cp -r "$BUILD_DIR"/* "$APP_DIR/usr/bin/"

cat <<EOF > "$APP_DIR/$APP_NAME.desktop"
[Desktop Entry]
Type=Application
Name=$DISPLAY_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Categories=AudioVideo;Player;Video;
EOF

if [ -f "assets/logo.png" ]; then
  cp assets/logo.png "$APP_DIR/$APP_NAME.png"
else
  touch "$APP_DIR/$APP_NAME.png"
fi

cat <<EOF > "$APP_DIR/AppRun"
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
export PATH="\$HERE/usr/bin:\$PATH"
export LD_LIBRARY_PATH="\$HERE/usr/bin/lib:\$LD_LIBRARY_PATH"
exec "\$HERE/usr/bin/$APP_NAME" "\$@"
EOF
chmod +x "$APP_DIR/AppRun"

./appimagetool "$APP_DIR" "$DIST_DIR/${APP_NAME}-${RELEASE_TAG}-x86_64.AppImage"

# ---------------------------------------------------------
# 5. Snap (.snap via Snapcraft)
# ---------------------------------------------------------
echo "Packaging Snap..."
snapcraft --target-arch=amd64
mv *.snap "$DIST_DIR/"