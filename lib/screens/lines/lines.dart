import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/map_filter_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Every line and route of the system, grouped by kind of transport, with a
/// search (by line, route, station, stop or neighbourhood). Choosing one
/// shows it on the map.
class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    tripController.ensureNetwork();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _show(TransitLine line) {
    groupFilter.value = null;
    lineFilter.value = line.id;
    context.go('/home');
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

  bool _matches(TransitNetwork network, TransitLine line, String query) {
    if (query.isEmpty) return true;
    final texts = [
      line.id,
      line.name,
      for (final id in line.stationIds) network.stations[id]?.name ?? '',
      for (final stop in line.stops) stop.name,
      ...line.municipalities,
    ];
    return texts.any((text) => _normalize(text).contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.linesTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ValueListenableBuilder<TripState>(
        valueListenable: tripController,
        builder: (context, state, _) {
          final network = state.network;
          if (network == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final query = _normalize(_query.text.trim());
          final groups = {
            for (final group in LineGroup.values)
              group: [
                for (final line in network.lines.values)
                  if (line.group == group &&
                      line.drawable &&
                      _matches(network, line, query))
                    line,
              ]..sort((a, b) => a.id.compareTo(b.id)),
          }..removeWhere((_, lines) => lines.isEmpty);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchLines,
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
              Expanded(
                child: groups.isEmpty
                    ? Center(child: Text(l10n.noLinesFound))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          for (final (i, entry) in groups.entries.indexed) ...[
                            // Metro (rail and cable) and buses apart.
                            if (i == 0 ||
                                entry.key.isBus !=
                                    groups.keys.elementAt(i - 1).isBus)
                              _FamilyTitle(familyLabel(l10n, entry.key.isBus)),
                            _GroupSection(
                              // Searching opens every section with results.
                              key: ValueKey('${entry.key}-${query.isEmpty}'),
                              group: entry.key,
                              lines: entry.value,
                              network: network,
                              // Street buses are many: folded until searched.
                              initiallyExpanded:
                                  query.isNotEmpty || !entry.key.isStreetBus,
                              onSelect: _show,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final LineGroup group;
  final List<TransitLine> lines;
  final TransitNetwork network;
  final bool initiallyExpanded;
  final ValueChanged<TransitLine> onSelect;

  const _GroupSection({
    super.key,
    required this.group,
    required this.lines,
    required this.network,
    required this.initiallyExpanded,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final color = lineColor(groupColor(group), brightness);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: const Border(),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: groupIcon(group, color: color),
      ),
      title: Text(
        groupLabel(l10n, group),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(l10n.linesCount(lines.length)),
      children: [
        if (group.isStreetBus)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              group == LineGroup.feeder
                  ? l10n.feederRoutesNote
                  : l10n.busRoutesNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final line in lines)
          _LineTile(line: line, network: network, onTap: () => onSelect(line)),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  final TransitLine line;
  final TransitNetwork network;
  final VoidCallback onTap;

  const _LineTile({
    required this.line,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = lineColor(line.color, Theme.of(context).brightness);
    final ends = [
      network.stations[line.stationIds.first]?.name,
      network.stations[line.stationIds.last]?.name,
    ].whereType<String>().join(' – ');
    final street = line.group.isStreetBus;
    // Bus names carry their code ("Ruta integrada C3-001 Santa Gema -
    // Aguacatala"): the code goes in the badge, the places in the title.
    final title = street
        ? line.name
              .replaceFirst(RegExp(r'^Ruta integrada\s*'), '')
              .replaceFirst(lineCode(line), '')
              .replaceFirst(RegExp(r'^[\s:]+'), '')
        : lineLabel(l10n, line);
    final stops = street && line.stops.isNotEmpty
        ? ' · ${l10n.stopsOnRoute(line.stops.length)}'
        : '';
    // Routes between municipalities: where they go matters more than the
    // terminal stations.
    final where = line.municipalities.length > 1
        ? line.municipalities.join(' · ')
        : null;
    return ListTile(
      onTap: onTap,
      leading: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          lineCode(line),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onLineColor(color),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        title.isEmpty ? lineLabel(l10n, line) : title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        where ?? '$ends$stops',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.map_outlined),
    );
  }
}

/// "Metro system" / "Buses" title between the groups.
class _FamilyTitle extends StatelessWidget {
  final String text;

  const _FamilyTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
