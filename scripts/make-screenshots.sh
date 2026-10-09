#!/bin/zsh
# Gera os screenshots do painel (EN/PT, claro/escuro) com dados de exemplo.
set -e
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc -parse-as-library -target arm64-apple-macosx14.0 \
  Sources/ClaudeUsageBar/{Mascot,Views,UsageService,Localization}.swift tools/RenderPopover.swift \
  -o .build/RenderPopover
.build/RenderPopover
