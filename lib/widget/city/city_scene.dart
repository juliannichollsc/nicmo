import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/il8n/app_localizations.dart';

/// Scene shown for [cities]: the one city's own scene, or Colombia when
/// several (or none) are chosen.
String citySceneId(List<City> cities) =>
    cities.length == 1 && _scenes.containsKey(cities.single.id)
    ? cities.single.id
    : 'colombia';

/// Animated postcard of the chosen city with its best-known nickname
/// (Medellín: the eternal spring), cross-fading when the choice changes.
class CityScene extends StatelessWidget {
  final List<City> cities;
  final double height;

  /// Times the ambient loop plays before resting; null loops forever.
  final int? loops;

  const CityScene({
    super.key,
    required this.cities,
    this.height = 120,
    this.loops,
  });

  @override
  Widget build(BuildContext context) {
    final id = citySceneId(cities);
    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _SceneView(key: ValueKey(id), id: id, loops: loops),
      ),
    );
  }
}

typedef _SceneFactory = CustomPainter Function(_Clock clock);

const Map<String, _SceneFactory> _scenes = {
  'medellin': _MedellinScene.new,
  'bogota': _BogotaScene.new,
  'cali': _CaliScene.new,
  'barranquilla': _BarranquillaScene.new,
  'cartagena': _CartagenaScene.new,
  'bucaramanga': _BucaramangaScene.new,
  'pereira': _PereiraScene.new,
  'colombia': _ColombiaScene.new,
};

String _caption(AppLocalizations l10n, String id) => switch (id) {
  'medellin' => l10n.citySceneMedellin,
  'bogota' => l10n.citySceneBogota,
  'cali' => l10n.citySceneCali,
  'barranquilla' => l10n.citySceneBarranquilla,
  'cartagena' => l10n.citySceneCartagena,
  'bucaramanga' => l10n.citySceneBucaramanga,
  'pereira' => l10n.cityScenePereira,
  _ => l10n.citySceneColombia,
};

class _SceneView extends StatefulWidget {
  final String id;
  final int? loops;

  const _SceneView({super.key, required this.id, this.loops});

  @override
  State<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<_SceneView> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _Clock _clock = _Clock(_loop, _intro);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      // A still frame with everything in bloom.
      _loop.value = 0.3;
      _intro.value = 1;
    } else {
      _intro.forward();
      _loop.repeat(count: widget.loops);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _scenes[widget.id]!(_clock)),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: DecoratedBox(
              // Keeps the caption readable over any scene.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x8A000000)],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    _caption(l10n, widget.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: [Shadow(blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Times shared by every scene: [t] loops 0→1 (anything driven by
/// whole turns of it is seamless) and [intro] eases in once.
class _Clock extends ChangeNotifier {
  final Animation<double> loop;
  final Animation<double> intro;

  _Clock(this.loop, this.intro) {
    loop.addListener(notifyListeners);
    intro.addListener(notifyListeners);
  }

  double get t => loop.value;
  double get turn => loop.value * 2 * math.pi;

  /// Entrance of the [i]-th of [n] elements, one after the other.
  double stagger(int i, int n) => Curves.easeOutBack.transform(
    ((intro.value * (n + 2) - i) / 3).clamp(0.0, 1.0),
  );

  @override
  void dispose() {
    loop.removeListener(notifyListeners);
    intro.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Deterministic "random" values so the scene looks the same every time.
List<List<double>> _seeds(int count, int seed, int fields) {
  final random = math.Random(seed);
  return List.generate(
    count,
    (_) => List.generate(fields, (_) => random.nextDouble()),
  );
}

abstract class _Scene extends CustomPainter {
  final _Clock clock;

  _Scene(this.clock) : super(repaint: clock);

  @override
  bool shouldRepaint(covariant _Scene old) => old.clock != clock;

  void sky(Canvas canvas, Size size, List<Color> colors) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
  }

  /// Rolling hills whose crest sits around [base] (fraction of height).
  Path hills(
    Size size,
    double base,
    double amplitude,
    double phase, {
    double waves = 1.5,
  }) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      final u = x / size.width;
      final y =
          size.height * base -
          size.height *
              amplitude *
              (0.6 * math.sin(u * math.pi * 2 * waves + phase) +
                  0.4 * math.sin(u * math.pi * 5.3 + phase * 2));
      path.lineTo(x, y);
    }
    return path
      ..lineTo(size.width, size.height)
      ..close();
  }

  void sun(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius * 1.8,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    final rays = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = clock.turn / 2 + i * math.pi / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * radius * 1.25,
        center + dir * radius * 1.6,
        rays,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
  }
}

