// lib/sankey_painter.dart

import 'package:flutter/material.dart';
import 'sankey_node.dart';
import 'sankey_link.dart';

/// A base [CustomPainter] for rendering a non-interactive Sankey diagram
///
/// This painter:
/// - Draws links between nodes using smooth cubic Bézier paths
/// - Renders nodes as colored rectangles
/// - Optionally draws labels for each node
///
/// Extend this class (e.g., [InteractiveSankeyPainter]) for user-interaction features
class SankeyPainter extends CustomPainter {
  /// List of Sankey nodes with layout geometry
  final List<SankeyNode> nodes;

  /// List of Sankey links that define flow between nodes
  final List<SankeyLink> links;

  /// Default color to use for all nodes
  final Color nodeColor;

  /// Default color to use for all links
  final Color linkColor;

  /// Whether to display node labels beside the nodes
  final bool showLabels;

  SankeyPainter({
    required this.nodes,
    required this.links,
    this.nodeColor = Colors.blue,
    this.linkColor = Colors.grey,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw links first, behind nodes ---
    for (SankeyLink link in links) {
      final source = link.source;
      final target = link.target;

      final path = Path();
      final xMid = (source.right + target.left) / 2;

      path.moveTo(source.right, link.ySourceStart);
      path.cubicTo(xMid, link.ySourceStart, xMid, link.yTargetEnd, target.left, link.yTargetEnd);

      final blendedColor = Color.lerp(Colors.transparent, linkColor, 0.5)!;

      final paint = Paint()
        ..color = blendedColor.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = link.width;

      canvas.drawPath(path, paint);
    }

    // --- Draw nodes and optional labels ---
    for (final node in nodes) {
      final rect = Rect.fromLTWH(
        node.left,
        node.top,
        node.right - node.left,
        node.bottom - node.top,
      );

      final paint = Paint()..color = nodeColor;
      canvas.drawRect(rect, paint);

      if (showLabels) {
        final textSpan = TextSpan(
          text: node.displayLabel,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelX = node.right + 6;
        final labelY =
            node.top + (node.bottom - node.top - textPainter.height) / 2;
        final labelOffset = Offset(labelX, labelY);

        if (labelX + textPainter.width <= size.width) {
          textPainter.paint(canvas, labelOffset);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SankeyPainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.links != links;
  }
}
