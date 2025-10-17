import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'puzzles.dart';

// ===================== APP ENTRY =====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B0FF),
        brightness: Brightness.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B0FF)),
        ),
        labelStyle: const TextStyle(color: Color(0xFFBBBBBB)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thermal Guesser',
      themeMode: ThemeMode.dark,
      theme: dark,
      home: const StartScreen(),
    );
  }
}

// ===================== LOGO =====================

// Top-left overlay for pages WITHOUT an AppBar
class TopLeftLogoOverlay extends StatelessWidget {
  const TopLeftLogoOverlay({super.key, this.size = 28, this.padding = const EdgeInsets.all(8)});
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: padding,
          child: Image.asset('assets/ui/SCL.png', height: size),
        ),
      ),
    );
  }
}

// Logo for AppBars (pages WITH an AppBar)
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key, this.size = 28, this.padding = const EdgeInsets.symmetric(horizontal: 8)});
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Image.asset('assets/ui/SCL.png', height: size),
    );
  }
}

// ===================== START (centered) =====================
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _startSession() async {
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInAnonymously();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final sessions = FirebaseFirestore.instance.collection('sessions');
      final doc = await sessions.add({
        'ownerUid': uid,
        'name': _name.text.trim(),
        'email': "",
        'totalScore': 0,
        'imagesCompleted': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'finished': false,
      });
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DemoScreen(sessionId: doc.id, playerName: _name.text.trim()),
        ),
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _name.text.trim().isNotEmpty && !_busy;

    return Scaffold(
      // no AppBar (removes top-left title)
      body: Stack(
        children: [
          const TopLeftLogoOverlay(),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Leaderboard',
                icon: const Icon(Icons.leaderboard),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaderboardAllScreen()),
                  );
                },
              ),
            ),
          ),

          // Centered form
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Centered title
                    Text(
                      'Thermal Guesser',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Bigger name field
                    TextField(
                      controller: _name,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 22),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        labelText: null,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),

                    const SizedBox(height: 20),

                    // Big Start button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canStart ? _startSession : null,
                        child: _busy
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Start',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== TEMP SCALE =====================

// === Temperature scale (vertical) ===
class TempScaleBar extends StatelessWidget {
  const TempScaleBar({
    super.key,
    this.minC = 0,
    this.maxC = 60,
    this.width = 56,
    this.assetPath = 'assets/ui/inferno_palette_vertical.png',
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final double minC;
  final double maxC;
  final double width;
  final String assetPath;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );

    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${maxC.toStringAsFixed(0)}°C', style: labelStyle),
            const SizedBox(height: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${minC.toStringAsFixed(0)}°C', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

// === Temperature scale (horizontal) ===
class TempScaleBarHorizontal extends StatelessWidget {
  const TempScaleBarHorizontal({
    super.key,
    this.minC = 0,
    this.maxC = 60,
    this.height = 48,
    this.assetPath = 'assets/ui/inferno_palette_vertical.png',
    this.quarterTurns = 1, // 1 = 90° clockwise; use 3 to flip direction
  });

  final double minC;
  final double maxC;
  final double height;
  final String assetPath;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${minC.toStringAsFixed(0)}°C', style: labelStyle),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: RotatedBox(
                quarterTurns: quarterTurns, // rotate vertical palette → horizontal
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${maxC.toStringAsFixed(0)}°C', style: labelStyle),
        ],
      ),
    );
  }
}