/// Eternal spring: flowers of the Feria de las Flores bloom in the valley
/// while petals drift past and a Metrocable cabin climbs the hillside.
class _MedellinScene extends _Scene {
  _MedellinScene(super.clock);

  static final _petals = _seeds(16, 11, 4);
  static const _flowerColors = [
    Color(0xFFE91E63),
    Color(0xFFFFB300),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFFF06292),
    Color(0xFFFFCA28),
    Color(0xFFEF5350),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [Color(0xFF8ED6F5), Color(0xFFFFF4C9)]);
    sun(canvas, Offset(w * 0.84, h * 0.26), h * 0.11, const Color(0xFFFFD54F));
    canvas.drawPath(
      hills(size, 0.55, 0.12, 0.6),
      Paint()..color = const Color(0xFF8CC57E),
    );

    // Metrocable: a sagging cable and a cabin going up and back.
    final a = Offset(-10, h * 0.62), b = Offset(w * 0.62, h * 0.18);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + h * 0.08);
    final cable = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    canvas.drawPath(
      cable,
      Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final u = 0.15 + 0.7 * (0.5 - 0.5 * math.cos(clock.turn));
    final metric = cable.computeMetrics().first;
    final hook = metric.getTangentForOffset(metric.length * u)!.position;
    final cabinPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawLine(
      hook,
      hook + Offset(0, h * 0.06),
      cabinPaint..strokeWidth = 1.5,
    );
    final cabin = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: hook + Offset(0, h * 0.11),
        width: h * 0.11,
        height: h * 0.1,
      ),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(cabin, Paint()..color = Colors.white);
    canvas.drawRRect(
      cabin.deflate(h * 0.018),
      Paint()..color = const Color(0xFF6CC8F2),
    );

    canvas.drawPath(
      hills(size, 0.8, 0.07, 2.1, waves: 1),
      Paint()..color = const Color(0xFF41822B),
    );

    // Flowers rising one after the other, swaying in the breeze.
    const count = 7;
    for (var i = 0; i < count; i++) {
      final grow = clock.stagger(i, count);
      if (grow <= 0) continue;
      final x = w * (0.06 + i * 0.148);
      final top = h * (0.62 + 0.08 * ((i * 37) % 5) / 5);
      final sway = 0.08 * math.sin(clock.turn + i * 1.3);
      canvas.save();
      canvas.translate(x, h);
      canvas.rotate(sway);
      final stemTop = Offset(0, -(h - top) * grow.clamp(0.0, 1.0));
      canvas.drawLine(
        Offset.zero,
        stemTop,
        Paint()
          ..color = const Color(0xFF2D5D1D)
          ..strokeWidth = 2,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: stemTop * 0.45 + const Offset(5, 0),
          width: 10,
          height: 5,
        ),
        Paint()..color = const Color(0xFF2D5D1D),
      );
      _flower(
        canvas,
        stemTop,
        h * 0.075 * grow,
        _flowerColors[i % _flowerColors.length],
        clock.turn * (i.isEven ? 1 : -1) / 4,
      );
      canvas.restore();
    }

    // Petals carried by the wind (whole turns of t: the loop is seamless).
    for (final p in _petals) {
      final x = ((p[0] + clock.t) % 1) * (w + 40) - 20;
      final y = ((p[1] + clock.t) % 1) * (h + 20) - 10;
      final wobble = math.sin(clock.turn * 2 + p[2] * 6) * 6;
      canvas.save();
      canvas.translate(x + wobble, y);
      canvas.rotate(clock.turn * 2 + p[3] * 6);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
        Paint()
          ..color = _flowerColors[(p[2] * _flowerColors.length).floor()]
              .withValues(alpha: 0.85),
      );
      canvas.restore();
    }
  }

  void _flower(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double spin,
  ) {
    if (radius <= 0) return;
    final petal = Paint()..color = color;
    for (var k = 0; k < 6; k++) {
      final a = spin + k * math.pi / 3;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(radius * 0.6, 0),
          width: radius * 1.1,
          height: radius * 0.6,
        ),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      radius * 0.35,
      Paint()..color = const Color(0xFFFFF176),
    );
  }
}

