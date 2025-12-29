// lib/sankey.dart

import 'dart:math';

import 'sankey_node.dart';
import 'sankey_link.dart';

/// Signature for an alignment function, used to compute the horizontal
/// placement of a node. It takes a [SankeyNode] and the total number of columns
/// (or maximum depth) [n], returning the column index where the node should be placed
typedef NodeAlign = int Function(SankeyNode node, int n);

/// Positions the node at the left side, using its [depth] as the column index
///
/// This alignment is equivalent to the d3‑sankey "left" alignment
int sankeyLeft(SankeyNode node, int n) => node.depth;

/// Positions the node at the right side of the diagram by subtracting its
/// [height] from the total number of columns
///
/// This alignment is equivalent to the d3‑sankey "right" alignment
int sankeyRight(SankeyNode node, int n) => n - 1 - node.height;

/// Aligns the node using a justifying algorithm
///
/// It returns the node's [depth] if it has outgoing links (i.e. it is a source),
/// otherwise it assigns the node to the rightmost column. This mirrors d3‑sankey's
/// "justify" alignment
int sankeyJustify(SankeyNode node, int n) =>
    node.sourceLinks.isNotEmpty ? node.depth : n - 1;

/// Centers the node based on its incoming/outgoing relationships
///
/// - If the node has incoming links (i.e. it is a target), its column is set to
///   its [depth].
/// - Otherwise, if it has outgoing links, its column is set to one less than the
///   minimum depth of its target nodes
/// - If neither is available, the node is placed in column 0
///
/// This function mimics d3‑sankey's "center" alignment
int sankeyCenter(SankeyNode node, int n) {
  if (node.targetLinks.isNotEmpty) return node.depth;
  if (node.sourceLinks.isNotEmpty)
    return (node.sourceLinks.map((link) => link.target.depth).reduce(min)) - 1;
  return 0;
}

/// A Sankey layout generator that computes the positions and dimensions
/// for the nodes and links in a Sankey diagram
///
/// The layout algorithm follows several steps:
/// 1. Initialize node links
/// 2. Compute node values based on incoming and outgoing flows
/// 3. Assign horizontal positions (depths/layers)
/// 4. Compute node heights (reverse assignment via incoming links)
/// 5. Position nodes vertically
/// 6. Compute the widths of the links
/// 7. Return a [SankeyGraph] containing the positioned nodes and links
///
/// The bounds of the layout are defined by `[leftBound, topBound]` and `[rightBound, bottomBound]`,
/// while `nodeWidth` and `nodePadding` determine the size and spacing of nodes
class Sankey {
  /// Left edge of the layout area
  double leftBound;

  /// Top edge of the layout area
  double topBound;

  /// Right edge of the layout area
  double rightBound;

  /// Bottom edge of the layout area
  double bottomBound;

  // Node width and padding
  double nodeWidth;
  double nodePadding;

  // Alignment function (default is justifying)
  NodeAlign align;

  // Number of relaxation iterations
  int iterations;

  // Optional sorting functions
  int Function(SankeyNode a, SankeyNode b)? nodeSort;
  int Function(SankeyLink a, SankeyLink b)? linkSort;

  /// Creates a [Sankey] layout generator with customizable
  /// bounds, node sizing, alignment, and iteration count
  ///
  /// If no [align] function is provided, it defaults to [sankeyJustify]
  Sankey({
    this.leftBound = 0,
    this.topBound = 0,
    this.rightBound = 1,
    this.bottomBound = 1,
    this.nodeWidth = 24,
    this.nodePadding = 8,
    NodeAlign? align,
    this.iterations = 6,
    this.nodeSort,
    this.linkSort,
  }) : align = align ?? sankeyJustify;

  /// Computes the layout for the given [nodes] and [links] and returns a
  /// [SankeyGraph] containing the computed positions
  ///
  /// The layout algorithm performs internal steps such as establishing node links,
  /// computing node values, assigning depths and heights, distributing nodes
  /// horizontally and vertically, and finally computing link positions
  SankeyGraph layout(List<SankeyNode> nodes, List<SankeyLink> links) {
    _computeNodeLinks(nodes, links);
    _computeNodeValues(nodes);
    _computeNodeDepths(nodes);
    _computeNodeHeights(nodes);
    _computeNodeBreadths(nodes);
    _computeLinkBreadths(nodes);
    return SankeyGraph(nodes: nodes, links: links);
  }

