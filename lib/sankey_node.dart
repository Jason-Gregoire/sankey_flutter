// lib/sankey_node.dart

import 'dart:ui';

import 'sankey_link.dart';

/// A node in the Sankey diagram.
class SankeyNode {
  final dynamic id;
  String? label;
  int index = 0;
  double value = 0.0;
  double? fixedValue;
  int depth = 0; // Distance from source
  int height = 0; // Distance to sink
  int layer = 0; // Horizontal column index
  double left = 0.0; // Left x
  double right = 0.0; // Right x
  double top = 0.0; // Top y
  double bottom = 0.0; // Bottom y
  List<SankeyLink> sourceLinks = [];
  List<SankeyLink> targetLinks = [];

  SankeyNode({required this.id, this.label});

  bool contains(Offset pt) =>
      pt.dx >= left && pt.dx <= right && pt.dy >= top && pt.dy <= bottom;
}