/// 2,600 m closer to the stars: dusk over Monserrate and its sanctuary,
/// twinkling stars and the lights of the city.
class _BogotaScene extends _Scene {
  _BogotaScene(super.clock);

  static final _stars = _seeds(26, 23, 3);
  static final _buildings = _seeds(16, 5, 3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [
      Color(0xFF0D1B3E),
      Color(0xFF2B4C7E),
      Color(0xFFE7A977),
    ]);
    for (final s in _stars) {
      final glow = 0.5 + 0.5 * math.sin(clock.turn * 2 + s[2] * 6.3);
      canvas.drawCircle(
        Offset(s[0] * w, s[1] * h * 0.55),
        0.8 + s[2] * 1.4,
        Paint()..color = Colors.white.withValues(alpha: 0.3 + 0.7 * glow),
      );
    }

    // Monserrate with the sanctuary on top.
    final peak = Offset(w * 0.3, h * 0.3);
    final mountain = Path()
      ..moveTo(-w * 0.1, h)
      ..quadraticBezierTo(w * 0.12, h * 0.5, peak.dx, peak.dy)
      ..quadraticBezierTo(w * 0.5, h * 0.45, w * 0.75, h)
      ..close();
    canvas.drawPath(
      hills(size, 0.62, 0.08, 1.4),
      Paint()..color = const Color(0xFF2E4F4A),
    );
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF1E3A34));
    final church = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawRect(Rect.fromLTWH(peak.dx - 7, peak.dy - 7, 14, 7), church);
    canvas.drawRect(Rect.fromLTWH(peak.dx - 2.5, peak.dy - 15, 5, 9), church);
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx - 9, peak.dy - 7)
        ..lineTo(peak.dx, peak.dy - 11)
        ..lineTo(peak.dx + 9, peak.dy - 7)
        ..close(),
      church,
    );

    // Skyline with windows lighting up, and a tower changing colour.
    var x = 0.0;
    final ink = Paint()..color = const Color(0xFF13213F);
    for (var i = 0; x < w; i++) {
      final b = _buildings[i % _buildings.length];
      final bw = w * (0.05 + b[0] * 0.05);
      final bh = h * (0.12 + b[1] * 0.2) + (i == 9 ? h * 0.22 : 0);
      final rect = Rect.fromLTWH(x, h - bh, bw - 2, bh);
      canvas.drawRect(rect, ink);
      if (i == 9) {
        final hue = (clock.t * 360) % 360;
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, 4),
          Paint()..color = HSVColor.fromAHSV(1, hue, 0.7, 1).toColor(),
        );
      }
      for (var wy = rect.top + 6; wy < h - 4; wy += 7) {
        for (var wx = rect.left + 3; wx < rect.right - 3; wx += 6) {
          final on = math.sin(wx * 0.37 + wy * 0.91 + clock.turn + b[2] * 9);
          if (on > 0.2) {
            canvas.drawRect(
              Rect.fromLTWH(wx, wy, 2.4, 2.6),
              Paint()..color = const Color(0xFFFFD180).withValues(alpha: on),
            );
          }
        }
      }
      x += bw;
    }
  }
}

/// World capital of salsa: sunset behind Cristo Rey, swaying palms and
/// music notes floating up.
class _CaliScene extends _Scene {
  _CaliScene(super.clock);

