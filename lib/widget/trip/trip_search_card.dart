import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address.dart';
import 'package:nicmo/state/location_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Origin / destination inputs with station + OpenStreetMap suggestions and
/// the "find best route" action that triggers planning.
class TripSearchCard extends StatefulWidget {
  final TripState state;
  final Future<void> Function() onUseMyLocation;

  const TripSearchCard({
    super.key,
    required this.state,
    required this.onUseMyLocation,
  });

  @override
  State<TripSearchCard> createState() => _TripSearchCardState();
}

class _TripSearchCardState extends State<TripSearchCard> {
  final _texts = {
    PlaceSlot.origin: TextEditingController(),
    PlaceSlot.destination: TextEditingController(),
  };
  final _focus = {
    PlaceSlot.origin: FocusNode(),
    PlaceSlot.destination: FocusNode(),
  };

  /// Last place written into each field. The text is only replaced when the
  /// place in the controller changes, never while the user is typing.
  final Map<PlaceSlot, Place?> _shown = {
    PlaceSlot.origin: null,
    PlaceSlot.destination: null,
  };

  Timer? _debounce;
  List<Place> _suggestions = const [];
  PlaceSlot? _activeSlot;
  bool _loading = false;
  bool _resolving = false;
  double _swapTurns = 0;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _syncFromState();
    for (final entry in _focus.entries) {
      entry.value.addListener(() => _onFocusChanged(entry.key));
    }
    for (final controller in _texts.values) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void didUpdateWidget(TripSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _texts.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Place? _placeOf(PlaceSlot slot) =>
      slot == PlaceSlot.origin ? widget.state.origin : widget.state.destination;

  void _syncFromState() {
    for (final slot in PlaceSlot.values) {
      final place = _placeOf(slot);
      if (!identical(place, _shown[slot])) {
        _shown[slot] = place;
        if (place != null) _texts[slot]!.text = place.name;
      }
    }
  }

  void _onFocusChanged(PlaceSlot slot) {
    if (_focus[slot]!.hasFocus) {
      setState(() {
        _activeSlot = slot;
        _suggestions = const [];
      });
      if (_texts[slot]!.text.trim().length >= 2 && _placeOf(slot) == null) {
        _onChanged(slot, _texts[slot]!.text);
      }
    } else if (_activeSlot == slot) {
      setState(() {
        _activeSlot = null;
        _suggestions = const [];
      });
    }
  }

  void _onChanged(PlaceSlot slot, String text) {
    // Editing the text invalidates the place previously chosen for the slot.
    if (_placeOf(slot) != null && _placeOf(slot)!.name != text) {
      _shown[slot] = null;
      tripController.setPlace(slot, null);
    }
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    // Nominatim allows ~1 request/second; debounce keystrokes.
    // Street addresses need several requests: wait for a longer pause so
    // half-typed numbers ("# 1", "# 1A Sur - 7") are not searched.
    final pause = ColombianAddress.tryParse(text) != null ? 900 : 400;
    _debounce = Timer(Duration(milliseconds: pause), () async {
      final token = ++_searchToken;
      setState(() => _loading = true);
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await tripController.search(
        text,
        languageCode,
        near: locationController.value?.position,
      );
      if (!mounted || token != _searchToken) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  void _select(PlaceSlot slot, Place place) {
    _shown[slot] = place;
    _texts[slot]!.text = place.name;
    tripController.setPlace(slot, place);
    setState(() => _suggestions = const []);
    if (slot == PlaceSlot.origin && widget.state.destination == null) {
      _focus[PlaceSlot.destination]!.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _clear(PlaceSlot slot) {
    _debounce?.cancel();
    _shown[slot] = null;
    _texts[slot]!.clear();
    tripController.setPlace(slot, null);
    setState(() => _suggestions = const []);
    _focus[slot]!.requestFocus();
  }

  void _pickOnMap(PlaceSlot slot) {
    FocusScope.of(context).unfocus();
    tripController.startPicking(slot);
  }

  void _swap() {
    final origin = _texts[PlaceSlot.origin]!.text;
    final destination = _texts[PlaceSlot.destination]!.text;
    setState(() => _swapTurns += 0.5);
    tripController.swap();
    _shown[PlaceSlot.origin] = tripController.value.origin;
    _shown[PlaceSlot.destination] = tripController.value.destination;
    _texts[PlaceSlot.origin]!.text = destination;
    _texts[PlaceSlot.destination]!.text = origin;
  }

  bool get _canSearch =>
      !_resolving &&
      !tripController.isSearching &&
      PlaceSlot.values.every(
        (slot) =>
            _placeOf(slot) != null || _texts[slot]!.text.trim().length >= 2,
      );

  /// Uses the chosen places, or the best match for text typed without
  /// picking a suggestion, then plans the trip.
  Future<void> _findBestRoute() async {
    // A pending autocomplete search must not start after (and cancel) this
    // one; drop it and ignore any suggestions still on the way.
    _debounce?.cancel();
    _searchToken++;
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() => _resolving = true);
    try {
      for (final slot in PlaceSlot.values) {
        if (_placeOf(slot) != null) continue;
        final query = _texts[slot]!.text.trim();
        final results = await tripController
            .search(
              query,
              languageCode,
              near: locationController.value?.position,
            )
            .timeout(const Duration(seconds: 20), onTimeout: () => const []);
        if (!mounted) return;
        if (results.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.placeNotFound(query))));
          return;
        }
        _shown[slot] = results.first;
        tripController.setPlace(slot, results.first);
        _texts[slot]!.text = results.first.name;
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
    await tripController.planTrip();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? MetroPalette.surface.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.98);
    final textColor = isDark ? Colors.white : Colors.black87;
    final busy = _resolving || tripController.isSearching;

    return Material(
      color: cardColor,
      elevation: 10,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 4),
              child: Row(
                children: [
                  const _RouteDots(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        _PlaceInput(
                          controller: _texts[PlaceSlot.origin]!,
                          focusNode: _focus[PlaceSlot.origin]!,
                          hint: l10n.originHint,
                          textColor: textColor,
                          onChanged: (t) => _onChanged(PlaceSlot.origin, t),
                          onClear: () => _clear(PlaceSlot.origin),
                          clearTooltip: l10n.clear,
                          actions: [
                            _InputAction(
                              icon: Icons.my_location_rounded,
                              tooltip: l10n.myLocation,
                              onTap: widget.onUseMyLocation,
                            ),
                            _InputAction(
                              icon: Icons.edit_location_alt_rounded,
                              tooltip: l10n.placeOnMap,
                              onTap: () async => _pickOnMap(PlaceSlot.origin),
                            ),
                          ],
                        ),
                        Divider(
                          height: 6,
                          color: textColor.withValues(alpha: 0.1),
                        ),
                        _PlaceInput(
                          controller: _texts[PlaceSlot.destination]!,
                          focusNode: _focus[PlaceSlot.destination]!,
                          hint: l10n.whereTo,
                          textColor: textColor,
                          onChanged: (t) =>
                              _onChanged(PlaceSlot.destination, t),
                          onClear: () => _clear(PlaceSlot.destination),
                          clearTooltip: l10n.clear,
                          actions: [
                            _InputAction(
                              icon: Icons.edit_location_alt_rounded,
                              tooltip: l10n.placeOnMap,
                              onTap: () async =>
                                  _pickOnMap(PlaceSlot.destination),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _swapTurns,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    child: IconButton(
                      tooltip: l10n.swapPlaces,
                      icon: Icon(Icons.swap_vert_rounded, color: textColor),
                      onPressed: _swap,
                    ),
                  ),
                ],
              ),
            ),
            if (_activeSlot != null && (_suggestions.isNotEmpty || _loading))
              // Same tap region as the text fields: tapping a suggestion must
              // not count as "tap outside", which would unfocus and drop it.
              TextFieldTapRegion(
                child: _Suggestions(
                  places: _suggestions,
                  loading: _loading,
                  textColor: textColor,
                  onSelect: (place) => _select(_activeSlot!, place),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: _SearchButton(
                label: l10n.findBestRoute,
                enabled: _canSearch,
                busy: busy,
                onPressed: _findBestRoute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  const _SearchButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled || busy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: active
              ? const [MetroPalette.green, MetroPalette.greenDeep]
              : [
                  MetroPalette.walk.withValues(alpha: 0.35),
                  MetroPalette.walk.withValues(alpha: 0.25),
                ],
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: MetroPalette.green.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: busy
                  ? const SizedBox(
                      key: ValueKey('busy'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
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

class _RouteDots extends StatelessWidget {
  const _RouteDots();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MetroPalette.green, width: 3),
          ),
        ),
        for (var i = 0; i < 4; i++)
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(
              color: MetroPalette.walk,
              shape: BoxShape.circle,
            ),
          ),
        const Icon(
          Icons.location_on_rounded,
          size: 16,
          color: MetroPalette.green,
        ),
      ],
    );
  }
}

class _InputAction {
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;

  const _InputAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}

class _PlaceInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final Color textColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String clearTooltip;
  final List<_InputAction> actions;

  const _PlaceInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.textColor,
    required this.onChanged,
    required this.onClear,
    required this.clearTooltip,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: hasText
              ? IconButton(
                  key: const ValueKey('clear'),
                  visualDensity: VisualDensity.compact,
                  tooltip: clearTooltip,
                  onPressed: onClear,
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: textColor,
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('empty'), width: 0),
        ),
        for (final action in actions)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: action.tooltip,
            icon: Icon(action.icon, size: 20, color: MetroPalette.green),
            onPressed: action.onTap,
          ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<Place> places;
  final bool loading;
  final Color textColor;
  final ValueChanged<Place> onSelect;

  const _Suggestions({
    required this.places,
    required this.loading,
    required this.textColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: loading ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: const LinearProgressIndicator(
              minHeight: 2,
              color: MetroPalette.green,
              backgroundColor: Colors.transparent,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                final station = place.station;
                final subtitle = _subtitle(context, place);
                return TweenAnimationBuilder<double>(
                  key: ValueKey('${place.name}${place.position}'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 220 + index * 45),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: MetroPalette.green.withValues(
                        alpha: 0.15,
                      ),
                      child: station != null
                          ? ModeIcon(
                              _stationMode(station.lineIds),
                              size: 18,
                              color: MetroPalette.green,
                            )
                          : const Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: MetroPalette.green,
                            ),
                    ),
                    title: Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                    onTap: () => onSelect(place),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

TransitMode _stationMode(List<String> lineIds) {
  final lines = tripController.value.network?.lines;
  final modes = [
    for (final id in lineIds)
      if (lines?[id] != null) lines![id]!.mode,
  ]..sort((a, b) => a.index.compareTo(b.index));
  return modes.isEmpty ? TransitMode.metro : modes.first;
}

String? _subtitle(BuildContext context, Place place) {
  final station = place.station;
  final l10n = AppLocalizations.of(context)!;
  if (station == null) {
    return [
      ?place.subtitle,
      if (place.approximate) l10n.approximateLocation,
    ].join(' · ');
  }
  final lines = tripController.value.network?.lines ?? const {};
  final labels = [
    for (final id in station.lineIds)
      if (lines[id] != null && !lines[id]!.approximate)
        lineLabel(l10n, lines[id]!),
  ];
  return labels.isEmpty ? null : labels.join(' · ');
}
