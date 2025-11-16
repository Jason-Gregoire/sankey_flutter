// example/main.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';

/// The entry point of the Sankey Complex Example application
///
/// This function initializes the app by running [SankeyComplexExampleApp]
void main() {
  runApp(SankeyComplexExampleApp());
}

/// A stateless widget that defines the overall structure of the Sankey Diagram Example App
///
/// It sets the app title, theme, and uses a [Scaffold] to provide an app bar and a body
/// that renders the Sankey diagram
class SankeyComplexExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complex Sankey Diagram Example',
      home: Scaffold(
        appBar: AppBar(title: Text('Complex Sankey Diagram')),
        body: SankeyComplexDiagramWidget(),
      ),
    );
  }
}

/// A stateful widget that manages the interactive Sankey diagram
///
/// This widget builds a Sankey diagram using data defined in the [initState] method
/// It also handles user tap interactions to select nodes
class SankeyComplexDiagramWidget extends StatefulWidget {
  @override
  _SankeyComplexDiagramWidgetState createState() =>
      _SankeyComplexDiagramWidgetState();
}

/// The state class for [SankeyComplexDiagramWidget]
///
/// It defines the nodes, links, node colors, and handles layout computation and tap interactions
/// Changes in state trigger a repaint to reflect node selection and updates to the diagram
class _SankeyComplexDiagramWidgetState
    extends State<SankeyComplexDiagramWidget> {
  late List<SankeyNode> nodes;
  late List<SankeyLink> links;
  late Map<String, Color> nodeColors;
  int? selectedNodeId;
  late SankeyDataSet sankeyDataSet;

  @override
  void initState() {
    super.initState();

    // Define the list of nodes across multiple layers
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

    // Define the links between nodes with specified flow values
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

    // Automatically generate a color map for the nodes using their labels
    nodeColors = generateDefaultNodeColorMap(nodes);

    // Combine the nodes and links into a data set
    sankeyDataSet = SankeyDataSet(nodes: nodes, links: links);

    // Generate the layout using a helper that configures the layout engine
    final sankey = generateSankeyLayout(
      width: 1000,
      height: 600,
      nodeWidth: 20,
      nodePadding: 15,
    );
    sankeyDataSet.layout(sankey);
  }

  /// Callback for handling tap events on nodes
  ///
  /// When a node is tapped, its [id] is stored in [selectedNodeId],
  /// triggering a rebuild that highlights the node
  void _handleNodeTap(int? nodeId) {
    setState(() {
      selectedNodeId = nodeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: SankeyDiagramWidget(
          data: sankeyDataSet,
          nodeColors: nodeColors,
          selectedNodeId: selectedNodeId,
          onNodeTap: _handleNodeTap,
          size: const Size(1000, 600),
          showLabels: false,
        ),
      ),
    );
  }
}
