// test\sankey_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_helpers.dart';

double _r(double x, [int precision = 2]) {
  final factor = pow(10, precision).toDouble();
  return (x * factor).roundToDouble() / factor;
}

Map<String, dynamic> roundNode(SankeyNode node) {
  return {
    "x": _r(node.left),
    "dx": _r(node.right - node.left),
    "y": _r(node.top),
    "dy": _r(node.bottom - node.top),
  };
}

Map<String, dynamic> roundLink(SankeyLink link) {
  final source = link.source as SankeyNode;
  final target = link.target as SankeyNode;

  return {
    "source": roundNode(source),
    "target": roundNode(target),
    "dy": _r(link.width),
    "sy": _r(link.ySourceStart - source.top - link.width / 2),
    "ty": _r(link.yTargetEnd - target.top - link.width / 2),
  };
}

bool fuzzyEqual(dynamic a, dynamic b, {double tolerance = 0.01}) {
  if (a is Map && b is Map) {
    for (final key in a.keys) {
      if (!fuzzyEqual(a[key], b[key], tolerance: tolerance)) return false;
    }
    return true;
  } else if (a is num && b is num) {
    return (a - b).abs() <= tolerance;
  } else {
    return a == b;
  }
}

void expectFuzzyEqual(
  List<Map<String, dynamic>> actual,
  List<Map<String, dynamic>> expected,
  String context, {
  double tolerance = 0.01,
}) {
  expect(actual.length, expected.length,
      reason:
          '$context length mismatch: ${actual.length} vs ${expected.length}');
  for (int i = 0; i < actual.length; i++) {
    final a = actual[i];
    final b = expected[i];
    final matches = fuzzyEqual(a, b, tolerance: tolerance);
    expect(matches, isTrue,
        reason:
            '$context[$i] mismatch\nActual: $a\nExpected: $b\nTolerance: ±$tolerance');
  }
}

Future<Map<String, dynamic>> loadJsonMap(String path) async {
  final file = File(path);
  return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> loadJsonList(String path) async {
  final file = File(path);
  final decoded = jsonDecode(await file.readAsString());
  return List<Map<String, dynamic>>.from(decoded);
}

void main() {
  test('Fuzzy match Sankey layout to d3-sankey energy.json', () async {
    final energy = await loadJsonMap('test/energy.json');
    final expectedNodes = await loadJsonList('test/energy_nodes.json');
    final expectedLinks = await loadJsonList('test/energy_links.json');

    final rawNodes = energy['nodes'] as List;
    final rawLinks = energy['links'] as List;

    final nodes = rawNodes.asMap().entries.map((entry) {
      return SankeyNode(id: entry.key);
    }).toList();

    final links = rawLinks.asMap().entries.map((entry) {
      final map = entry.value as Map;
      return SankeyLink(
        source: nodes[map['source']],
        target: nodes[map['target']],
        value: (map['value'] as num).toDouble(),
      );
    }).toList();

    final sankeyData = SankeyDataSet(nodes: nodes, links: links);
    final sankey = generateSankeyLayout(
      width: 959,
      height: 494,
      nodeWidth: 15,
      nodePadding: 10,
    );
    sankeyData.layout(sankey);

    final actualNodes = nodes.map(roundNode).toList();
    final actualLinks = links.map(roundLink).toList();

    expectFuzzyEqual(actualNodes, expectedNodes, 'Node');
    expectFuzzyEqual(actualLinks, expectedLinks, 'Link');
  });
}