  /// Initializes each node's source and target links
  ///
  /// This function loops over every node to reset its link lists
  /// then assigns each link to its corresponding source and target nodes
  void _computeNodeLinks(List<SankeyNode> nodes, List<SankeyLink> links) {
    // Initialize each node’s sourceLinks and targetLinks.
    for (int i = 0; i < nodes.length; i++) {
      nodes[i].index = i;
      nodes[i].sourceLinks = [];
      nodes[i].targetLinks = [];
    }
    // For each link, add it to the respective source and target nodes
    for (int i = 0; i < links.length; i++) {
      SankeyLink link = links[i];
      link.index = i;
      link.source.sourceLinks.add(link);
      link.target.targetLinks.add(link);
    }
    // Optionally sort links if a sort function is provided
    if (linkSort != null) {
      for (SankeyNode node in nodes) {
        node.sourceLinks.sort(linkSort);
        node.targetLinks.sort(linkSort);
      }
    }
  }

  /// Computes node values by summing the incoming and outgoing link values
  ///
  /// For each node, if a fixed value is provided via [fixedValue], it is used;
  /// otherwise, the node's value is set to the maximum of the sum of its source links
  /// or target links. This ensures that the node's rendered size reflects the
  /// largest flow through it
  void _computeNodeValues(List<SankeyNode> nodes) {
    for (SankeyNode node in nodes) {
      if (node.fixedValue != null) {
        node.value = node.fixedValue!;
      } else {
        double sumSource =
            node.sourceLinks.fold(0.0, (prev, link) => prev + link.value);
        double sumTarget =
            node.targetLinks.fold(0.0, (prev, link) => prev + link.value);
        node.value = max(sumSource, sumTarget);
      }
    }
  }

  /// Assigns a horizontal depth to each node using a breadth-first search
  ///
  /// Nodes are processed level by level, starting with the initial list
  /// A node's depth represents its horizontal distance from the source
  /// If a circular dependency is detected, an exception is thrown
  void _computeNodeDepths(List<SankeyNode> nodes) {
    int n = nodes.length;
    List<SankeyNode> current = List.from(nodes);
    List<SankeyNode> next = [];
    int depth = 0;
    while (current.isNotEmpty) {
      for (SankeyNode node in current) {
        node.depth = depth;
        for (SankeyLink link in node.sourceLinks) {
          if (!next.contains(link.target)) {
            next.add(link.target);
          }
        }
      }
      depth++;
      if (depth > n) {
        throw Exception("Circular link detected in computeNodeDepths");
      }
      current = List.from(next);
      next.clear();
    }
  }

  /// Computes the height (reverse depth) of each node via a reverse
  /// breadth-first search using incoming links
  ///
  /// The height represents the distance from the node to a sink
  /// If a circular dependency is detected, an exception is thrown
  void _computeNodeHeights(List<SankeyNode> nodes) {
    int n = nodes.length;
    List<SankeyNode> current = List.from(nodes);
    List<SankeyNode> next = [];
    int height = 0;
    while (current.isNotEmpty) {
      for (SankeyNode node in current) {
        node.height = height;
        for (SankeyLink link in node.targetLinks) {
          if (!next.contains(link.source)) {
            next.add(link.source);
          }
        }
      }
      height++;
      if (height > n) {
        throw Exception("Circular link detected in computeNodeHeights");
      }
      current = List.from(next);
      next.clear();
    }
  }

  /// Computes the columns (or layers) of nodes based on their horizontal position
  ///
  /// The maximum depth is computed and each node is assigned a layer value using
  /// the provided [align] function. Horizontal positions are then calculated
  /// for each node. Optionally, nodes can be sorted using [nodeSort]
  List<List<SankeyNode>> _computeNodeLayers(List<SankeyNode> nodes) {
    // Determine the maximum depth
    int maxDepth = nodes.map((node) => node.depth).reduce(max) + 1;
    // Compute horizontal spacing
    double kx =
        maxDepth > 1 ? (rightBound - leftBound - nodeWidth) / (maxDepth - 1) : 0;
    List<List<SankeyNode>> columns = List.generate(maxDepth, (_) => []);
    for (SankeyNode node in nodes) {
      int layer = align(node, maxDepth);
      layer = layer.clamp(0, maxDepth - 1);
      node.layer = layer;
      node.left = leftBound + layer * kx;
      node.right = node.left + nodeWidth;
      columns[layer].add(node);
    }
    if (nodeSort != null) {
      for (List<SankeyNode> column in columns) {
        column.sort(nodeSort);
      }
    }
    return columns;
  }

