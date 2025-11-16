// lib\interactive_sankey_painter.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_painter.dart';

/// A [SankeyPainter] subclass that adds interactivity:
///
/// - Supports custom node colors per label
/// - Highlights connected links when a node is selected
/// - Applies hover/focus feedback with opacity and borders
class InteractiveSankeyPainter extends SankeyPainter {
  /// Map of node labels to specific colors
  final Map<String, Color> nodeColors;
  final bool showTexture;

  /// ID of the currently selected node, if any
  final int? selectedNodeId;

  InteractiveSankeyPainter({
    required List<SankeyNode> nodes,
    required List<SankeyLink> links,
    required this.nodeColors,
    this.selectedNodeId,
    bool showLabels = true,
    this.showTexture = true,
    Color linkColor = Colors.grey,
  }) : super(
          showLabels: showLabels,
          nodes: nodes,
          links: links,
          nodeColor: Colors.blue, // fallback node color
          linkColor: linkColor,
        );

  /// Blends two colors for transition effects (used in link paths)
  Color blendColors(Color a, Color b) => Color.lerp(a, b, 0.5) ?? a;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw enhanced links ---
    for (SankeyLink link in links) {
      final source = link.source as SankeyNode;
      final target = link.target as SankeyNode;

      var sourceColor = nodeColors[source.label] ?? Colors.blue;
      var targetColor = nodeColors[target.label] ?? Colors.blue;

      // Highlight links connected to the selected node
      final isConnected = (selectedNodeId != null) &&
          (source.id == selectedNodeId || target.id == selectedNodeId);
      sourceColor = sourceColor.withAlpha(isConnected ? 225 : 80);
      targetColor = targetColor.withAlpha(isConnected ? 225 : 80);
      
      final gradient = LinearGradient(
       colors: [sourceColor, targetColor], 
       stops: [0.2, 0.8],
    );

      final linkPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(source.x1, source.y1, target.x0 - source.x1, target.y0 - source.y1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = link.width;

      var path = Path();
      final xMid = (source.x1 + target.x0) / 2;
      path.moveTo(source.x1, link.y0);
      path.cubicTo(xMid, link.y0, xMid, link.y1, target.x0, link.y1);
      canvas.drawPath(path, linkPaint);

      // --- Paint texture ---
      if (showTexture) {
        final texturePaint = Paint()
          ..color = Colors.white30
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var i = link.width / -2; i < link.width; i = i+10) {
          path = Path();
          path.moveTo(source.x1, link.y0 + i);
          path.cubicTo(xMid, link.y0 + i, xMid, link.y1 + i, target.x0, link.y1 + i);
          canvas.drawPath(path, texturePaint);
        }
      }
    }

    // --- Draw colored nodes and labels with selection borders ---
    for (SankeyNode node in nodes) {
      final color = nodeColors[node.label] ?? Colors.blue;
      final rect =
          Rect.fromLTWH(node.x0, node.y0, node.x1 - node.x0, node.y1 - node.y0);
      final isSelected = selectedNodeId != null && node.id == selectedNodeId;

      canvas.drawRect(rect, Paint()..color = color);

      if (isSelected) {
        final hsl = HSLColor.fromColor(color);
        final contrast = hsl.withHue(hsl.hue > 180 ? hsl.hue - 180 : hsl.hue + 180);
        final borderPaint = Paint()
          ..color = contrast.toColor() 
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRect(rect, borderPaint);
      } else {
        final borderPaint = Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(rect.deflate(2), borderPaint);
      }

      final isDark = color.computeLuminance() < 0.05;
      final textColor = isDark ? Colors.white : Colors.black;

      if (node.label != null && showLabels) {
        final textSpan = TextSpan(
          text: node.label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout(minWidth: 0, maxWidth: size.width);

        const margin = 6.0;
        final labelY = rect.top + (rect.height - textPainter.height) / 2;
        final labelOffsetRight = Offset(rect.right + margin, labelY);
        final labelOffsetLeft =
            Offset(rect.left - margin - textPainter.width, labelY);

        // Automatically choose a side that fits within the canvas
        final labelOffset =
            (rect.right + margin + textPainter.width <= size.width)
                ? labelOffsetRight
                : (rect.left - margin - textPainter.width >= 0)
                    ? labelOffsetLeft
                    : labelOffsetRight;

        textPainter.paint(canvas, labelOffset);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant InteractiveSankeyPainter oldDelegate) {
    if(oldDelegate.selectedNodeId != selectedNodeId) {
      return true;
    }
    return super.shouldRepaint(oldDelegate);
  }
}
