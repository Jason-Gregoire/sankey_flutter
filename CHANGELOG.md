# Changelog

All notable changes to the `sankey_flutter` package will be documented in this file.

## [0.0.3] - 2025-12-29

### ✨ New Features
- **Gradient link rendering** - Links now use `LinearGradient` shaders for smooth color transitions between source and target nodes
- **Texture overlay** - Added `showTexture` parameter for subtle texture patterns on links, enhancing visual depth
- **Node selection callback** - New `onNodeSelected(SankeyNode?)` callback provides the full node object on tap
- **Display label fallback** - `SankeyNode.displayLabel` getter returns label or falls back to `id.toString()`

### 🛠 Enhancements
- **HSL-based selection borders** - Selected nodes display contrasting borders using intelligent HSL color manipulation
- **Clearer field names** - Renamed node position fields from `x0/x1/y0/y1` to `left/right/top/bottom`
- **Efficient hit testing** - Added `SankeyNode.contains(Offset)` method for cleaner tap detection
- **Subtle node borders** - Unselected nodes show subtle white borders for better visual definition
- **Repaint fix** - `shouldRepaint` now correctly triggers for `selectedNodeId`, `showLabels`, and `showTexture` changes
- **Responsive example** - Example app uses `LayoutBuilder` to adapt to screen size

### ⚠️ Breaking Changes
- Removed deprecated `onNodeTap(int?)` callback — use `onNodeSelected(SankeyNode?)` instead

### 🔧 Internal
- Migrated deprecated `withOpacity()` calls to `withAlpha()`
- **Type safety** - `SankeyLink.source` and `SankeyLink.target` are now strongly typed as `SankeyNode`
- **Consistent naming** - Renamed `Sankey` layout bounds from `x0/y0/x1/y1` to `leftBound/topBound/rightBound/bottomBound`
- **Widget tests** - Added comprehensive tests for `SankeyDiagramWidget`, node detection, and color mapping

> **Contributor:** [@jheyne](https://github.com/jheyne) — gradient rendering implementation

---

## [0.0.2] - 2025-04-16

### ✨ New Features
- **Label toggle** - Added `showLabels` boolean parameter to `InteractiveSankeyPainter` to show/hide node labels
- Exposed `showLabels` through `buildInteractiveSankeyPainter()` and `SankeyDiagramWidget`

### 🛠 Enhancements
- Label rendering respects the `showLabels` flag during painting
- Improved flexibility for minimal or uncluttered diagram visuals

> **Contributor:** [@pese-git](https://github.com/pese-git) — showLabels feature

---

## [0.0.1] - 2025-04-01

### 🎉 Initial Release
- Fully featured Sankey layout engine adapted from [d3-sankey](https://github.com/d3/d3-sankey)
- Customizable node width, padding, and alignment
- Interactive node selection with tap detection
- Test fixture parity with d3's energy.json example

---

## Contributors

A huge thank you to our community contributors:

| Contributor | Contribution |
|-------------|--------------|
| [@jheyne](https://github.com/jheyne) | Gradient link rendering, texture overlay, HSL selection borders |
| [@pese-git](https://github.com/pese-git) | `showLabels` toggle feature |
