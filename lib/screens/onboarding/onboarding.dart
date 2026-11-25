import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/screens/legal/terms.dart';
import 'package:nicmo/state/onboarding_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/city/city_card.dart';
import 'package:nicmo/widget/city/city_scene.dart';
import 'package:nicmo/widget/shared/lightdark.dart';
import 'package:nicmo/widget/shared/nicmo_logo.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Three welcome slides shown once, before the map, and the choice of the
/// city the user gets around (only its map and routes are kept).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _count = 4;
  static const _cityPage = _count - 1;
  final PageController _pages = PageController();
  double _position = 0;
  City? _city =
      cityController.current ?? cityController.catalog.byId(kDefaultCityId);

  int get _index => _position.round();
  bool get _onCityPage => _index == _cityPage;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() => setState(() => _position = _pages.page ?? 0));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final city = _city;
    if (city == null) return;
    await cityController.choose(city);
    await OnboardingState.markSeen();
    // No account to create: the map comes right after.
    if (mounted) context.go('/home');
  }

  /// "Skip" jumps over the slides, not over the choice of city.
  void _skip() => _pages.animateToPage(
    _cityPage,
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeInOutCubicEmphasized,
  );

  void _next() {
    if (_onCityPage) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final slides = [
      (l10n.onboardingTitle1, l10n.onboardingBody1),
      (l10n.onboardingTitle2, l10n.onboardingBody2),
      (l10n.onboardingTitle3, l10n.onboardingBody3),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeBackground(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    NicmoWordmark(height: 32, color: textColor),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _onCityPage ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: TextButton(
                        onPressed: _onCityPage ? null : _skip,
                        child: Text(
                          l10n.skip,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _count,
                  itemBuilder: (context, i) {
                    // -1..1 while swiping: drives parallax and fades.
                    final delta = (i - _position).clamp(-1.0, 1.0);
                    if (i == _cityPage) {
                      return _CityStep(
                        delta: delta,
                        active: i == _index,
                        selected: _city,
                        textColor: textColor,
                        onSelect: (city) => setState(() => _city = city),
                      );
                    }
                    return _Slide(
                      delta: delta,
                      active: i == _index,
                      title: slides[i].$1,
                      body: slides[i].$2,
                      textColor: textColor,
                      illustration: switch (i) {
                        0 => _SearchIllustration(active: i == _index),
                        1 => _CombineIllustration(active: i == _index),
                        _ => _TravelIllustration(active: i == _index),
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    for (var i = 0; i < _count; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? MetroPalette.green
                              : textColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      // The last step needs a city.
                      onPressed: _onCityPage && _city == null ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MetroPalette.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: textColor.withValues(
                          alpha: 0.12,
                        ),
                        disabledForegroundColor: textColor.withValues(
                          alpha: 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        ),
                        child: Row(
                          key: ValueKey(_index == _count - 1),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _index == _count - 1
                                  ? l10n.getStarted
                                  : l10n.next,
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last step: which city the user gets around. Cards rise in one after
/// the other each time the page is reached; available cities come first.
class _CityStep extends StatelessWidget {
  final double delta;
  final bool active;
  final City? selected;
  final Color textColor;
  final ValueChanged<City> onSelect;

  const _CityStep({
    required this.delta,
    required this.active,
    required this.selected,
    required this.textColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fade = (1 - delta.abs()).clamp(0.0, 1.0);
    final cities = [
      for (final c in cityController.catalog.cities)
        if (kMultiCityEnabled || c.id == kDefaultCityId) c,
    ]..sort((a, b) => a.available == b.available ? 0 : (a.available ? -1 : 1));
    return Transform.translate(
      offset: Offset(delta * 40, 0),
      child: Opacity(
        opacity: fade,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
              child: Column(
                children: [
                  // The chosen city's postcard (Medellín: eternal spring).
                  CityScene(cities: [?selected], height: 112),
                  const SizedBox(height: 14),
                  Text(
                    l10n.cityPickTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kMultiCityEnabled
                        ? l10n.cityPickBody
                        : l10n.cityPickBodySingle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ShaderMask(
                // Cards fade out under the edges instead of being cut.
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0, 0.04, 0.92, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: ListView.separated(
                  // A new key on arrival replays the entrance.
                  key: ValueKey(active),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: cities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => StaggeredEntrance(
                    index: i,
                    child: CityCard(
                      city: cities[i],
                      selected: cities[i].id == selected?.id,
                      onTap: () => onSelect(cities[i]),
                    ),
                  ),
                ),
              ),
            ),
            // Starting the app is accepting the terms (no sign-up any more).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TermsNotice(color: textColor),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: selected == null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.cityChooseFirst,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : (selected!.available
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey(selected!.id),
                            padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                            child: Text(
                              l10n.citySoonNote(selected!.name),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final double delta;
  final bool active;
  final String title;
  final String body;
  final Color textColor;
  final Widget illustration;

  const _Slide({
    required this.delta,
    required this.active,
    required this.title,
    required this.body,
    required this.textColor,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final fade = 1 - delta.abs();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          // The picture lags behind the page (parallax) and shrinks a bit.
          Transform.translate(
            offset: Offset(delta * 90, 0),
            child: Transform.scale(
              scale: 0.86 + 0.14 * fade,
              child: Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: SizedBox(height: 300, child: illustration),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Transform.translate(
            offset: Offset(delta * 40, 24 * (1 - fade)),
            child: Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 15.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Loops an animation while its slide is visible, restarting on entry.
mixin _LoopWhileActive<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController loop;

  Duration get loopDuration;
  bool get isActive;

  @override
  void initState() {
    super.initState();
    loop = AnimationController(vsync: this, duration: loopDuration);
    if (isActive) loop.repeat();
  }

  void syncActive(bool wasActive) {
    if (isActive && !wasActive) {
      loop
        ..value = 0
        ..repeat();
    } else if (!isActive && wasActive) {
      loop.stop();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Card used as the frame of every illustration.
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? MetroPalette.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: MetroPalette.green.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 1: type an address, pins A and B drop, a route joins them.
// ---------------------------------------------------------------------------

class _SearchIllustration extends StatefulWidget {
  final bool active;

  const _SearchIllustration({required this.active});

  @override
  State<_SearchIllustration> createState() => _SearchIllustrationState();
}

class _SearchIllustrationState extends State<_SearchIllustration>
    with SingleTickerProviderStateMixin, _LoopWhileActive {
  // An example address in Medellín's nomenclature.
  static const _address = 'Cra. 43B # 1A Sur - 70';

  @override
  Duration get loopDuration => const Duration(milliseconds: 4600);

  @override
  bool get isActive => widget.active;

  @override
  void didUpdateWidget(_SearchIllustration old) {
    super.didUpdateWidget(old);
    syncActive(old.active);
  }

  static double _phase(
    double t,
    double from,
    double to, [
    Curve c = Curves.linear,
  ]) => c.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final t = loop.value;
          final typed = (_address.length * _phase(t, 0.02, 0.32)).round();
          final pinA = _phase(t, 0.34, 0.46, Curves.bounceOut);
          final pinB = _phase(t, 0.46, 0.58, Curves.bounceOut);
          final route = _phase(t, 0.58, 0.82, Curves.easeInOutCubic);
          final out = 1 - _phase(t, 0.93, 1.0); // fade before looping
          return LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              final a = Offset(w * 0.24, h * 0.78);
              final b = Offset(w * 0.76, h * 0.42);
              return Opacity(
                opacity: out,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StreetsPainter(isDark: isDark),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedRoutePainter(
                          from: a,
                          to: b,
                          progress: route,
                        ),
                      ),
                    ),
                    _Pin(
                      at: a,
                      drop: pinA,
                      letter: 'A',
                      color: MetroPalette.greenDeep,
                    ),
                    _Pin(
                      at: b,
                      drop: pinB,
                      letter: 'B',
                      color: const Color(0xFFE0533D),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 16,
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? MetroPalette.surfaceHigh
                              : const Color(0xFFF2F7F0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: MetroPalette.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _address.substring(0, typed),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Blinking caret while typing.
                            Opacity(
                              opacity:
                                  typed < _address.length &&
                                      (t * 20).floor().isEven
                                  ? 1
                                  : 0,
                              child: Container(
                                width: 2,
                                height: 18,
                                color: MetroPalette.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  final bool isDark;

  const _StreetsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final street = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07)
      ..strokeWidth = 6;
    for (var x = -size.height; x < size.width; x += 46) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.5, 0),
        street,
      );
    }
    for (var y = 70.0; y < size.height; y += 52) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 30), street);
    }
    // River (the Medellín river crosses the valley).
    final river = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: isDark ? 0.25 : 0.35)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.55, size.height + 10)
        ..quadraticBezierTo(
          size.width * 0.4,
          size.height * 0.55,
          size.width * 0.62,
          70,
        ),
      river,
    );
  }

  @override
  bool shouldRepaint(_StreetsPainter old) => old.isDark != isDark;
}

class _DashedRoutePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  const _DashedRoutePainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final control = Offset((from.dx + to.dx) / 2 + 30, from.dy - 10);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    final paint = Paint()
      ..color = MetroPalette.green
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      final end = metric.length * progress;
      for (var d = 0.0; d < end; d += 16) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 9, end)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoutePainter old) => old.progress != progress;
}

class _Pin extends StatelessWidget {
  final Offset at;
  final double drop;
  final String letter;
  final Color color;

  const _Pin({
    required this.at,
    required this.drop,
    required this.letter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (drop <= 0) return const SizedBox.shrink();
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 52 - 60 * (1 - drop),
      child: Opacity(
        opacity: drop.clamp(0.0, 1.0),
        child: SizedBox(
          width: 44,
          height: 52,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 52,
                color: color,
                shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
              ),
              Positioned(
                top: 10,
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 2: walk + bus + metro + Metrocable drawn segment by segment.
// ---------------------------------------------------------------------------

class _CombineIllustration extends StatefulWidget {
  final bool active;

  const _CombineIllustration({required this.active});

  @override
  State<_CombineIllustration> createState() => _CombineIllustrationState();
}

class _CombineIllustrationState extends State<_CombineIllustration>
    with SingleTickerProviderStateMixin, _LoopWhileActive {
  static const _segments = [
    (
      TransitMode.walk,
      MetroPalette.walk,
      Offset(0.10, 0.82),
      Offset(0.24, 0.66),
    ),
    (
      TransitMode.bus,
      Color(0xFF65BC4B),
      Offset(0.24, 0.66),
      Offset(0.44, 0.70),
    ),
    (
      TransitMode.metro,
      Color(0xFF215CA0),
      Offset(0.44, 0.70),
      Offset(0.62, 0.36),
    ),
    (
      TransitMode.cable,
      Color(0xFFB9CF47),
      Offset(0.62, 0.36),
      Offset(0.90, 0.18),
    ),
  ];

  @override
  Duration get loopDuration => const Duration(milliseconds: 4800);

  @override
  bool get isActive => widget.active;

  @override
  void didUpdateWidget(_CombineIllustration old) {
    super.didUpdateWidget(old);
    syncActive(old.active);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final t = loop.value;
          final draw = Curves.easeInOut.transform((t / 0.75).clamp(0.0, 1.0));
          final out = 1 - ((t - 0.93) / 0.07).clamp(0.0, 1.0);
          final minutes = (47 * draw).round();
          return LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              Offset at(Offset f) =>
                  Offset(f.dx * size.width, f.dy * size.height);
              return Opacity(
                opacity: out,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StreetsPainter(isDark: isDark),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SegmentsPainter(
                          segments: [
                            for (final s in _segments)
                              (
                                s.$2,
                                at(s.$3),
                                at(s.$4),
                                s.$1 == TransitMode.walk,
                              ),
                          ],
                          progress: draw,
                        ),
                      ),
                    ),
                    for (var i = 0; i < _segments.length; i++)
                      _ModeBubble(
                        at: Offset.lerp(
                          at(_segments[i].$3),
                          at(_segments[i].$4),
                          0.5,
                        )!,
                        mode: _segments[i].$1,
                        color: _segments[i].$2,
                        // Pops when its segment is half drawn.
                        appear: ((draw * _segments.length - i - 0.5) * 3).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: MetroPalette.green,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$minutes min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SegmentsPainter extends CustomPainter {
  final List<(Color, Offset, Offset, bool)> segments;
  final double progress;

  const _SegmentsPainter({required this.segments, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final perSegment = 1 / segments.length;
    for (var i = 0; i < segments.length; i++) {
      final (color, a, b, dotted) = segments[i];
      final local = ((progress - i * perSegment) / perSegment).clamp(0.0, 1.0);
      if (local <= 0) break;
      final end = Offset.lerp(a, b, local)!;
      final paint = Paint()
        ..color = color
        ..strokeWidth = dotted ? 5 : 9
        ..strokeCap = StrokeCap.round;
      if (dotted) {
        final length = (end - a).distance;
        for (var d = 0.0; d < length; d += 12) {
          canvas.drawCircle(Offset.lerp(a, end, d / length)!, 3, paint);
        }
      } else {
        canvas.drawLine(
          a,
          end,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(a, end, paint);
      }
      canvas.drawCircle(a, 7, Paint()..color = Colors.white);
      canvas.drawCircle(a, 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SegmentsPainter old) => old.progress != progress;
}

class _ModeBubble extends StatelessWidget {
  final Offset at;
  final TransitMode mode;
  final Color color;
  final double appear;

  const _ModeBubble({
    required this.at,
    required this.mode,
    required this.color,
    required this.appear,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Curves.elasticOut.transform(appear);
    return Positioned(
      left: at.dx - 20,
      top: at.dy - 50,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
          ),
          alignment: Alignment.center,
          child: ModeIcon(mode, size: 20, color: onLineColor(color)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 3: the metro arriving and the steps being checked off.
// ---------------------------------------------------------------------------

class _TravelIllustration extends StatefulWidget {
  final bool active;

  const _TravelIllustration({required this.active});

  @override
  State<_TravelIllustration> createState() => _TravelIllustrationState();
}

class _TravelIllustrationState extends State<_TravelIllustration>
    with SingleTickerProviderStateMixin, _LoopWhileActive {
  @override
  Duration get loopDuration => const Duration(milliseconds: 4200);

  @override
  bool get isActive => widget.active;

  @override
  void didUpdateWidget(_TravelIllustration old) {
    super.didUpdateWidget(old);
    syncActive(old.active);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (Icons.directions_walk_rounded, MetroPalette.walk, l10n.modeWalk),
      (Icons.subway_rounded, const Color(0xFF215CA0), l10n.lineName('A')),
      (Icons.local_taxi_rounded, MetroPalette.car, 'Uber'),
    ];
    return _Card(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: MetroPalette.night,
              child: widget.active
                  ? Lottie.asset(
                      'assets/animations/metro_train.json',
                      fit: BoxFit.cover,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: AnimatedBuilder(
              animation: loop,
              builder: (context, _) {
                final t = loop.value;
                return Row(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      if (i > 0)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: MetroPalette.walk.withValues(alpha: 0.8),
                        ),
                      Expanded(
                        child: _StepChip(
                          icon: steps[i].$1,
                          color: steps[i].$2,
                          label: steps[i].$3,
                          appear: ((t - i * 0.12) / 0.15).clamp(0.0, 1.0),
                          done: t > 0.45 + i * 0.15,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double appear;
  final bool done;

  const _StepChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.appear,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - appear)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: done ? MetroPalette.green : color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Icon(
                  done ? Icons.check_rounded : icon,
                  key: ValueKey(done),
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