// ===================== DEMO (puzzles/01) =====================
// ===================== DEMO (puzzles/01) =====================
class DemoScreen extends StatefulWidget {
  final String sessionId;
  final String playerName;
  const DemoScreen({super.key, required this.sessionId, required this.playerName});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  PuzzleRef? _demo;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadDemo();
  }

  Future<void> _loadDemo() async {
    final all = await loadPuzzleIndex();
    if (all.isEmpty) {
      setState(() { _demo = null; _busy = false; });
      return;
    }
    final d = all.firstWhere((p) => p.id == '01', orElse: () => all.first);
    setState(() { _demo = d; _busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CONSISTENT APP BAR (Back + Logo in title + ~5px edge buffer)
      appBar: AppBar(
        automaticallyImplyLeading: false, // we lay out leading manually
        title: null,                      // title comes from flexibleSpace
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              // 1) Centered title
              Center(
                child: Text(
                  'Demo',
                  style: Theme.of(context).appBarTheme.titleTextStyle
                      ?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 2) Left cluster: Back + Logo (with small buffer)
              Positioned(
                left: 10, top: 10, bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    const AppBarLogo(size: 24, padding: EdgeInsets.zero),
                  ],
                ),
              ),

              // 3) Right cluster: actions + ~5px buffer
              Positioned(
                right: 10, top: 10, bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Leaderboard',
                      icon: const Icon(Icons.leaderboard),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LeaderboardAllScreen()),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Home',
                      icon: const Icon(Icons.home_outlined),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const StartScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // MAIN CONTENT
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _busy || _demo == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, cons) {
                  final wide = cons.maxWidth >= 800;

                  final panes = <Widget>[
                    // LEFT: Instructions
                    Flexible(
                      flex: 5,
                      child: _DemoInstructions(
                        onLeaderboard: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LeaderboardAllScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16, height: 16),
                    // RIGHT: Demo image card
                    Flexible(
                      flex: 7,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _DemoCard(
                            ref: _demo!,
                            onContinue: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => RoundGridScreen(
                                    sessionId: widget.sessionId,
                                    playerName: widget.playerName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ];
                  return wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: panes)
                      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: panes);
                },
              ),
      ),
    );
  }
}


class _DemoCard extends StatefulWidget {
  final PuzzleRef ref;
  final VoidCallback onContinue;
  const _DemoCard({required this.ref, required this.onContinue});
  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  int _w = 0, _h = 0;
  String? _rgbPath, _mrtPath, _maskPath, _metaPath, _coldPath;
  List<double>? _mrtGray;
  List<int>? _mask;
  Offset? _tapImg;
  bool _submitted = false;
  late Future<void> _prep;

  int? _tx, _ty;
  double? _iStar, _iMin, _iMax;

  @override
  void initState() {
    super.initState();
    _prep = _prepare();
  }

  Future<ui.Image> _decodeUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<List<double>> _toGray(ui.Image img) async {
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = bd!.buffer.asUint8List();
    final w = img.width, h = img.height;
    final out = List<double>.filled(w * h, 0.0, growable: false);
    for (int i = 0, p = 0; i < bytes.length; i += 4, p++) {
      final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
      out[p] = 0.299 * r + 0.587 * g + 0.114 * b;
    }
    return out;
  }

  List<double> _resizeBilinear(List<double> src, int sw, int sh, int dw, int dh) {
    final dst = List<double>.filled(dw * dh, 0.0, growable: false);
    if (sw == dw && sh == dh) {
      for (int i = 0; i < dst.length; i++) {
        dst[i] = src[i];
      }
      return dst;
    }
    for (int y = 0; y < dh; y++) {
      final gy = ((y + 0.5) * (sh / dh)) - 0.5;
      final y0 = gy.floor().clamp(0, sh - 1);
      final y1 = (y0 + 1).clamp(0, sh - 1);
      final wy = gy - y0;
      for (int x = 0; x < dw; x++) {
        final gx = ((x + 0.5) * (sw / dw)) - 0.5;
        final x0 = gx.floor().clamp(0, sw - 1);
        final x1 = (x0 + 1).clamp(0, sw - 1);
        final wx = gx - x0;
        final i00 = src[y0 * sw + x0];
        final i01 = src[y0 * sw + x1];
        final i10 = src[y1 * sw + x0];
        final i11 = src[y1 * sw + x1];
        final top = i00 * (1 - wx) + i01 * wx;
        final bot = i10 * (1 - wx) + i11 * wy;
        dst[y * dw + x] = top * (1 - wy) + bot * wy;
      }
    }
    return dst;
  }

