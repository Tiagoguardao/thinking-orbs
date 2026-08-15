# ThinkingOrbsKit

`ThinkingOrbsKit` is the native SwiftUI renderer for thinking-orbs. It ports all nine source states at the two tuned sizes, 20 and 64 points. The public library has no dependencies.

The repository root is the Swift package root. Add the repository URL in Xcode or declare the package in another manifest, then import `ThinkingOrbsKit`.

```swift
ThinkingOrb(state: .searching, size: .px64)
ThinkingOrb(state: .working, size: .px20, theme: .light)
```

The renderer uses `Canvas` and `TimelineView`. `theme: .auto` follows the SwiftUI color scheme. Reduce Motion renders the fixed representative time `0.6`. The animation pauses when its scene becomes inactive. `renderTime` overrides the clock for deterministic screenshots and static widgets.

## Verification

From the repository root:

```bash
npm ci --ignore-scripts
npm run spec
npm run codegen:swift
swift test
swift run ThinkingOrbsSnapshot build/parity/swift
python3 scripts/capture-web-parity.py build/parity/web --probe-output build/parity/probe/web
python3 scripts/parity-diff.py build/parity/web build/parity/swift
```

The geometry suite compares 72 frozen cases against `spec/orbs-golden.json` within `0.0001`. The renderer suite creates 144 browser and Swift images. The current full-frame acceptance budget is `5/255` mean composite difference and `0.8` pixels of centroid drift. Twelve isolated and overlapping-circle probes distinguish primitive raster differences from dense-frame accumulation.