  static final _notes = _seeds(8, 31, 3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [
      Color(0xFFEC6A9C),
      Color(0xFFFFB74D),
      Color(0xFFFFE0B2),
    ]);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.72),
      h * 0.3,
      Paint()..color = const Color(0xFFFFF176).withValues(alpha: 0.85),
    );
    canvas.drawPath(
      hills(size, 0.7, 0.12, 0.3),
      Paint()..color = const Color(0xFF8E5A7A),
    );

    // Cristo Rey on the hill to the right.
    final base = Offset(w * 0.8, h * 0.5);
    final hill = Path()
      ..moveTo(w * 0.55, h)
      ..quadraticBezierTo(base.dx - w * 0.1, base.dy, base.dx, base.dy)
      ..quadraticBezierTo(base.dx + w * 0.12, base.dy, w * 1.05, h)
      ..close();
    final dark = Paint()..color = const Color(0xFF4A2B3F);
    canvas.drawPath(hill, dark);
    canvas.drawRect(Rect.fromLTWH(base.dx - 2.5, base.dy - 26, 5, 26), dark);
    canvas.drawRect(Rect.fromLTWH(base.dx - 11, base.dy - 20, 22, 4), dark);
    canvas.drawCircle(Offset(base.dx, base.dy - 29), 3.5, dark);

    _palm(canvas, Offset(w * 0.1, h), h * 0.75, 0);
    _palm(canvas, Offset(w * 0.24, h), h * 0.55, 1.7);

    for (final n in _notes) {
      final rise = (n[0] + clock.t) % 1;
      final x = w * (0.3 + n[1] * 0.45) + math.sin(rise * 9 + n[2] * 6) * 8;
      final y = h * (1.05 - rise * 1.1);
      final alpha = math.sin(rise * math.pi).clamp(0.0, 1.0);
      _note(canvas, Offset(x, y), h * 0.05, alpha, n[2] > 0.5);
    }
  }

  void _palm(Canvas canvas, Offset foot, double height, double phase) {
    final sway = math.sin(clock.turn + phase) * height * 0.04;
    final top = foot + Offset(height * 0.15 + sway, -height);
    final paint = Paint()
      ..color = const Color(0xFF3E2235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy)
        ..quadraticBezierTo(foot.dx, top.dy + height * 0.4, top.dx, top.dy),
      paint,
    );
    paint.strokeWidth = 3;
    for (var k = 0; k < 6; k++) {
      final a = -math.pi / 2 + (k - 2.5) * 0.55 + sway * 0.02;
      final tip = top + Offset(math.cos(a), math.sin(a) + 0.9) * height * 0.28;
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + math.cos(a) * height * 0.2,
            top.dy + math.sin(a) * height * 0.2,
            tip.dx,
            tip.dy,
          ),
        paint,
      );
    }
  }

  void _note(Canvas canvas, Offset at, double s, double alpha, bool beamed) {
    final paint = Paint()
      ..color = const Color(0xFF5D1F47).withValues(alpha: alpha)
      ..strokeWidth = 1.8;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 1.2, height: s * 0.85),
      paint,
    );
    canvas.drawLine(Offset(s * 0.55, 0), Offset(s * 0.55, -s * 2.2), paint);
    if (beamed) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 1.6, s * 0.2),
          width: s * 1.2,
          height: s * 0.85,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(s * 2.15, s * 0.2),
        Offset(s * 2.15, -s * 2),
        paint,
      );
      canvas.drawLine(
        Offset(s * 0.55, -s * 2.2),
        Offset(s * 2.15, -s * 2),
        paint..strokeWidth = 3,
      );
    } else {
      canvas.drawLine(
        Offset(s * 0.55, -s * 2.2),
        Offset(s * 1.3, -s * 1.5),
        paint,
      );
    }
    canvas.restore();
  }
}

/// The Carnival: confetti and streamers over the Magdalena.
class _BarranquillaScene extends _Scene {
  _BarranquillaScene(super.clock);

  static final _confetti = _seeds(36, 41, 4);
  static const _colors = [
    Color(0xFFFFD600),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFF6D00),
    Color(0xFF8E24AA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [Color(0xFF29B6F6), Color(0xFFFFF59D)]);
    sun(canvas, Offset(w * 0.15, h * 0.28), h * 0.1, const Color(0xFFFFEB3B));

    // River waves.
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 4) {
        path.lineTo(
          x,
          h * (0.78 + layer * 0.08) +
              math.sin(x / w * math.pi * 4 + clock.turn * (layer + 1)) * 3,
        );
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = layer == 0
              ? const Color(0xFF4FA3C7)
              : const Color(0xFF2F7FA8),
      );
    }

    // Streamers across the sky.
    for (var k = 0; k < 3; k++) {
      final path = Path();
      for (var x = -10.0; x <= w + 10; x += 4) {
        final y =
            h * (0.18 + k * 0.17) +
            math.sin(x / w * math.pi * 3 + clock.turn + k * 2) * h * 0.06;
        x == -10 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _colors[k * 2 % _colors.length].withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Tumbling confetti.
    for (final c in _confetti) {
      final fall = (c[0] + clock.t * (1 + (c[3] * 2).floor())) % 1;
      final x = c[1] * w + math.sin(fall * 12 + c[2] * 6) * 8;
      final y = fall * (h + 20) - 10;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fall * 12 + c[2] * 6);
      canvas.scale(1, math.cos(fall * 20 + c[3] * 6));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
        Paint()..color = _colors[(c[2] * _colors.length).floor()],
      );
      canvas.restore();
    }
  }
}