  /// Computes the vertical positions and sizes of nodes
  ///
  /// This method first computes the vertical scaling factor `ky` for each column,
  /// then assigns vertical positions to each node accordingly. It also computes
  /// the width of each link based on the scaling factor. Finally, extra spacing is added
  /// and node links are reordered to match the behavior of d3‑sankey
  void _initializeNodeBreadths(List<List<SankeyNode>> columns) {
    // Determine the vertical scaling factor (ky)
    double ky = double.infinity;
    for (List<SankeyNode> column in columns) {
      double columnSum = column.fold(0.0, (prev, node) => prev + node.value);
      if (column.isNotEmpty) {
        ky = min(ky,
            (bottomBound - topBound - (column.length - 1) * nodePadding) / columnSum);
      }
    }
    // Position each node vertically
    for (List<SankeyNode> column in columns) {
      double y = topBound;
      for (SankeyNode node in column) {
        node.top = y;
        node.bottom = y + node.value * ky;
        y = node.bottom + nodePadding;
        // Set the computed link widths
        for (SankeyLink link in node.sourceLinks) {
          link.width = link.value * ky;
        }
      }
      // Add extra vertical spacing
      double spacing = (bottomBound - y + nodePadding) / (column.length + 1);
      for (int i = 0; i < column.length; i++) {
        column[i].top += spacing * (i + 1);
        column[i].bottom += spacing * (i + 1);
      }
      // Reorder node links to match the JS implementation
      _reorderLinks(column);
    }
  }

  /// Computes the final vertical positions of nodes (node breadths) and
  /// performs iterative relaxation to minimize overlap
  ///
  /// Nodes are first assigned to columns (layers) and then positioned using
  /// [_initializeNodeBreadths]. Iterative relaxation is applied to adjust nodes
  /// from left-to-right and right-to-left for a balanced layout
  void _computeNodeBreadths(List<SankeyNode> nodes) {
    List<List<SankeyNode>> columns = _computeNodeLayers(nodes);
    int maxNodes = columns.map((col) => col.length).reduce(max);
    double effectiveNodePadding =
        min(nodePadding, (bottomBound - topBound) / (maxNodes - 1));
    nodePadding = effectiveNodePadding;
    _initializeNodeBreadths(columns);
    // Apply iterative relaxation.
    for (int i = 0; i < iterations; i++) {
      double alpha = pow(0.99, i).toDouble();
      double beta = max(1 - alpha, (i + 1) / iterations);
      _relaxRightToLeft(columns, alpha, beta);
      _relaxLeftToRight(columns, alpha, beta);
    }
  }

  /// Computes the vertical positions for links based on the positions of the nodes
  ///
  /// For each node, this method calculates the starting position for outgoing links
  /// and the ending position for incoming links, adjusting for the link width
  void _computeLinkBreadths(List<SankeyNode> nodes) {
    for (SankeyNode node in nodes) {
      double offset = node.top;
      for (SankeyLink link in node.sourceLinks) {
        link.ySourceStart = offset + link.width / 2;
        offset += link.width;
      }
      offset = node.top;
      for (SankeyLink link in node.targetLinks) {
        link.yTargetEnd = offset + link.width / 2;
        offset += link.width;
      }
    }
  }

  /// Performs relaxation of node positions from left to right
  ///
  /// For each node (except those in the first column), adjusts the vertical position
  /// based on the weighted average of the positions of the nodes in the previous column
  /// Then, it resolves any collisions that result
  void _relaxLeftToRight(
      List<List<SankeyNode>> columns, double alpha, double beta) {
    for (int i = 1; i < columns.length; i++) {
      for (SankeyNode target in columns[i]) {
        double ySum = 0;
        double weightSum = 0;
        for (SankeyLink link in target.targetLinks) {
          double idealY = _targetTop(link.source, target);
          double weight = link.value * (target.layer - link.source.layer);
          ySum += idealY * weight;
          weightSum += weight;
        }
        if (weightSum > 0) {
          double dy = (ySum / weightSum - target.top) * alpha;
          target.top += dy;
          target.bottom += dy;
          _reorderNodeLinks(target);
        }
      }
      if (nodeSort == null) {
        columns[i].sort((a, b) => a.top.compareTo(b.top));
      }
      _resolveCollisions(columns[i], beta);
    }
  }

  /// Performs relaxation of node positions from right to left
  ///
  /// Adjusts the vertical positions for nodes in earlier columns based on their
  /// source nodes in later columns, then resolves collisions
  void _relaxRightToLeft(
      List<List<SankeyNode>> columns, double alpha, double beta) {
    for (int i = columns.length - 2; i >= 0; i--) {
      for (SankeyNode source in columns[i]) {
        double ySum = 0;
        double weightSum = 0;
        for (SankeyLink link in source.sourceLinks) {
          double idealY = _sourceTop(source, link.target);
          double weight = link.value * (link.target.layer - source.layer);
          ySum += idealY * weight;
          weightSum += weight;
        }
        if (weightSum > 0) {
          double dy = (ySum / weightSum - source.top) * alpha;
          source.top += dy;
          source.bottom += dy;
          _reorderNodeLinks(source);
        }
      }
      if (nodeSort == null) {
        columns[i].sort((a, b) => a.top.compareTo(b.top));
      }
      _resolveCollisions(columns[i], beta);
    }
  }

