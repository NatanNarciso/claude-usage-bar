# Build from source

Requires macOS 14+ and the Xcode **Command Line Tools** (`xcode-select --install`). No Xcode project.

```bash
git clone https://github.com/YOUR_USER/claude-usage-bar.git
cd claude-usage-bar
./build.sh              # build/Claude Usage.app
./build.sh --install    # also copy to ~/Applications and launch
./scripts/make-dmg.sh   # dist/*.dmg, *.zip, SHA256SUMS.txt
```

`build.sh` compiles with `swiftc` directly and ad-hoc signs the bundle (`LSUIElement` = no Dock icon). Bump `VERSION` for releases and tag `vX.Y.Z` — the Release workflow publishes the artifacts.