  List<int> _nearestResizeMask(List<int> src, int sw, int sh, int dw, int dh) {
    final dst = List<int>.filled(dw * dh, 0, growable: false);
    for (int y = 0; y < dh; y++) {
      final sy = (y * sh / dh).floor().clamp(0, sh - 1);
      for (int x = 0; x < dw; x++) {
        final sx = (x * sw / dw).floor().clamp(0, sw - 1);
        dst[y * dw + x] = src[sy * sw + sx];
      }
    }
    return dst;
  }

  Future<List<int>> _loadMaskOrOnes(String? path, int w, int h) async {
    if (path == null || path.isEmpty) return List<int>.filled(w * h, 1, growable: false);
    try {
      final img = await _decodeUiImage(path);
      final gray = await _toGray(img);
      List<int> raw = gray.map((v) => v > 127 ? 1 : 0).toList();
      if (img.width != w || img.height != h) {
        raw = _nearestResizeMask(raw, img.width, img.height, w, h);
      }
      return raw;
    } catch (_) {
      return List<int>.filled(w * h, 1, growable: false);
    }
  }

  Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> _prepare() async {
    final p = widget.ref;
    _rgbPath = p.rgbPath;
    _mrtPath = p.tempPath;
    _maskPath = p.maskPath;
    _metaPath = p.metaPath;
    _coldPath = p.coldPath;

    final rgb = await _decodeUiImage(_rgbPath!);
    final rw = rgb.width, rh = rgb.height;
    _w = rw; _h = rh;

    final mrt = await _decodeUiImage(_mrtPath!);
    var gray = await _toGray(mrt);
    if (mrt.width != rw || mrt.height != rh) {
      gray = _resizeBilinear(gray, mrt.width, mrt.height, rw, rh);
    }

    final mask = await _loadMaskOrOnes(_maskPath, rw, rh);

    int tX = 0, tY = 0;
    try {
      final meta = await _loadJson(_metaPath!);
      final mw = (meta['width'] ?? rw) as int;
      final mh = (meta['height'] ?? rh) as int;
      final mt = (meta['target'] as Map<String, dynamic>);
      final mx = (mt['x'] as num).toDouble();
      final my = (mt['y'] as num).toDouble();
      tX = ((mx / (mw - 1).clamp(1, 1e9)) * (rw - 1)).round().clamp(0, rw - 1);
      tY = ((my / (mh - 1).clamp(1, 1e9)) * (rh - 1)).round().clamp(0, rh - 1);
    } catch (_) {
      int minIdx = 0; double minVal = double.infinity;
      for (int i = 0; i < rw * rh; i++) {
        if (mask[i] == 0) continue;
        final v = gray[i];
        if (v < minVal) { minVal = v; minIdx = i; }
      }
      final my = (minIdx / rw).floor();
      final mx = minIdx - my * rw;
      tX = mx; tY = my;
    }

    final iStar = gray[tY * rw + tX];
    double iMin = double.infinity, iMax = -double.infinity;
    for (int i = 0; i < rw * rh; i++) {
      if (mask[i] == 0) continue;
      final v = gray[i];
      if (v < iMin) iMin = v;
      if (v > iMax) iMax = v;
    }

    setState(() {
      _mrtGray = gray;
      _mask = mask;
      _tx = tX; _ty = tY;
      _iStar = iStar; _iMin = iMin; _iMax = iMax;
    });
  }

  void _onTapDown(TapDownDetails d, Size boxSize) {
    if (_submitted) return;
    if (_w == 0 || _h == 0 || _mask == null) return;

    final map = _fitContain(Size(_w.toDouble(), _h.toDouble()), boxSize);
    final local = d.localPosition;

    // outside the image? ignore
    if (local.dx < map.offX || local.dx > map.offX + map.drawW ||
        local.dy < map.offY || local.dy > map.offY + map.drawH) {
      return;
    }

    final nx = (local.dx - map.offX) / map.drawW;
    final ny = (local.dy - map.offY) / map.drawH;
    final ix = (nx * _w).clamp(0, _w - 1).floor();
    final iy = (ny * _h).clamp(0, _h - 1).floor();

    // sky (mask==0) is unclickable
    final playable = _mask![iy * _w + ix] != 0;
    if (!playable) {
      return;
    }

    setState(() { _tapImg = Offset(ix.toDouble(), iy.toDouble()); });
  }