  /// Resolves collisions among nodes within a column
  ///
  /// This method checks and adjusts the positions of nodes in a column so that they
  /// do not overlap. It does so by processing nodes both from the middle outward and by
  /// applying adjustments top-to-bottom and bottom-to-top
  void _resolveCollisions(List<SankeyNode> column, double alpha) {
    if (column.isEmpty) return;
    int mid = column.length ~/ 2;
    _resolveCollisionsBottomToTop(
        column, column[mid].top - nodePadding, mid - 1, alpha);
    _resolveCollisionsTopToBottom(
        column, column[mid].bottom + nodePadding, mid + 1, alpha);
    _resolveCollisionsBottomToTop(column, bottomBound, column.length - 1, alpha);
    _resolveCollisionsTopToBottom(column, topBound, 0, alpha);
  }

  /// Adjusts node positions from top downwards to resolve collisions
  void _resolveCollisionsTopToBottom(
      List<SankeyNode> column, double y, int startIndex, double alpha) {
    for (int i = startIndex; i < column.length; i++) {
      SankeyNode node = column[i];
      double dy = (y - node.top) * alpha;
      if (dy > 1e-6) {
        node.top += dy;
        node.bottom += dy;
      }
      y = node.bottom + nodePadding;
    }
  }

  /// Adjusts node positions from bottom upwards to resolve collisions
  void _resolveCollisionsBottomToTop(
      List<SankeyNode> column, double y, int startIndex, double alpha) {
    for (int i = startIndex; i >= 0; i--) {
      SankeyNode node = column[i];
      double dy = (node.bottom - y) * alpha;
      if (dy > 1e-6) {
        node.top -= dy;
        node.bottom -= dy;
      }
      y = node.top - nodePadding;
    }
  }

  /// Reorders the links for the given node based on the vertical positions
  /// of connected nodes
  ///
  /// For consistency with d3‑sankey:
  /// - [sourceLinks] are sorted by the [top] position of their target nodes
  /// - [targetLinks] are sorted by the [top] position of their source nodes
  /// In the event of a tie, the link's index is used as a tie-breaker
  void _reorderNodeLinks(SankeyNode node) {
    if (linkSort == null) {
      node.sourceLinks.sort((a, b) {
        int cmp = a.target.top.compareTo(b.target.top);
        return cmp != 0 ? cmp : a.index.compareTo(b.index);
      });
      node.targetLinks.sort((a, b) {
        int cmp = a.source.top.compareTo(b.source.top);
        return cmp != 0 ? cmp : a.index.compareTo(b.index);
      });
    }
  }

  /// Reorders links for all nodes in the given column
  ///
  /// This ensures that the ordering of link offsets is consistent
  /// with the behavior of d3‑sankey
  void _reorderLinks(List<SankeyNode> nodes) {
    if (linkSort == null) {
      for (SankeyNode node in nodes) {
        node.sourceLinks.sort((a, b) {
          int cmp = a.target.top.compareTo(b.target.top);
          return cmp != 0 ? cmp : a.index.compareTo(b.index);
        });
        node.targetLinks.sort((a, b) {
          int cmp = a.source.top.compareTo(b.source.top);
          return cmp != 0 ? cmp : a.index.compareTo(b.index);
        });
      }
    }
  }

  /// Calculates the ideal starting vertical position for links leaving a source node
  /// connecting to the specified target node
  ///
  /// This is computed by starting from the source node's top position, adjusting
  /// for the link widths and padding until the target node is reached
  double _targetTop(SankeyNode source, SankeyNode target) {
    double y = source.top - (source.sourceLinks.length - 1) * nodePadding / 2;
    for (SankeyLink link in source.sourceLinks) {
      if (link.target == target) break;
      y += link.width + nodePadding;
    }
    for (SankeyLink link in target.targetLinks) {
      if (link.source == source) break;
      y -= link.width;
    }
    return y;
  }

  /// Calculates the ideal starting vertical position for links entering a target node
  /// from the specified source node
  ///
  /// This is computed by starting from the target node's top position and adjusting
  /// for the widths of incoming links, ensuring a visually balanced position
  double _sourceTop(SankeyNode source, SankeyNode target) {
    double y = target.top - (target.targetLinks.length - 1) * nodePadding / 2;
    for (SankeyLink link in target.targetLinks) {
      if (link.source == source) break;
      y += link.width + nodePadding;
    }
    for (SankeyLink link in source.sourceLinks) {
      if (link.target == target) break;
      y -= link.width;
    }
    return y;
  }
}

/// A simple container for the computed Sankey diagram graph
///
/// The [SankeyGraph] holds the list of nodes and links after the layout
/// generator has computed their positions and dimensions
class SankeyGraph {
  /// The list of positioned Sankey nodes
  final List<SankeyNode> nodes;

  /// The list of Sankey links with computed geometries
  final List<SankeyLink> links;

  SankeyGraph({required this.nodes, required this.links});
}
