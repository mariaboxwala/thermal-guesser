import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class PuzzleRef {
  final String id;
  final String rgbPath;
  final String tempPath; // not used yet (next step)
  final String maskPath; // not used yet (next step)
  final String metaPath;
  final String? coldPath;

  PuzzleRef({
    required this.id,
    required this.rgbPath,
    required this.tempPath,
    required this.maskPath,
    required this.metaPath,
    this.coldPath, 
  });
}

class PuzzleMeta {
  final int width;
  final int height;
  final int targetX;
  final int targetY;
  final double targetTempC;
  final double? dtMax; // optional (we'll compute if absent)

  PuzzleMeta({
    required this.width,
    required this.height,
    required this.targetX,
    required this.targetY,
    required this.targetTempC,
    this.dtMax,
  });

  static PuzzleMeta fromJson(Map<String, dynamic> j) {
    final t = j['target'] ?? {};
    final s = j['score'] ?? {};
    return PuzzleMeta(
      width: (j['width'] as num?)?.toInt() ?? 0,
      height: (j['height'] as num?)?.toInt() ?? 0,
      targetX: (t['x'] as num?)?.toInt() ?? 0,
      targetY: (t['y'] as num?)?.toInt() ?? 0,
      targetTempC: (t['tempC'] as num?)?.toDouble() ?? 0.0,
      dtMax: (s['dtMax'] as num?)?.toDouble(),
    );
  }
}

Future<List<PuzzleRef>> loadPuzzleIndex() async {
  final raw = await rootBundle.loadString('assets/puzzles/index.json');
  final j = jsonDecode(raw) as Map<String, dynamic>;
  final List<dynamic> arr = (j['puzzles'] as List<dynamic>? ?? []);
  return arr.map((e) {
    final m = e as Map<String, dynamic>;
    return PuzzleRef(
      id: m['id'] as String,
      rgbPath: m['rgb'] as String,
      tempPath: m['temp'] as String,
      maskPath: m['mask'] as String,
      metaPath: m['meta'] as String,
      coldPath: m['cold'] as String?,
    );
  }).toList(growable: false);
}

Future<PuzzleMeta> loadPuzzleMeta(String metaPath) async {
  final s = await rootBundle.loadString(metaPath);
  return PuzzleMeta.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

List<int> randomOrder(int n, {int? seed}) {
  final idx = List<int>.generate(n, (i) => i);
  final rng = Random(seed);
  for (int i = n - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = idx[i];
    idx[i] = idx[j];
    idx[j] = tmp;
  }
  return idx;
}