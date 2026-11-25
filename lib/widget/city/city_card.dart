import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/theme/metro_theme.dart';

/// Colour of a city's badge: a stable hue per city, kept in the Nicmo
/// saturation and lightness so every badge belongs to the same family.
Color cityColor(City city) {
  final hex = city.color;
  if (hex != null && hex.length == 7) {
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
  final hue = (city.id.codeUnits.fold<int>(7, (h, c) => h * 31 + c) % 360)
      .toDouble();
  return HSLColor.fromAHSL(1, hue, 0.5, 0.4).toColor();
}

/// Hero tag of the current city's badge (side menu ↔ cities screen).
String cityHeroTag(City city) => 'city-badge-${city.id}';

/// Square with the city's initials over a faint drawing of transit lines.
class CityBadge extends StatelessWidget {
  final City city;
  final double size;

  const CityBadge({super.key, required this.city, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final color = cityColor(city);
    final deep = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.14).clamp(0.0, 1.0),
        )
        .toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, deep],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: CustomPaint(
        painter: _BadgeLinesPainter(seed: city.id.hashCode),
        child: Center(
          child: Text(
            _initials(city.name),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length > 1) return words.take(2).map((w) => w[0]).join();
    return name.substring(0, math.min(2, name.length));
  }
}

class _BadgeLinesPainter extends CustomPainter {
  final int seed;

  const _BadgeLinesPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 2; i++) {
      final path = Path()
        ..moveTo(size.width * random.nextDouble(), -4)
        ..quadraticBezierTo(
          size.width * random.nextDouble(),
          size.height * 0.5,
          size.width * random.nextDouble(),
          size.height + 4,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BadgeLinesPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// "Routes available" / "Coming soon" pill.
class CityStatusPill extends StatelessWidget {
  final City city;

  const CityStatusPill({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = city.available
        ? (isDark ? MetroPalette.greenBright : MetroPalette.green)
        : (isDark ? const Color(0xFFFFCA6B) : const Color(0xFF8A5A00));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          // Large text sizes: shortened rather than overflowing.
          Flexible(
            child: Text(
              city.available ? l10n.cityAvailable : l10n.citySoon,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A city to choose: badge, name, region, systems and status. Selecting it
/// tints the card, thickens its border and pops a check in.
class CityCard extends StatefulWidget {
  final City city;
  final bool selected;
  final VoidCallback? onTap;

  /// Extra line under the systems (offline map size, "you are here").
  final Widget? footer;

  /// Action at the right (cities screen); a check is shown otherwise.
  final Widget? trailing;

  /// The badge flies from / to the side menu (one card per city on screen).
  final bool hero;

  const CityCard({
    super.key,
    required this.city,
    this.selected = false,
    this.onTap,
    this.footer,
    this.trailing,
    this.hero = false,
  });

  @override
  State<CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<CityCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : MetroPalette.ink;
    final accent = isDark ? MetroPalette.greenBright : MetroPalette.green;
    final selected = widget.selected;
    return Semantics(
      button: widget.onTap != null,
      selected: selected,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            // Opaque: the tint must not let the background show through.
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: isDark ? 0.16 : 0.08),
                    isDark ? MetroPalette.surface : Colors.white,
                  )
                : (isDark ? MetroPalette.surface : Colors.white),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : textColor.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: selected ? 0.14 : (isDark ? 0.2 : 0.06),
                ),
                blurRadius: selected ? 22 : 12,
                offset: Offset(0, selected ? 10 : 4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    widget.hero
                        ? Hero(
                            tag: cityHeroTag(city),
                            child: CityBadge(city: city),
                          )
                        : CityBadge(city: city),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The status goes under the name when both do
                          // not fit (narrow phones, long names).
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                city.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              CityStatusPill(city: city),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            city.region,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          if (city.systems.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              city.systems.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (widget.footer != null) ...[
                            const SizedBox(height: 6),
                            DefaultTextStyle.merge(
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                              child: widget.footer!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    widget.trailing ??
                        AnimatedScale(
                          scale: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 320),
                          curve: selected ? Curves.easeOutBack : Curves.easeIn,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accent,
                            size: 26,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child in after [index] steps (lists of cards).
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + 60 * math.min(index, 8)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
