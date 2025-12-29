// lib/sankey_node.dart

import 'dart:ui';

import 'sankey_link.dart';

/// A node in the Sankey diagram.
///
/// Each node has a unique [id] and an optional [label] for display.
/// Use [displayLabel] to get a non-null label (falls back to id.toString()).
class SankeyNode {
  /// Unique identifier for this node
  final dynamic id;

  /// Optional display label for the node
  String? label;

  /// Index assigned during layout computation
  int index = 0;

  /// Computed flow value through this node
  double value = 0.0;

  /// Optional fixed value override
  double? fixedValue;

  /// Distance from source nodes (horizontal depth)
  int depth = 0;

  /// Distance to sink nodes
  int height = 0;

  /// Horizontal column index after layout
  int layer = 0;

  /// Left edge x-coordinate after layout
  double left = 0.0;

  /// Right edge x-coordinate after layout
  double right = 0.0;

  /// Top edge y-coordinate after layout
  double top = 0.0;

  /// Bottom edge y-coordinate after layout
  double bottom = 0.0;

  /// Links where this node is the source
  List<SankeyLink> sourceLinks = [];

  /// Links where this node is the target
  List<SankeyLink> targetLinks = [];

  SankeyNode({required this.id, this.label});

  /// Returns the label if set, otherwise falls back to id.toString()
  ///
  /// This ensures a non-null string is always available for display and
  /// color mapping purposes.
  String get displayLabel => label ?? id.toString();

  /// Returns true if the given point is within this node's bounds
  bool contains(Offset pt) =>
      pt.dx >= left && pt.dx <= right && pt.dy >= top && pt.dy <= bottom;
}
