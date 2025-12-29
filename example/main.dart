// example/main.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';

void main() {
  runApp(const SankeyComplexExampleApp());
}

class SankeyComplexExampleApp extends StatelessWidget {
  const SankeyComplexExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complex Sankey Diagram Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Complex Sankey Diagram')),
        body: const SankeyComplexDiagramWidget(),
      ),
    );
  }
}

class SankeyComplexDiagramWidget extends StatefulWidget {
  const SankeyComplexDiagramWidget({super.key});

  @override
  State<SankeyComplexDiagramWidget> createState() =>
      _SankeyComplexDiagramWidgetState();
}

class _SankeyComplexDiagramWidgetState
    extends State<SankeyComplexDiagramWidget> {
  late List<SankeyNode> nodes;
  late List<SankeyLink> links;
  late Map<String, Color> nodeColors;
  int? selectedNodeId;

  // Track the last computed size to avoid unnecessary relayouts
  Size? _lastLayoutSize;
  SankeyDataSet? _sankeyDataSet;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    nodes = [
      SankeyNode(id: 0, label: 'Salary'),
      SankeyNode(id: 1, label: 'Freelance'),
      SankeyNode(id: 2, label: 'Investments'),
      SankeyNode(id: 3, label: 'Total Income'),
      SankeyNode(id: 13, label: 'Mandatory Expenses'),
      SankeyNode(id: 14, label: 'Discretionary Expenses'),
      SankeyNode(id: 4, label: 'Taxes'),
      SankeyNode(id: 5, label: 'Essentials'),
      SankeyNode(id: 6, label: 'Discretionary'),
      SankeyNode(id: 7, label: 'Savings'),
      SankeyNode(id: 8, label: 'Debt'),
      SankeyNode(id: 9, label: 'Investments Reinvested'),
      SankeyNode(id: 10, label: 'Healthcare'),
      SankeyNode(id: 11, label: 'Education'),
      SankeyNode(id: 12, label: 'Donations'),
    ];

    links = [
      SankeyLink(source: nodes[0], target: nodes[3], value: 70),
      SankeyLink(source: nodes[1], target: nodes[3], value: 30),
      SankeyLink(source: nodes[2], target: nodes[3], value: 20),
      SankeyLink(source: nodes[3], target: nodes[13], value: 64),
      SankeyLink(source: nodes[3], target: nodes[14], value: 56),
      SankeyLink(source: nodes[13], target: nodes[4], value: 20),
      SankeyLink(source: nodes[13], target: nodes[5], value: 40),
      SankeyLink(source: nodes[13], target: nodes[10], value: 3),
      SankeyLink(source: nodes[13], target: nodes[11], value: 1),
      SankeyLink(source: nodes[14], target: nodes[6], value: 20),
      SankeyLink(source: nodes[14], target: nodes[7], value: 20),
      SankeyLink(source: nodes[14], target: nodes[8], value: 10),
      SankeyLink(source: nodes[14], target: nodes[9], value: 5),
      SankeyLink(source: nodes[14], target: nodes[12], value: 1),
    ];

    nodeColors = generateDefaultNodeColorMap(nodes);
  }

  /// Computes the Sankey layout for the given size.
  /// Only recomputes if the size has changed.
  SankeyDataSet _computeLayout(Size size) {
    if (_sankeyDataSet != null && _lastLayoutSize == size) {
      return _sankeyDataSet!;
    }

    // Reset node positions before relayout
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
      nodeWidth: 20,
      nodePadding: 15,
    );
    sankeyDataSet.layout(sankey);

    _lastLayoutSize = size;
    _sankeyDataSet = sankeyDataSet;
    return sankeyDataSet;
  }

  void _handleNodeTap(SankeyNode? node) {
    setState(() {
      selectedNodeId = node?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width, with min/max constraints for usability
        final width = constraints.maxWidth.clamp(400.0, 1200.0);
        // Maintain a reasonable aspect ratio (5:3)
        final height = (width * 0.6).clamp(300.0, 800.0);
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
                  selectedNodeId: selectedNodeId,
                  onNodeSelected: _handleNodeTap,
                  size: size,
                  showLabels: true,
                  showTexture: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
