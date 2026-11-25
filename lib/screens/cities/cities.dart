import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/location_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/city/city_card.dart';
import 'package:nicmo/widget/city/city_scene.dart';
import 'package:nicmo/widget/shared/lightdark.dart';

/// The cities of the user: the one on the map, the others they activated
/// (their map is kept offline) and the rest of the catalog, with a search.
/// Opened from the side menu so the menu itself never lists cities.
class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final TextEditingController _query = TextEditingController();

  /// Offline map size per city, refreshed after adding / removing one.
  final Map<String, Future<int>> _sizes = {};

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<int> _size(City city) =>
      _sizes[city.id] ??= OfflineVectorTiles.areaBytes(city.id);

  void _go(City city) {
    cityController.choose(city);
    context.go('/home');
  }

  Future<void> _add(City city) async {
    final l10n = AppLocalizations.of(context)!;
    await cityController.activate(city);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.cityAdded(city.name))));
  }

  Future<void> _remove(City city) async {
    final l10n = AppLocalizations.of(context)!;
    final size = formatBytes(await _size(city));
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: CityBadge(city: city, size: 44),
        title: Text(l10n.cityRemoveTitle(city.name)),
        content: Text(l10n.cityRemoveBody(city.name, size)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cityRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cityController.deactivate(city);
    _sizes.remove(city.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.cityRemoved(city.name))));
  }

  static String _normalize(String text) {
    var result = text.toLowerCase();
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  bool _matches(City city, String query) =>
      query.isEmpty ||
      [
        city.name,
        city.region,
        ...city.municipalities,
        ...city.systems,
      ].any((text) => _normalize(text).contains(query));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : MetroPalette.ink;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeBackground(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: ValueListenableBuilder<CitySelection>(
          valueListenable: cityController,
          builder: (context, selection, _) {
            final current = selection.current;
            final others = [
              for (final c in selection.active)
                if (c.id != current?.id) c,
            ];
            final query = _normalize(_query.text.trim());
            final more =
                [
                  for (final c in cityController.catalog.cities)
                    if (!selection.isActive(c) && _matches(c, query)) c,
                ]..sort(
                  (a, b) =>
                      a.available == b.available ? 0 : (a.available ? -1 : 1),
                );
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: textColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                  ),
                  title: Text(
                    l10n.citiesTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                // One active city shows its own scene; several, Colombia.
                // It plays a few times and rests (and lets tests settle).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: CityScene(cities: selection.active, loops: 3),
                  ),
                ),
                if (current != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _CurrentCityCard(
                        city: current,
                        size: _size(current),
                      ),
                    ),
                  ),
                if (others.isNotEmpty) ...[
                  _Section(l10n.cityActive, textColor),
                  SliverList.separated(
                    itemCount: others.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final city = others[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StaggeredEntrance(
                          key: ValueKey('active-${city.id}'),
                          index: i,
                          child: CityCard(
                            city: city,
                            onTap: () => _go(city),
                            footer: _CityFooter(city: city, size: _size(city)),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () => _go(city),
                                  child: Text(l10n.cityGo),
                                ),
                                IconButton(
                                  tooltip: l10n.cityRemove,
                                  onPressed: () => _remove(city),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                _Section(l10n.cityExplore, textColor),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.citySearch,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _query.clear,
                              ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                if (more.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.cityNoMatch,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: more.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final city = more[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StaggeredEntrance(
                          key: ValueKey('more-${city.id}'),
                          index: others.length + i,
                          child: CityCard(
                            city: city,
                            onTap: () => _go(city),
                            footer: _CityFooter(city: city),
                            trailing: OutlinedButton(
                              onPressed: () => _add(city),
                              child: Text(l10n.cityActivate),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.offline_pin_outlined,
                            size: 18,
                            color: textColor.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.cityKeepsOffline,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _Section extends StatelessWidget {
  final String title;
  final Color color;

  const _Section(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color.withValues(alpha: 0.55),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

/// "You are here" when the user is inside the city, and the size of its
/// offline map when known.
class _CityFooter extends StatelessWidget {
  final City city;
  final Future<int>? size;

  const _CityFooter({required this.city, this.size});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final here = locationController.value?.position;
    final isHere = here != null && city.bounds.contains(here);
    final parts = <Widget>[
      if (isHere)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.near_me_rounded,
              size: 14,
              color: Color(0xFF29B6F6),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.cityHere,
              style: const TextStyle(
                color: Color(0xFF29B6F6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      if (size != null)
        FutureBuilder<int>(
          future: size,
          builder: (context, snapshot) {
            final bytes = snapshot.data ?? 0;
            return Text(
              bytes > 0
                  ? l10n.cityOfflineMap(formatBytes(bytes))
                  : l10n.cityOfflineEmpty,
            );
          },
        ),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 2, children: parts);
  }
}

/// The city on the map: large card with its badge (it flies in from the
/// side menu), lines and offline map size.
class _CurrentCityCard extends StatelessWidget {
  final City city;
  final Future<int> size;

  const _CurrentCityCard({required this.city, required this.size});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = cityColor(city);
    final deep = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.18).clamp(0.0, 1.0),
        )
        .toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, deep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // White ring: the badge has the colour of the card.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Hero(
                    tag: cityHeroTag(city),
                    child: CityBadge(city: city, size: 60),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cityCurrent.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        city.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        city.region,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (city.available)
                  ValueListenableBuilder<TripState>(
                    valueListenable: tripController,
                    builder: (context, state, _) => _Stat(
                      icon: Icons.route_rounded,
                      text: state.network == null
                          ? '…'
                          : l10n.linesCount(state.network!.lines.length),
                    ),
                  )
                else
                  _Stat(icon: Icons.schedule_rounded, text: l10n.citySoon),
                FutureBuilder<int>(
                  future: size,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data ?? 0;
                    return _Stat(
                      icon: Icons.offline_pin_rounded,
                      text: bytes > 0
                          ? l10n.cityOfflineMap(formatBytes(bytes))
                          : l10n.cityOfflineEmpty,
                    );
                  },
                ),
              ],
            ),
            if (!city.available) ...[
              const SizedBox(height: 12),
              Text(
                l10n.citySoonNote(city.name),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Stat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "12.3 MB", "850 KB".
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}
