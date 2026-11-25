import 'package:flutter/material.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/map_filter_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Map filter by kind of transport: a pill with an arrow that unfolds the
/// options (all, then the Metro groups and the bus groups of the city).
class TransportFilter extends StatefulWidget {
  final TransitNetwork? network;

  const TransportFilter({super.key, this.network});

  @override
  State<TransportFilter> createState() => _TransportFilterState();
}

class _TransportFilterState extends State<TransportFilter> {
  bool _open = false;

  void _choose(LineGroup? group) {
    lineFilter.value = null;
    groupFilter.value = group;
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return ValueListenableBuilder<String?>(
      valueListenable: lineFilter,
      builder: (context, lineId, _) => ValueListenableBuilder<LineGroup?>(
        valueListenable: groupFilter,
        builder: (context, group, _) {
          final line = widget.network?.lines[lineId];
          // Only the kinds of transport the city has.
          final present = {
            for (final l in widget.network?.lines.values ?? <TransitLine>[])
              if (l.drawable) l.group,
          };
          final groups = [
            for (final g in LineGroup.values)
              if (present.contains(g)) g,
          ];
          final Widget icon;
          final String label;
          if (line != null) {
            icon = groupIcon(
              line.group,
              size: 20,
              color: lineColor(line.color, brightness),
            );
            label = lineLabel(l10n, line);
          } else if (group != null) {
            icon = groupIcon(
              group,
              size: 20,
              color: lineColor(groupColor(group), brightness),
            );
            label = groupLabel(l10n, group);
          } else {
            icon = Icon(Icons.layers_rounded, size: 20, color: scheme.primary);
            label = l10n.allTransport;
          }
          return Material(
            elevation: 8,
            shadowColor: Colors.black45,
            color: isDark
                ? MetroPalette.surface.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _open = !_open),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_open) ...[
                    Divider(height: 1, color: scheme.outlineVariant),
                    _Option(
                      icon: Icon(
                        Icons.layers_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                      label: l10n.allTransport,
                      selected: line == null && group == null,
                      index: 0,
                      onTap: () => _choose(null),
                    ),
                    for (final (i, g) in groups.indexed) ...[
                      if (i == 0 || g.isBus != groups[i - 1].isBus)
                        _FamilyHeader(familyLabel(l10n, g.isBus)),
                      _Option(
                        icon: groupIcon(
                          g,
                          size: 20,
                          color: lineColor(groupColor(g), brightness),
                        ),
                        label: groupLabel(l10n, g),
                        selected: line == null && group == g,
                        index: i + 1,
                        onTap: () => _choose(g),
                      ),
                    ],
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -8 * (1 - t)),
          child: child,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Metro system" / "Buses" title between the options.
class _FamilyHeader extends StatelessWidget {
  final String text;

  const _FamilyHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