/// The walled city: colourful houses, the wall with its sentry box and a
/// sailboat on the Caribbean at sunset.
class _CartagenaScene extends _Scene {
  _CartagenaScene(super.clock);

  static const _houses = [
    Color(0xFFFFB300),
    Color(0xFFE57373),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [
      Color(0xFF5C6BC0),
      Color(0xFFFF8A65),
      Color(0xFFFFD54F),
    ]);
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.56),
      h * 0.16,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Caribbean with glints moving.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.58, w, h * 0.42),
      Paint()..color = const Color(0xFF1E6FB8),
    );
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final y = h * (0.62 + (i % 3) * 0.05);
      final x = ((i * 0.13 + clock.t) % 1) * (w + 30) - 15;
      canvas.drawLine(Offset(x, y), Offset(x + 12, y), glint);
    }

    // Sailboat crossing the bay, bobbing.
    final boatX = ((clock.t + 0.3) % 1) * (w + 60) - 30;
    final boatY = h * 0.66 + math.sin(clock.turn * 3) * 2;
    canvas.drawPath(
      Path()
        ..moveTo(boatX - 12, boatY)
        ..lineTo(boatX + 12, boatY)
        ..lineTo(boatX + 8, boatY + 5)
        ..lineTo(boatX - 8, boatY + 5)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawPath(
      Path()
        ..moveTo(boatX, boatY - 1)
        ..lineTo(boatX, boatY - 22)
        ..lineTo(boatX + 11, boatY - 3)
        ..close(),
      Paint()..color = Colors.white,
    );

    // Colourful colonial houses on the left, rising in turn.
    const count = 5;
    for (var i = 0; i < count; i++) {
      final grow = clock.stagger(i, count);
      final hw = w * 0.11;
      final hh = h * (0.28 + (i % 3) * 0.06) * grow.clamp(0.0, 1.2);
      final rect = Rect.fromLTWH(i * hw, h * 0.78 - hh, hw - 1, hh);
      canvas.drawRect(rect, Paint()..color = _houses[i % _houses.length]);
      if (grow > 0.9) {
        final balcony = Paint()..color = const Color(0xFF6D4C41);
        canvas.drawRect(
          Rect.fromLTWH(rect.left + 4, rect.top + 8, rect.width - 8, 3),
          balcony,
        );
        canvas.drawRect(
          Rect.fromLTWH(rect.center.dx - 3, rect.top + 13, 6, 8),
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      }
    }

    // The wall with crenellations and a sentry box.
    final stone = Paint()..color = const Color(0xFFC8A165);
    final wallTop = h * 0.78;
    canvas.drawRect(Rect.fromLTWH(0, wallTop, w, h - wallTop), stone);
    for (var x = 0.0; x < w; x += 14) {
      canvas.drawRect(Rect.fromLTWH(x, wallTop - 5, 8, 5), stone);
    }
    final box = Offset(w * 0.88, wallTop);
    canvas.drawRect(Rect.fromLTWH(box.dx - 7, box.dy - 18, 14, 18), stone);
    canvas.drawArc(
      Rect.fromCenter(center: box.translate(0, -18), width: 14, height: 12),
      math.pi,
      math.pi,
      true,
      stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(box.dx - 1.5, box.dy - 14, 3, 6),
      Paint()..color = const Color(0xFF6D4C41),
    );
  }
}

/// The city of parks: swaying trees, birds overhead and the famous
/// hormigas culonas marching across the grass.
class _BucaramangaScene extends _Scene {
  _BucaramangaScene(super.clock);

