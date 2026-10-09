#!/bin/zsh
# Regenera docs/assets/mascot-states.gif (os 4 estados animados do mascote).
set -e
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc -parse-as-library -target arm64-apple-macosx14.0 Sources/ClaudeUsageBar/Mascot.swift tools/RenderGIF.swift -o .build/RenderGIF
.build/RenderGIF docs/assets/mascot-states.gif
