#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/build/release/HEIC Drop.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$PWD/build/AppIcon.iconset"
xcrun swift -module-cache-path "$PWD/build/ModuleCache" scripts/icon.swift "$PWD/build/AppIcon.iconset"
python3 - "$PWD/build/AppIcon.iconset" "$APP/Contents/Resources/AppIcon.icns" <<'PYICON'
import pathlib, struct, sys
root=pathlib.Path(sys.argv[1])
chunks=[]
for tag,name in [('icp4','icon_16x16'),('icp5','icon_32x32'),('icp6','icon_32x32@2x'),('ic07','icon_128x128'),('ic08','icon_256x256'),('ic09','icon_512x512'),('ic10','icon_512x512@2x')]:
    data=(root/(name+'.png')).read_bytes()
    chunks.append(tag.encode()+struct.pack('>I',len(data)+8)+data)
body=b''.join(chunks)
pathlib.Path(sys.argv[2]).write_bytes(b'icns'+struct.pack('>I',len(body)+8)+body)
PYICON
cp "$PWD/build/AppIcon.iconset/icon_128x128.png" "$PWD/docs/images/app-icon.png"
xcrun swiftc -module-cache-path "$PWD/build/ModuleCache" Sources/Converter.swift Sources/main.swift -o "$PWD/build/HEICDrop-new" -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers -target arm64-apple-macos13.0
mv -f "$PWD/build/HEICDrop-new" "$APP/Contents/MacOS/HEICDrop"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.berkegokmen.heicdrop</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>HEIC Drop</string>
<key>CFBundleExecutable</key><string>HEICDrop</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
pkgbuild --component "$APP" --install-location /Applications --identifier com.berkegokmen.heicdrop --version 0.1.0 "$PWD/build/HEICDrop-0.1.0.pkg"