  static final _birds = _seeds(4, 53, 2);
  static final _ants = _seeds(6, 59, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [Color(0xFF81D4FA), Color(0xFFE1F5FE)]);
    sun(canvas, Offset(w * 0.86, h * 0.22), h * 0.09, const Color(0xFFFFD54F));
    // The plateau (the mesa) the city sits on.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..lineTo(w * 0.15, h * 0.45)
        ..lineTo(w * 0.7, h * 0.43)
        ..lineTo(w * 0.85, h * 0.6)
        ..lineTo(w, h * 0.62)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF9FB3A8),
    );
    final ground = h * 0.8;
    canvas.drawRect(
      Rect.fromLTWH(0, ground, w, h - ground),
      Paint()..color = const Color(0xFF66BB6A),
    );

    const count = 5;
    for (var i = 0; i < count; i++) {
      final grow = clock.stagger(i, count);
      if (grow <= 0) continue;
      final x = w * (0.1 + i * 0.2);
      final th = h * (0.25 + (i % 2) * 0.08) * grow;
      final sway = math.sin(clock.turn + i) * 3;
      canvas.drawLine(
        Offset(x, ground + 2),
        Offset(x + sway * 0.5, ground - th),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 3,
      );
      final crown = Offset(x + sway, ground - th);
      final r = h * 0.09 * grow;
      for (final (d, c) in [
        (const Offset(-0.7, 0.2), const Color(0xFF2E7D32)),
        (const Offset(0.7, 0.2), const Color(0xFF388E3C)),
        (const Offset(0, -0.4), const Color(0xFF43A047)),
      ]) {
        canvas.drawCircle(crown + d * r, r, Paint()..color = c);
      }
    }

    final wing = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final b in _birds) {
      final x = ((b[0] + clock.t) % 1) * (w + 30) - 15;
      final y = h * (0.12 + b[1] * 0.2);
      final flap = math.sin(clock.turn * 6 + b[0] * 6) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(x - 7, y - flap)
          ..quadraticBezierTo(x - 3, y - 3, x, y)
          ..quadraticBezierTo(x + 3, y - 3, x + 7, y - flap),
        wing,
      );
    }

    final ant = Paint()..color = const Color(0xFF4E2A1E);
    for (final a in _ants) {
      final x = ((a[0] + clock.t) % 1) * (w + 20) - 10;
      final y = h * 0.93 + math.sin(clock.turn * 10 + a[0] * 9);
      canvas.drawCircle(Offset(x - 5, y), 3, ant);
      canvas.drawCircle(Offset(x, y), 2, ant);
      canvas.drawCircle(Offset(x + 3.5, y - 0.5), 1.8, ant);
    }
  }
}

/// The Coffee Region: plantation hills, ripe red cherries and a steaming
/// cup of coffee.
class _PereiraScene extends _Scene {
  _PereiraScene(super.clock);

  static final _bushes = _seeds(7, 67, 2);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    sky(canvas, size, const [Color(0xFFB3E5FC), Color(0xFFFFF8E1)]);
    sun(canvas, Offset(w * 0.18, h * 0.24), h * 0.09, const Color(0xFFFFCA28));

