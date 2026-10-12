#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcrun swiftc -module-cache-path "$PWD/build/ModuleCache" Sources/Converter.swift Tests/main.swift -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers -o build/converter-tests
./build/converter-tests
