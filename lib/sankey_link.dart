// lib/sankey_link.dart

import 'sankey_node.dart';

/// A link (flow) between two nodes in the Sankey diagram
class SankeyLink {
  /// The source node where this link originates
  SankeyNode source;

  /// The target node where this link terminates
  SankeyNode target;

  /// The flow value/weight of this link
  double value;

  /// Index assigned during layout computation
  int index = 0;

  /// Vertical start position at source node
  double ySourceStart = 0.0;

  /// Vertical end position at target node
  double yTargetEnd = 0.0;

  /// Computed width of the link (proportional to value)
  double width = 0.0;

  SankeyLink({required this.source, required this.target, required this.value});
}
