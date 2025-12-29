// example/main.dart
//
// Demonstrates all features of the sankey_flutter package:
// - Gradient link rendering with smooth color transitions
// - Interactive node selection with HSL-based contrasting borders
// - Texture overlay on links (toggleable)
// - Node labels (toggleable)
// - Responsive layout using LayoutBuilder
// - onNodeSelected callback for handling tap events

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';

void main() {
  runApp(const SankeyExampleApp());
}

class SankeyExampleApp extends StatelessWidget {
  const SankeyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sankey Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SankeyDemoPage(),
    );
  }
}

class SankeyDemoPage extends StatefulWidget {
  const SankeyDemoPage({super.key});

  @override
  State<SankeyDemoPage> createState() => _SankeyDemoPageState();
}

class _SankeyDemoPageState extends State<SankeyDemoPage> {
  late List<SankeyNode> nodes;
  late List<SankeyLink> links;
  late Map<String, Color> nodeColors;

  // Feature toggles
  bool showLabels = true;
  bool showTexture = true;

  // Selection state
  SankeyNode? selectedNode;

  // Layout caching
  Size? _lastLayoutSize;
  SankeyDataSet? _sankeyDataSet;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Personal finance flow example
    nodes = [
      // Income sources (Layer 0)
      SankeyNode(id: 0, label: 'Salary'),
      SankeyNode(id: 1, label: 'Freelance'),
      SankeyNode(id: 2, label: 'Investments'),
      // Aggregation (Layer 1)
      SankeyNode(id: 3, label: 'Total Income'),
      // Categories (Layer 2)
      SankeyNode(id: 4, label: 'Mandatory'),
      SankeyNode(id: 5, label: 'Discretionary'),
      // Final destinations (Layer 3)
      SankeyNode(id: 6, label: 'Taxes'),
      SankeyNode(id: 7, label: 'Housing'),
      SankeyNode(id: 8, label: 'Food'),
      SankeyNode(id: 9, label: 'Entertainment'),
      SankeyNode(id: 10, label: 'Savings'),
      SankeyNode(id: 11, label: 'Travel'),
    ];

    links = [
      // Income to Total
      SankeyLink(source: nodes[0], target: nodes[3], value: 5000),
      SankeyLink(source: nodes[1], target: nodes[3], value: 1500),
      SankeyLink(source: nodes[2], target: nodes[3], value: 500),
      // Total to Categories
      SankeyLink(source: nodes[3], target: nodes[4], value: 4500),
      SankeyLink(source: nodes[3], target: nodes[5], value: 2500),
      // Mandatory expenses
      SankeyLink(source: nodes[4], target: nodes[6], value: 1500),
      SankeyLink(source: nodes[4], target: nodes[7], value: 2000),
      SankeyLink(source: nodes[4], target: nodes[8], value: 1000),
      // Discretionary expenses
      SankeyLink(source: nodes[5], target: nodes[9], value: 800),
      SankeyLink(source: nodes[5], target: nodes[10], value: 1200),
      SankeyLink(source: nodes[5], target: nodes[11], value: 500),
    ];

    nodeColors = generateDefaultNodeColorMap(nodes);
  }

  SankeyDataSet _computeLayout(Size size) {
    if (_sankeyDataSet != null && _lastLayoutSize == size) {
      return _sankeyDataSet!;
    }

    // Reset node state before relayout
    for (final node in nodes) {
      node.left = 0;
      node.right = 0;
      node.top = 0;
      node.bottom = 0;
      node.sourceLinks = [];
      node.targetLinks = [];
    }

    final sankeyDataSet = SankeyDataSet(nodes: nodes, links: links);
    final sankey = generateSankeyLayout(
      width: size.width,
      height: size.height,
      nodeWidth: 24,
      nodePadding: 20,
    );
    sankeyDataSet.layout(sankey);

    _lastLayoutSize = size;
    _sankeyDataSet = sankeyDataSet;
    return sankeyDataSet;
  }

  void _handleNodeSelected(SankeyNode? node) {
    setState(() {
      selectedNode = node;
    });
  }

  String _formatValue(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sankey Flutter Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                // Feature toggles
                const Text('Features: '),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Labels'),
                  selected: showLabels,
                  onSelected: (value) => setState(() => showLabels = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Texture'),
                  selected: showTexture,
                  onSelected: (value) => setState(() => showTexture = value),
                ),
                const Spacer(),
                // Selected node info
                if (selectedNode != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: nodeColors[selectedNode!.displayLabel]
                              ?.withAlpha(50) ??
                          Colors.grey.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: nodeColors[selectedNode!.displayLabel] ??
                            Colors.grey,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: nodeColors[selectedNode!.displayLabel],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedNode!.displayLabel}: ${_formatValue(selectedNode!.value)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    'Tap a node to select',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // Sankey diagram
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.clamp(400.0, 1200.0);
                final height = (constraints.maxHeight - 32).clamp(300.0, 800.0);
                final size = Size(width, height);
                final sankeyDataSet = _computeLayout(size);

                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SankeyDiagramWidget(
                          data: sankeyDataSet,
                          nodeColors: nodeColors,
                          selectedNodeId: selectedNode?.id,
                          onNodeSelected: _handleNodeSelected,
                          size: size,
                          showLabels: showLabels,
                          showTexture: showTexture,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
