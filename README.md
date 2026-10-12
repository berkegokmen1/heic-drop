<p align="center"><img src="docs/images/app-icon.png" width="96" alt="HEIC Drop icon"></p>
<h1 align="center">HEIC Drop</h1>
<p align="center">Drop. Convert. Copy.</p>

A small native macOS app for converting HEIC images to PNG or JPG. Built with Swift and AppKit, with no third-party dependencies.

## Use

1. Install the `.pkg` into Applications and open **HEIC Drop**.
2. Select **PNG** or **JPG**.
3. Drop one or more images onto the window, paste with **⌘V**, or click **Choose…**.
4. Click **Copy** to copy the converted files, or **Save…** to choose an output folder.

Conversion starts automatically. Drop another batch to replace the current results. Changing the format affects the next batch. Other ImageIO-supported image formats also work. Conversion uses the first image in each file; animated sequences and auxiliary HEIC depth data are not exported.

Images stay on your Mac. Originals are never overwritten. Output names gain a numeric suffix when needed. JPG uses 95% quality and flattens transparency onto white. Orientation is preserved; source EXIF/GPS metadata is not deliberately copied.

Copy places file URLs on the clipboard. Finder and apps that accept pasted files can use them; clipboard behavior depends on the receiving app. Temporary conversion files remain in the system temporary directory so copied files continue to work after quitting. macOS may eventually remove them; use Save for permanent copies.

## Build and test

Requires Apple Silicon, macOS 13 or later, and Xcode Command Line Tools.

```sh
./scripts/test.sh
./scripts/build.sh
```

Outputs:

- `build/release/HEIC Drop.app`
- `build/HEICDrop-0.1.0.pkg`, installing into `/Applications`

The app is ad-hoc signed. The installer is unsigned and not notarized. Developer ID signing and notarization are needed for normal external distribution.

## Project layout

```text
Sources/       Native window, clipboard, drag-and-drop and conversion
Tests/         Image conversion fixtures
scripts/       Build, installer, icon generation and tests
docs/          Validation notes and app icon
```

See [validation notes](docs/VALIDATION.md) for automated coverage and manual checks.

## License

MIT
