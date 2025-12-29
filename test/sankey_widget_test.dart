// test/sankey_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_helpers.dart';

/// Creates a simple test dataset with 3 nodes and 2 links
SankeyDataSet createTestDataSet() {
  final nodes = [
    SankeyNode(id: 0, label: 'Source'),
    SankeyNode(id: 1, label: 'Middle'),
    SankeyNode(id: 2, label: 'Target'),
  ];

  final links = [
    SankeyLink(source: nodes[0], target: nodes[1], value: 50),
    SankeyLink(source: nodes[1], target: nodes[2], value: 50),
  ];

  final sankeyDataSet = SankeyDataSet(nodes: nodes, links: links);
  final sankey = generateSankeyLayout(
    width: 400,
    height: 300,
    nodeWidth: 20,
    nodePadding: 10,
  );
  sankeyDataSet.layout(sankey);

  return sankeyDataSet;
}

void main() {
  group('SankeyNode', () {
    test('displayLabel returns label when set', () {
      final node = SankeyNode(id: 1, label: 'Test Label');
      expect(node.displayLabel, 'Test Label');
    });

    test('displayLabel falls back to id.toString() when label is null', () {
      final node = SankeyNode(id: 42);
      expect(node.displayLabel, '42');
    });

    test('displayLabel works with string id', () {
      final node = SankeyNode(id: 'node-abc');
      expect(node.displayLabel, 'node-abc');
    });

    test('contains() returns true for point inside node bounds', () {
      final node = SankeyNode(id: 1)
        ..left = 10
        ..right = 30
        ..top = 20
        ..bottom = 50;

      expect(node.contains(const Offset(20, 35)), isTrue);
      expect(node.contains(const Offset(10, 20)), isTrue); // edge
      expect(node.contains(const Offset(30, 50)), isTrue); // edge
    });

    test('contains() returns false for point outside node bounds', () {
      final node = SankeyNode(id: 1)
        ..left = 10
        ..right = 30
        ..top = 20
        ..bottom = 50;

      expect(node.contains(const Offset(5, 35)), isFalse); // left
      expect(node.contains(const Offset(35, 35)), isFalse); // right
      expect(node.contains(const Offset(20, 15)), isFalse); // above
      expect(node.contains(const Offset(20, 55)), isFalse); // below
    });
  });

  group('detectTappedNode', () {
    test('returns node when tap is inside node bounds', () {
      final nodes = [
        SankeyNode(id: 0)
          ..left = 0
          ..right = 20
          ..top = 0
          ..bottom = 50,
        SankeyNode(id: 1)
          ..left = 100
          ..right = 120
          ..top = 0
          ..bottom = 50,
      ];

      final tapped = detectTappedNode(nodes, const Offset(10, 25));
      expect(tapped, isNotNull);
      expect(tapped!.id, 0);
    });

    test('returns null when tap is outside all nodes', () {
      final nodes = [
        SankeyNode(id: 0)
          ..left = 0
          ..right = 20
          ..top = 0
          ..bottom = 50,
      ];

      final tapped = detectTappedNode(nodes, const Offset(50, 25));
      expect(tapped, isNull);
    });

    test('returns first matching node when overlapping', () {
      final nodes = [
        SankeyNode(id: 0)
          ..left = 0
          ..right = 30
          ..top = 0
          ..bottom = 50,
        SankeyNode(id: 1)
          ..left = 10
          ..right = 40
          ..top = 0
          ..bottom = 50,
      ];

      final tapped = detectTappedNode(nodes, const Offset(20, 25));
      expect(tapped, isNotNull);
      expect(tapped!.id, 0); // First node wins
    });
  });

  group('generateDefaultNodeColorMap', () {
    test('generates colors for all nodes with labels', () {
      final nodes = [
        SankeyNode(id: 0, label: 'A'),
        SankeyNode(id: 1, label: 'B'),
        SankeyNode(id: 2, label: 'C'),
      ];

      final colorMap = generateDefaultNodeColorMap(nodes);

      expect(colorMap.length, 3);
      expect(colorMap.containsKey('A'), isTrue);
      expect(colorMap.containsKey('B'), isTrue);
      expect(colorMap.containsKey('C'), isTrue);
    });

    test('uses displayLabel for nodes without explicit labels', () {
      final nodes = [
        SankeyNode(id: 0), // displayLabel = "0"
        SankeyNode(id: 1, label: 'Named'),
      ];

      final colorMap = generateDefaultNodeColorMap(nodes);

      expect(colorMap.length, 2);
      expect(colorMap.containsKey('0'), isTrue);
      expect(colorMap.containsKey('Named'), isTrue);
    });

    test('does not duplicate colors for same label', () {
      final nodes = [
        SankeyNode(id: 0, label: 'Same'),
        SankeyNode(id: 1, label: 'Same'),
        SankeyNode(id: 2, label: 'Different'),
      ];

      final colorMap = generateDefaultNodeColorMap(nodes);

      expect(colorMap.length, 2); // Only 2 unique labels
    });
  });

  group('SankeyDiagramWidget', () {
    testWidgets('renders without errors', (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
            ),
          ),
        ),
      );

      expect(find.byType(SankeyDiagramWidget), findsOneWidget);
      // GestureDetector is part of SankeyDiagramWidget
      expect(
          find.descendant(
            of: find.byType(SankeyDiagramWidget),
            matching: find.byType(GestureDetector),
          ),
          findsOneWidget);
    });

    testWidgets('calls onNodeSelected when node is tapped', (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);
      SankeyNode? selectedNode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
              onNodeSelected: (node) {
                selectedNode = node;
              },
            ),
          ),
        ),
      );

      // Find the first node's center position
      final firstNode = dataSet.nodes[0];
      final nodeCenter = Offset(
        (firstNode.left + firstNode.right) / 2,
        (firstNode.top + firstNode.bottom) / 2,
      );

      // Get the SankeyDiagramWidget's position
      final widgetFinder = find.byType(SankeyDiagramWidget);
      final topLeft = tester.getTopLeft(widgetFinder);

      // Tap on the node
      await tester.tapAt(topLeft + nodeCenter);
      await tester.pump();

      expect(selectedNode, isNotNull);
      expect(selectedNode!.id, firstNode.id);
    });

    testWidgets('calls onNodeSelected with null when empty space is tapped',
        (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);
      SankeyNode? selectedNode = SankeyNode(id: -1); // Initialize to non-null

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
              onNodeSelected: (node) {
                selectedNode = node;
              },
            ),
          ),
        ),
      );

      // Get the SankeyDiagramWidget's position
      final widgetFinder = find.byType(SankeyDiagramWidget);
      final topLeft = tester.getTopLeft(widgetFinder);

      // Tap on empty space (far from any node)
      await tester.tapAt(topLeft + const Offset(350, 150));
      await tester.pump();

      expect(selectedNode, isNull);
    });

    testWidgets('renders with showLabels=false', (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
              showLabels: false,
            ),
          ),
        ),
      );

      expect(find.byType(SankeyDiagramWidget), findsOneWidget);
    });

    testWidgets('renders with showTexture=false', (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
              showTexture: false,
            ),
          ),
        ),
      );

      expect(find.byType(SankeyDiagramWidget), findsOneWidget);
    });

    testWidgets('selectedNodeId is passed to painter', (tester) async {
      final dataSet = createTestDataSet();
      final nodeColors = generateDefaultNodeColorMap(dataSet.nodes);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: dataSet,
              nodeColors: nodeColors,
              size: const Size(400, 300),
              selectedNodeId: 1,
            ),
          ),
        ),
      );

      // Widget renders without errors with selectedNodeId
      expect(find.byType(SankeyDiagramWidget), findsOneWidget);
    });
  });

  group('SankeyDataSet', () {
    test('layout computes node positions', () {
      final nodes = [
        SankeyNode(id: 0, label: 'A'),
        SankeyNode(id: 1, label: 'B'),
      ];
      final links = [
        SankeyLink(source: nodes[0], target: nodes[1], value: 100),
      ];

      final dataSet = SankeyDataSet(nodes: nodes, links: links);
      final sankey = generateSankeyLayout(
        width: 200,
        height: 100,
        nodeWidth: 20,
        nodePadding: 10,
      );
      dataSet.layout(sankey);

      // After layout, nodes should have computed positions
      expect(nodes[0].right - nodes[0].left, 20); // nodeWidth
      expect(nodes[1].right - nodes[1].left, 20);
      expect(nodes[0].left, lessThan(nodes[1].left)); // A is before B
    });
  });
}