    for (final (base, amp, phase, color) in [
      (0.5, 0.1, 0.4, const Color(0xFF9CCC65)),
      (0.68, 0.1, 2.2, const Color(0xFF689F38)),
    ]) {
      final hill = hills(size, base, amp, phase);
      canvas.drawPath(hill, Paint()..color = color);
      // Rows of coffee plants following the slope.
      canvas.save();
      canvas.clipPath(hill);
      final rows = Paint()
        ..color = const Color(0xFF33691E).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var k = 0; k < 8; k++) {
        canvas.drawPath(
          hills(size, base + 0.06 + k * 0.07, amp * 0.8, phase),
          rows,
        );
      }
      canvas.restore();
    }

    // Coffee bushes in front, cherries ripening as the scene opens.
    for (var i = 0; i < _bushes.length; i++) {
      final b = _bushes[i];
      final c = Offset(w * (0.04 + i * 0.1), h * (0.88 + b[0] * 0.05));
      canvas.drawCircle(c, h * 0.1, Paint()..color = const Color(0xFF2E5D1D));
      final ripe = clock.stagger(i, _bushes.length);
      for (var k = 0; k < 4; k++) {
        final a = b[1] * 6 + k * 1.6;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * h * 0.055,
          2.6 * ripe,
          Paint()..color = const Color(0xFFC62828),
        );
      }
    }

    // A cup of coffee with steam curling up.
    final cup = Offset(w * 0.84, h * 0.84);
    final s = h * 0.13;
    canvas.drawOval(
      Rect.fromCenter(
        center: cup + Offset(0, s * 0.95),
        width: s * 2.6,
        height: s * 0.5,
      ),
      Paint()..color = Colors.white,
    );
    final body = Path()
      ..moveTo(cup.dx - s, cup.dy - s * 0.4)
      ..lineTo(cup.dx + s, cup.dy - s * 0.4)
      ..quadraticBezierTo(
        cup.dx + s,
        cup.dy + s * 0.9,
        cup.dx,
        cup.dy + s * 0.9,
      )
      ..quadraticBezierTo(
        cup.dx - s,
        cup.dy + s * 0.9,
        cup.dx - s,
        cup.dy - s * 0.4,
      )
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawCircle(
      cup + Offset(s * 1.1, s * 0.1),
      s * 0.32,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: cup + Offset(0, -s * 0.4),
        width: s * 2,
        height: s * 0.4,
      ),
      Paint()..color = const Color(0xFF4E342E),
    );
    for (var k = 0; k < 3; k++) {
      final rise = (clock.t + k / 3) % 1;
      final path = Path();
      for (var j = 0; j <= 12; j++) {
        final v = j / 12;
        final p = Offset(
          cup.dx + (k - 1) * s * 0.5 + math.sin(v * 6 + rise * 2 * math.pi) * 3,
          cup.dy - s * 0.6 - v * s * 1.6 - rise * s * 0.6,
        );
        j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.7 * math.sin(rise * math.pi),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

/// Several cities: the flag of Colombia waving, with an Andean condor
/// gliding across it.
class _ColombiaScene extends _Scene {
  _ColombiaScene(super.clock);

  static const _yellow = Color(0xFFFCD116);
  static const _blue = Color(0xFF003893);
  static const _red = Color(0xFFCE1126);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE3F2FD),
    );
    // The flag in narrow strips, each shifted and shaded by the wave.
    const step = 3.0;
    final reveal = Curves.easeOutCubic.transform(clock.intro.value);
    for (var x = 0.0; x < w * reveal; x += step) {
      final phase = x / w * math.pi * 3 - clock.turn;
      final dy = math.sin(phase) * h * 0.05;
      final shade = math.cos(phase) * 0.12;
      Color lit(Color c) =>
          Color.lerp(c, shade > 0 ? Colors.white : Colors.black, shade.abs())!;
      final top = h * 0.06 + dy, height = h * 0.88;
      for (final (from, to, c) in [
        (0.0, 0.5, _yellow),
        (0.5, 0.75, _blue),
        (0.75, 1.0, _red),
      ]) {
        canvas.drawRect(
          Rect.fromLTRB(
            x,
            top + height * from,
            x + step + 0.6,
            top + height * to,
          ),
          Paint()..color = lit(c),
        );
      }
    }

    // Condor gliding across, wings flexing slightly.
    final x = ((clock.t + 0.2) % 1) * (w + 80) - 40;
    final y = h * 0.3 + math.sin(clock.turn * 2) * 5;
    final flex = math.sin(clock.turn * 4) * 3;
    final span = h * 0.32;
    final condor = Path()
      ..moveTo(x - span, y - 2 + flex)
      ..quadraticBezierTo(x - span * 0.5, y - 8 - flex, x - 4, y)
      ..lineTo(x, y - 4)
      ..lineTo(x + 4, y)
      ..quadraticBezierTo(x + span * 0.5, y - 8 - flex, x + span, y - 2 + flex)
      ..quadraticBezierTo(x + span * 0.5, y + 2, x + 3, y + 6)
      ..lineTo(x, y + 9)
      ..lineTo(x - 3, y + 6)
      ..quadraticBezierTo(x - span * 0.5, y + 2, x - span, y - 2 + flex)
      ..close();
    canvas.drawPath(condor, Paint()..color = const Color(0xFF212121));
    // The white collar of the condor.
    canvas.drawCircle(Offset(x, y - 3), 2.2, Paint()..color = Colors.white);
  }
}
