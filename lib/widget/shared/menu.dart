import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/ads/ads_service.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/map_filter_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/ads/sponsored_ad.dart';
import 'package:nicmo/widget/city/city_card.dart';
import 'package:nicmo/widget/shared/lightdark.dart';
import 'package:nicmo/widget/shared/nicmo_logo.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Side menu styled after the Metro de Medellín: green header with the
/// network drawn behind and the current city, travel / account sections and
/// the lines of the city, Metro and buses apart.
class MenuWidget extends StatelessWidget {
  const MenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // City and network change while the menu may be open (cities screen
    // pushed over it).
    return ListenableBuilder(
      listenable: Listenable.merge([cityController, tripController]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final location = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path;

    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    var index = 0;
    Widget item(IconData icon, String label, String path) {
      return _MenuItem(
        index: index++,
        icon: icon,
        label: label,
        selected: location == path,
        textColor: textColor,
        onTap: () => go(path),
      );
    }

    final city = cityController.current;
    final network = tripController.value.network;
    // Lines grouped by kind of transport: the full list (with search) is in
    // the lines view, the menu only offers the groups.
    final counts = <LineGroup, int>{
      for (final group in LineGroup.values)
        group:
            network?.lines.values
                .where((l) => l.group == group && l.drawable)
                .length ??
            0,
    }..removeWhere((_, count) => count == 0);

    return Drawer(
      backgroundColor: isDark ? MetroPalette.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _Header(
            // One region for now: the Valle de Aburrá.
            subtitle: kMultiCityEnabled && city != null
                ? l10n.moveAround(city.name)
                : l10n.menuSubtitle,
            city: city,
            // Pushed over the menu: the city badge flies to the cities
            // screen and back returns to the open menu.
            onCity: () => context.push('/cities'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              children: [
                _SectionTitle(l10n.menuSectionTravel, textColor),
                item(Icons.map_rounded, l10n.map, '/home'),
                item(Icons.route_rounded, l10n.linesTitle, '/lines'),
                if (kMultiCityEnabled)
                  _MenuItem(
                    index: index++,
                    icon: Icons.location_city_rounded,
                    label: l10n.citiesTitle,
                    selected: false,
                    textColor: textColor,
                    onTap: () => context.push('/cities'),
                  ),
                item(Icons.settings_rounded, l10n.settings, '/settings'),
                if (counts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: lineFilter,
                    builder: (context, line, _) =>
                        ValueListenableBuilder<LineGroup?>(
                          valueListenable: groupFilter,
                          builder: (context, group, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _SectionTitle(
                                      l10n.menuSectionLines,
                                      textColor,
                                    ),
                                  ),
                                  // Back to the whole network.
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) =>
                                        RotationTransition(
                                          turns: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        ),
                                    child: line == null && group == null
                                        ? const SizedBox(height: 40)
                                        : IconButton(
                                            tooltip: l10n.showAllLines,
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              color: MetroPalette.green,
                                            ),
                                            onPressed: () {
                                              lineFilter.value = null;
                                              groupFilter.value = null;
                                            },
                                          ),
                                  ),
                                ],
                              ),
                              for (final (i, entry)
                                  in counts.entries.indexed) ...[
                                // Metro (rail and cable) and buses apart.
                                if (i == 0 ||
                                    entry.key.isBus !=
                                        counts.keys.elementAt(i - 1).isBus)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      8,
                                      12,
                                      2,
                                    ),
                                    child: Text(
                                      familyLabel(l10n, entry.key.isBus),
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.7),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                _GroupRow(
                                  index: i,
                                  group: entry.key,
                                  count: entry.value,
                                  selected: line == null && group == entry.key,
                                  dimmed:
                                      (line != null || group != null) &&
                                      group != entry.key,
                                  textColor: textColor,
                                  onTap: () {
                                    lineFilter.value = null;
                                    groupFilter.value = entry.key;
                                    go('/home');
                                  },
                                ),
                              ],
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => go('/lines'),
                                  icon: const Icon(Icons.list_rounded),
                                  label: Text(l10n.seeAllLines),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SponsoredAd(placement: AdPlacement.menu),
          ),
          Divider(height: 1, color: textColor.withValues(alpha: 0.1)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isDark ? l10n.lightMode : l10n.darkModeMenu,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const LightDarkWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String subtitle;
  final City? city;
  final VoidCallback onCity;

  const _Header({
    required this.subtitle,
    required this.city,
    required this.onCity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MetroPalette.brand, MetroPalette.greenDeep],
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: CustomPaint(
        painter: const _NetworkPainter(),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(-16 * (1 - t), 0),
                  child: child,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NicmoWordmark(height: 44, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  if (kMultiCityEnabled && city != null) ...[
                    const SizedBox(height: 12),
                    _CityChip(city: city!, onTap: onCity),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Current city in the header; opens the cities screen.
class _CityChip extends StatelessWidget {
  final City city;
  final VoidCallback onTap;

  const _CityChip({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.changeCity,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: cityHeroTag(city),
                  child: CityBadge(city: city, size: 30),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.changeCity,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint lines A and B with stations behind the header.
class _NetworkPainter extends CustomPainter {
  const _NetworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final a = Path()
      ..moveTo(w * 0.78, -10)
      ..quadraticBezierTo(w * 0.86, h * 0.5, w * 0.72, h + 10);
    final b = Path()
      ..moveTo(w * 0.82, h * 0.45)
      ..quadraticBezierTo(w * 0.95, h * 0.55, w + 10, h * 0.4);
    canvas.drawPath(a, line);
    canvas.drawPath(b, line);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.3);
    for (final p in [
      Offset(w * 0.8, h * 0.18),
      Offset(w * 0.82, h * 0.45),
      Offset(w * 0.77, h * 0.78),
      Offset(w * 0.93, h * 0.5),
    ]) {
      canvas.drawCircle(p, 6, dot);
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color.withValues(alpha: 0.55),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? MetroPalette.green : textColor;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(-24 * (1 - t), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected
              ? MetroPalette.green.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Line-coloured rail marks the current screen.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 4,
                    height: 22,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: selected ? MetroPalette.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A kind of transport in the menu: tap to show only it on the map.
class _GroupRow extends StatelessWidget {
  final int index;
  final LineGroup group;
  final int count;
  final bool selected;
  final bool dimmed;
  final Color textColor;
  final VoidCallback onTap;

  const _GroupRow({
    required this.index,
    required this.group,
    required this.count,
    required this.selected,
    required this.dimmed,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = lineColor(groupColor(group), Theme.of(context).brightness);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(-24 * (1 - t), 0),
          child: child,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? 0.45 : 1,
        child: Material(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: groupIcon(
                      group,
                      size: 18,
                      color: onLineColor(color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      groupLabel(l10n, group),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
