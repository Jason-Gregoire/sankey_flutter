## [0.0.3] - Gradient Rendering & API Improvements

### ✨ New Features
- **Gradient link rendering**: Links now use `LinearGradient` shaders for smooth color transitions between source and target nodes.
- **Texture overlay**: Added `showTexture` parameter to `InteractiveSankeyPainter` and `SankeyDiagramWidget` for subtle texture patterns on links.
- **New `onNodeSelected` callback**: Added `onNodeSelected(SankeyNode?)` callback that provides the full node object, not just the ID.
- **Display label fallback**: Added `SankeyNode.displayLabel` getter that returns label or falls back to `id.toString()`.

### 🛠 Enhancements
- **HSL-based selection borders**: Selected nodes now display contrasting borders using HSL color manipulation instead of fixed yellow.
- **Improved field names**: Renamed node position fields from `x0/x1/y0/y1` to `left/right/top/bottom` for clarity.
- **Efficient hit testing**: Added `SankeyNode.contains(Offset)` method for cleaner tap detection.
- **Subtle node borders**: Unselected nodes now show subtle white borders for better visual definition.
- **`shouldRepaint` optimization**: `InteractiveSankeyPainter` now properly triggers repaints when selection state changes.
- **Responsive example**: Example app now uses `LayoutBuilder` to adapt to screen size.

### ⚠️ Breaking Changes
- Removed deprecated `onNodeTap(int?)` callback. Use `onNodeSelected(SankeyNode?)` instead.

### 🔧 Internal
- Migrated deprecated `withOpacity()` calls to `withAlpha()`.
- Labels enabled by default in example application.
- **Type safety**: `SankeyLink.source` and `SankeyLink.target` are now strongly typed as `SankeyNode` instead of `dynamic`.
- **Consistent naming**: Renamed `Sankey` layout bounds from `x0/y0/x1/y1` to `leftBound/topBound/rightBound/bottomBound`.
- **Widget tests**: Added comprehensive widget tests for `SankeyDiagramWidget`, node detection, and color mapping.

Thanks to [@jheyne](https://github.com/jheyne) for the gradient rendering contribution!

---

## [0.0.2] - Add `showLabels` Toggle for Node Labels

### ✨ New Features
- Added `showLabels` boolean parameter to `InteractiveSankeyPainter` to enable or disable node label rendering.
- Exposed `showLabels` parameter through `buildInteractiveSankeyPainter()` and `SankeyDiagramWidget`, allowing label control at the widget level.
- Added example usage demonstrating label toggle support.

### 🛠 Enhancements
- Label rendering logic now respects the `showLabels` flag during painting.
- Improved flexibility for use cases where minimal or uncluttered visuals are preferred.

Thanks to [@pese-git](https://github.com/pese-git) for the contribution!

---

## [0.0.1] - Initial Release

- Fully featured Sankey layout engine adapted from d3-sankey
- Supports customizable node width, padding, alignment, and interactivity
- Includes test fixture parity with d3's energy example