  void _submit() {
    if (_submitted || _tapImg == null) return;
    setState(() { _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _w > 0 && _h > 0 && _mrtGray != null && _tx != null && _ty != null;
    return !ready
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT: interactive image
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          final boxSize = Size(cons.maxWidth, cons.maxHeight);
                          return GestureDetector(
                            onTapDown: (d) => _onTapDown(d, boxSize),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    _submitted ? _mrtPath! : _rgbPath!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                                if (_tapImg != null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _DotPainter(
                                        imgSize: Size(_w.toDouble(), _h.toDouble()),
                                        tapImg: _tapImg!,
                                        color: const Color(0xFF90CAF9),
                                        radius: 6,
                                      ),
                                    ),
                                  ),
                                if (_submitted && _coldPath != null)
                                  Positioned.fill(
                                    child: Image.asset(
                                      _coldPath!,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // RIGHT: show scale only after submit
                    if (_submitted) ...[
                      const SizedBox(width: 8),
                      TempScaleBar(minC: 0, maxC: 60),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Exit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (!_submitted && _tapImg != null) ? _submit : null,
                      child: const Text('Submit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitted ? widget.onContinue : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}

class _DemoInstructions extends StatelessWidget {
  final VoidCallback? onLeaderboard;
  const _DemoInstructions({super.key, this.onLeaderboard});

  @override
  Widget build(BuildContext context) {
    // === Font-size knobs — tweak these ===
    const double titleFontSize = 26;      // section title
    const double bulletTitleSize = 22;    // bullet heading
    const double bodyFontSize = 20;       // bullet body

    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: titleFontSize,
        );

    Widget bullet(IconData icon, String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: bulletTitleSize,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(fontSize: bodyFontSize, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget tip(String t) => Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Chip(
        label: Text(
          t,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        // LayoutBuilder + ConstrainedBox centers the content vertically
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // vertical centering
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How this demo works', style: titleStyle),
                    const SizedBox(height: 12),

                    bullet(
                      Icons.visibility,
                      'Look first',
                      'Study the natural photo. You’re trying to guess the coolest spot in the scene.',
                    ),
                    bullet(
                      Icons.touch_app,
                      'Tap to place your guess',
                      'Tap once on the image to drop a blue dot. You can move it by tapping again before submitting.',
                    ),
                    bullet(
                      Icons.check_circle_outline,
                      'Submit to reveal',
                      'After you submit, the thermal image appears and a translucent “cold mask” overlays the 5% coolest regions.',
                    ),
                    const SizedBox(height: 16),
                    Center(child: tip('Tip: Sky pixels don’t count')),
                    const SizedBox(height: 64),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: onLeaderboard,
                        icon: const Icon(Icons.leaderboard),
                        label: const Text('Leaderboard'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===================== ROUND OF 3 (side-by-side) =====================
class RoundGridScreen extends StatefulWidget {
  final String sessionId;
  final String playerName;
  const RoundGridScreen({super.key, required this.sessionId, required this.playerName});
  @override
  State<RoundGridScreen> createState() => _RoundGridScreenState();
}

class _RoundGridScreenState extends State<RoundGridScreen> {
  List<PuzzleRef> _cards = [];
  final Map<int, int> _scores = {}; // index -> 0..100
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _pickThree();
  }

  Future<void> _pickThree() async {
    final all = await loadPuzzleIndex();
    final pool = all.where((p) => p.id != '01').toList(); // exclude demo
    final order = randomOrder(pool.length);
    final sel = <PuzzleRef>[];
    for (int i = 0; i < math.min(3, pool.length); i++) {
      sel.add(pool[order[i]]);
    }
    setState(() { _cards = sel; _busy = false; });
  }

  double _avg() {
    if (_scores.isEmpty) return 0.0;
    final s = _scores.values.fold<int>(0, (a, b) => a + b);
    return s / _cards.length;
  }

  Future<void> _onCardSubmitted(int idx, int score) async {
    setState(() { _scores[idx] = score; });
    if (_scores.length == _cards.length) {
      final avgScore = _avg().round();
      try {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .update({
          'totalScore': avgScore,
          'imagesCompleted': _cards.length,
          'finished': true,
        });
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LeaderboardAllScreen(
            highlightSessionId: widget.sessionId,
            yourScore: avgScore,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false, // we lay out the toolbar ourselves
      title: null,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            // Centered title that never collides with left/right clusters
            Center(
              child: Text(
                'Round',
                style: Theme.of(context).appBarTheme.titleTextStyle
                    ?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Left cluster: Back + Logo with edge buffer
            Positioned(
              left: 10, top: 10, bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(width: 8),
                  const AppBarLogo(size: 24, padding: EdgeInsets.zero),
                ],
              ),
            ),

            // Right cluster: actions with edge buffer
            Positioned(
              right: 10, top: 10, bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Leaderboard',
                    icon: const Icon(Icons.leaderboard),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LeaderboardAllScreen()),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Home',
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const StartScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, cons) {
                  // === Responsive 3-across cards ===
                  const gap = 16.0;
                  final available = cons.maxWidth;

                  // 3 cards side-by-side
                  final cardWidth   = (available - gap * 2) / 3.0;
                  // Make the image tall, but leave room for button + padding
                  final imageHeight = cardWidth * 1.20;          // was 1.25
                  // Height budget: image + 8 gap + 40 button + 16 card padding + 8 card margin
                  final rowHeight   = imageHeight + 8 + 40 + 16 + 8;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pick the coolest spot • Submitted ${_scores.length}/${_cards.length} • Avg: ${_avg().toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: rowHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_cards.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(right: i == _cards.length - 1 ? 0 : gap),
                              child: SizedBox(
                                width: cardWidth,
                                child: Card(
                                  margin: EdgeInsets.zero,            // remove default 4px margin
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: _RoundCard(
                                      index: i,
                                      ref: _cards[i],
                                      onSubmitted: (score) => _onCardSubmitted(i, score),
                                      imageHeight: imageHeight,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: const TempScaleBarHorizontal(
                          minC: 0,
                          maxC: 60,
                          height: 48,         // adjust if you want a slimmer/thicker bar
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _RoundCard extends StatefulWidget {
  final int index;
  final PuzzleRef ref;
  final ValueChanged<int> onSubmitted; // score 0..100
  final double imageHeight;            // provided by parent for consistent sizing
  const _RoundCard({
    required this.index,
    required this.ref,
    required this.onSubmitted,
    required this.imageHeight,
  });
  @override
  State<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends State<_RoundCard> {
  int _w = 0, _h = 0;
  String? _rgbPath, _mrtPath, _maskPath, _metaPath, _coldPath;
  List<double>? _mrtGray;
  List<int>? _mask;
  Offset? _tapImg;
  bool _submitted = false;
  int _score = 0;

  int? _tx, _ty;          // from meta (scaled)
  double? _iStar;         // intensity at target
  double? _iMin, _iMax;   // range over mask

  late Future<void> _prep;

  @override
  void initState() {
    super.initState();
    _prep = _prepare();
  }

  // ---- helpers (same as demo) ----
  Future<ui.Image> _decodeUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<List<double>> _toGray(ui.Image img) async {
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = bd!.buffer.asUint8List();
    final w = img.width, h = img.height;
    final out = List<double>.filled(w * h, 0.0, growable: false);
    for (int i = 0, p = 0; i < bytes.length; i += 4, p++) {
      final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
      out[p] = 0.299 * r + 0.587 * g + 0.114 * b;
    }
    return out;
  }

  List<double> _resizeBilinear(List<double> src, int sw, int sh, int dw, int dh) {
    final dst = List<double>.filled(dw * dh, 0.0, growable: false);
    if (sw == dw && sh == dh) {
      for (int i = 0; i < dst.length; i++) {
        dst[i] = src[i];
      }
      return dst;
    }
    for (int y = 0; y < dh; y++) {
      final gy = ((y + 0.5) * (sh / dh)) - 0.5;
      final y0 = gy.floor().clamp(0, sh - 1);
      final y1 = (y0 + 1).clamp(0, sh - 1);
      final wy = gy - y0;
      for (int x = 0; x < dw; x++) {
        final gx = ((x + 0.5) * (sw / dw)) - 0.5;
        final x0 = gx.floor().clamp(0, sw - 1);
        final x1 = (x0 + 1).clamp(0, sw - 1);
        final wx = gx - x0;
        final i00 = src[y0 * sw + x0];
        final i01 = src[y0 * sw + x1];
        final i10 = src[y1 * sw + x0];
        final i11 = src[y1 * sw + x1];
        final top = i00 * (1 - wx) + i01 * wx;
        final bot = i10 * (1 - wx) + i11 * wy;
        dst[y * dw + x] = top * (1 - wy) + bot * wy;
      }
    }
    return dst;
  }

  List<int> _nearestResizeMask(List<int> src, int sw, int sh, int dw, int dh) {
    final dst = List<int>.filled(dw * dh, 0, growable: false);
    for (int y = 0; y < dh; y++) {
      final sy = (y * sh / dh).floor().clamp(0, sh - 1);
      for (int x = 0; x < dw; x++) {
        final sx = (x * sw / dw).floor().clamp(0, sw - 1);
        dst[y * dw + x] = src[sy * sw + sx];
      }
    }
    return dst;
  }

  Future<List<int>> _loadMaskOrOnes(String? path, int w, int h) async {
    if (path == null || path.isEmpty) return List<int>.filled(w * h, 1, growable: false);
    try {
      final img = await _decodeUiImage(path);
      final gray = await _toGray(img);
      List<int> raw = gray.map((v) => v > 127 ? 1 : 0).toList();
      if (img.width != w || img.height != h) {
        raw = _nearestResizeMask(raw, img.width, img.height, w, h);
      }
      return raw;
    } catch (_) {
      return List<int>.filled(w * h, 1, growable: false);
    }
  }

  Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> _prepare() async {
    final p = widget.ref;
    _rgbPath = p.rgbPath;
    _mrtPath = p.tempPath;
    _maskPath = p.maskPath;
    _metaPath = p.metaPath;
    _coldPath = p.coldPath;

    final rgb = await _decodeUiImage(_rgbPath!);
    final rw = rgb.width, rh = rgb.height;
    _w = rw; _h = rh;

    final mrt = await _decodeUiImage(_mrtPath!);
    var gray = await _toGray(mrt);
    if (mrt.width != rw || mrt.height != rh) {
      gray = _resizeBilinear(gray, mrt.width, mrt.height, rw, rh);
    }

    final mask = await _loadMaskOrOnes(_maskPath, rw, rh);

    int tX = 0, tY = 0;
    try {
      final meta = await _loadJson(_metaPath!);
      final mw = (meta['width'] ?? rw) as int;
      final mh = (meta['height'] ?? rh) as int;
      final mt = (meta['target'] as Map<String, dynamic>);
      final mx = (mt['x'] as num).toDouble();
      final my = (mt['y'] as num).toDouble();
      tX = ((mx / (mw - 1).clamp(1, 1e9)) * (rw - 1)).round().clamp(0, rw - 1);
      tY = ((my / (mh - 1).clamp(1, 1e9)) * (rh - 1)).round().clamp(0, rh - 1);
    } catch (_) {
      int minIdx = 0; double minVal = double.infinity;
      for (int i = 0; i < rw * rh; i++) {
        if (mask[i] == 0) continue;
        final v = gray[i];
        if (v < minVal) { minVal = v; minIdx = i; }
      }
      final my = (minIdx / rw).floor();
      final mx = minIdx - my * rw;
      tX = mx; tY = my;
    }

    final iStar = gray[tY * rw + tX];
    double iMin = double.infinity, iMax = -double.infinity;
    for (int i = 0; i < rw * rh; i++) {
      if (mask[i] == 0) continue;
      final v = gray[i];
      if (v < iMin) iMin = v;
      if (v > iMax) iMax = v;
    }

    setState(() {
      _mrtGray = gray;
      _mask = mask;
      _tx = tX; _ty = tY;
      _iStar = iStar; _iMin = iMin; _iMax = iMax;
    });
  }

  void _onTapDown(TapDownDetails d, Size boxSize) {
    if (_submitted) return;
    if (_w == 0 || _h == 0 || _mask == null) return;

    final map = _fitContain(Size(_w.toDouble(), _h.toDouble()), boxSize);
    final local = d.localPosition;

    if (local.dx < map.offX || local.dx > map.offX + map.drawW ||
        local.dy < map.offY || local.dy > map.offY + map.drawH) {
      return;
    }

    final nx = (local.dx - map.offX) / map.drawW;
    final ny = (local.dy - map.offY) / map.drawH;
    final ix = (nx * _w).clamp(0, _w - 1).floor();
    final iy = (ny * _h).clamp(0, _h - 1).floor();

    // block taps on sky/invalid pixels
    final playable = _mask![iy * _w + ix] != 0;
    if (!playable) {
      return;
    }
    setState(() { _tapImg = Offset(ix.toDouble(), iy.toDouble()); });
  }

  void _submit() {
    if (_submitted || _tapImg == null || _mrtGray == null || _iStar == null || _iMin == null || _iMax == null) return;

    final x = _tapImg!.dx.floor().clamp(0, _w - 1);
    final y = _tapImg!.dy.floor().clamp(0, _h - 1);
    final idx = y * _w + x;

    final iGuess = _mrtGray![idx];
    final iStar = _iStar!;
    final iMin = _iMin!;
    final iMax = _iMax!;
    final dt = (iGuess - iStar).abs();
    final dmax = math.max(1e-6, math.max(iStar - iMin, iMax - iStar));
    final score = (100.0 * (1.0 - dt / dmax)).clamp(0.0, 100.0).round();

    setState(() { _score = score; _submitted = true; });
    widget.onSubmitted(score);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prep,
      builder: (context, snap) {
        final ready = _w > 0 && _h > 0 && _mrtGray != null && _tx != null && _ty != null;
        if (!ready) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Use LayoutBuilder to get the *actual* width inside the Card's padding.
        return LayoutBuilder(
          builder: (context, cons) {
            final imgW = cons.maxWidth; // accurate inner width
            final imgH = widget.imageHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imgH,
                  child: GestureDetector(
                    onTapDown: (d) => _onTapDown(d, Size(imgW, imgH)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            _submitted ? _mrtPath! : _rgbPath!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        if (_tapImg != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DotPainter(
                                imgSize: Size(_w.toDouble(), _h.toDouble()),
                                tapImg: _tapImg!,
                                color: const Color(0xFF90CAF9),
                                radius: 5,
                              ),
                            ),
                          ),
                        if (_submitted && _coldPath != null)
                          Positioned.fill(
                            child: Image.asset(
                              _coldPath!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: _submitted
                      ? Center(
                          child: Text(
                            'Score: $_score',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: (_tapImg != null) ? _submit : null,
                          child: const Text('Submit'),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ===================== LEADERBOARD (ALL) =====================
class LeaderboardAllScreen extends StatelessWidget {
  final String? highlightSessionId;
  final int? yourScore;
  const LeaderboardAllScreen({super.key, this.highlightSessionId, this.yourScore});

  Color? _rankBorder(int i) {
    if (i == 0) return const Color(0xFFFFD700); // Gold
    if (i == 1) return const Color(0xFFC0C0C0); // Silver
    if (i == 2) return const Color(0xFFCD7F32); // Bronze
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('sessions')
        .orderBy('totalScore', descending: true);
    return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: null,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            // Centered title
            Center(
              child: Text(
                'Leaderboard — All Players',
                style: Theme.of(context).appBarTheme.titleTextStyle
                    ?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Left: Back + Logo
            Positioned(
              left: 10, top: 10, bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  const AppBarLogo(size: 24, padding: EdgeInsets.zero),
                ],
              ),
            ),

            // Right: Home + ~5px buffer
            Positioned(
              right: 10, top: 10, bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Home',
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const StartScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No sessions yet.'));

          int rank = -1;
          if (highlightSessionId != null) {
            for (int i = 0; i < docs.length; i++) {
              if (docs[i].id == highlightSessionId) { rank = i + 1; break; }
            }
          }

          return Column(
            children: [
              if (highlightSessionId != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Chip(
                    label: Text(
                      rank > 0
                          ? 'Your rank: #$rank of ${docs.length} • Score: ${yourScore ?? '-'}'
                          : 'Your session recorded • Score: ${yourScore ?? '-'}',
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final m = d.data();
                    final name = (m['name'] ?? '').toString();
                    final score = (m['totalScore'] ?? 0).toString();
                    final me = d.id == highlightSessionId;

                    final rankBorder = _rankBorder(i);
                    final highlightColor = me ? const Color(0xFF0D47A1) : null;

                    return Card(
                      color: highlightColor ?? Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: rankBorder != null
                            ? BorderSide(color: rankBorder, width: 2)
                            : const BorderSide(color: Colors.transparent),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rankBorder ?? const Color(0xFF424242),
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.black)),
                        ),
                        title: Text(name.isEmpty ? 'Anonymous' : name),
                        trailing: Text(
                          score,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================== DRAW HELPERS =====================
class _DotPainter extends CustomPainter {
  final Size imgSize;
  final Offset tapImg;
  final Color color;
  final double radius;
  _DotPainter({
    required this.imgSize,
    required this.tapImg,
    this.color = const Color(0xFF2196F3),
    this.radius = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final map = _fitContain(imgSize, size);
    final nx = tapImg.dx / imgSize.width;
    final ny = tapImg.dy / imgSize.height;
    final px = map.offX + nx * map.drawW;
    final py = map.offY + ny * map.drawH;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.95);
    canvas.drawCircle(Offset(px, py), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) {
    return old.tapImg != tapImg ||
        old.imgSize != imgSize ||
        old.color != color ||
        old.radius != radius;
  }
}

class _XMarkerPainter extends CustomPainter {
  final Size imgSize;
  final double x, y; // in image pixels
  final Color color;
  final double size;   // arm half-length in display px
  final double stroke;
  _XMarkerPainter({
    required this.imgSize,
    required this.x,
    required this.y,
    this.color = const Color(0xFF00B0FF),
    this.size = 14,
    this.stroke = 3,
  });

  @override
  void paint(Canvas canvas, Size sizePx) {
    final map = _fitContain(imgSize, sizePx);
    final nx = x / imgSize.width;
    final ny = y / imgSize.height;
    final px = map.offX + nx * map.drawW;
    final py = map.offY + ny * map.drawH;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withOpacity(0.95)
      ..strokeCap = StrokeCap.round;

    final a = Offset(px - size, py - size);
    final b = Offset(px + size, py + size);
    final c = Offset(px - size, py + size);
    final d = Offset(px + size, py - size);
    canvas.drawLine(a, b, p);
    canvas.drawLine(c, d, p);
  }

  @override
  bool shouldRepaint(covariant _XMarkerPainter old) {
    return old.x != x ||
        old.y != y ||
        old.imgSize != imgSize ||
        old.color != color ||
        old.size != size ||
        old.stroke != stroke;
  }
}

class _FitMap {
  final double drawW, drawH, offX, offY;
  _FitMap(this.drawW, this.drawH, this.offX, this.offY);
}

_FitMap _fitContain(Size imgSize, Size box) {
  final imgAspect = imgSize.width / imgSize.height;
  final boxAspect = box.width / box.height;
  late double drawW, drawH, offX, offY;
  if (imgAspect > boxAspect) {
    drawW = box.width;
    drawH = drawW / imgAspect;
    offX = 0;
    offY = (box.height - drawH) / 2;
  } else {
    drawH = box.height;
    drawW = drawH * imgAspect;
    offY = 0;
    offX = (box.width - drawW) / 2;
  }
  return _FitMap(drawW, drawH, offX, offY);
}
