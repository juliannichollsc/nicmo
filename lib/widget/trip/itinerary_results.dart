import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/ride_hail/ride_hail_launcher.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

class ItineraryResultsSheet extends StatelessWidget {
  final TripState state;
  final VoidCallback onStart;

  const ItineraryResultsSheet({
    super.key,
    required this.state,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.46,
      minChildSize: 0.2,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.2, 0.46, 0.88],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? MetroPalette.surface.withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black38)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MetroPalette.walk.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (state.status == TripStatus.searching) ...[
                Row(
                  children: [
                    Lottie.asset(
                      'assets/animations/metro_train.json',
                      width: 72,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.searchingRoutes,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < 3; i++) _SkeletonCard(index: i),
              ] else ...[
                Text(
                  l10n.alternatives,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < state.itineraries.length; i++)
                  _Staggered(
                    index: i,
                    child: _ItineraryCard(
                      network: state.network!,
                      itinerary: state.itineraries[i],
                      selected: i == state.selectedIndex,
                      onTap: () => tripController.select(i),
                      onStart: onStart,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Staggered extends StatelessWidget {
  final int index;
  final Widget child;

  const _Staggered({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final TransitNetwork network;
  final Itinerary itinerary;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _ItineraryCard({
    required this.network,
    required this.itinerary,
    required this.selected,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? MetroPalette.green.withValues(alpha: 0.12)
              : onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? MetroPalette.green
                : onSurface.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tags(itinerary: itinerary),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < itinerary.legs.length; i++) ...[
                              if (i > 0)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: onSurface.withValues(alpha: 0.5),
                                ),
                              LineBadge(leg: itinerary.legs[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.minutesShort(itinerary.totalMin.ceil()),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      l10n.transfersCount(itinerary.transfers),
                      if (itinerary.walkMeters >= 15)
                        l10n.walkDistance(itinerary.walkMeters.round()),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 12),
                    LegTimeline(network: network, itinerary: itinerary),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MetroPalette.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.startTrip),
                      ),
                    ),
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

class _Tags extends StatelessWidget {
  final Itinerary itinerary;

  const _Tags({required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <(String, IconData)>[
      if (itinerary.tags.contains(ItineraryTag.fastest))
        (l10n.recommended, Icons.bolt_rounded),
      if (itinerary.tags.contains(ItineraryTag.fewestTransfers))
        (l10n.fewestTransfers, Icons.sync_alt_rounded),
      if (itinerary.tags.contains(ItineraryTag.leastWalking))
        (l10n.leastWalking, Icons.directions_walk_rounded),
      if (itinerary.rideLegs.any((leg) => leg.line!.approximate))
        (l10n.approximateRoute, Icons.info_outline_rounded),
    ];
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final (label, icon) in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MetroPalette.green.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: MetroPalette.green),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MetroPalette.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical list of steps with the line colour as a rail on the left.
class LegTimeline extends StatelessWidget {
  final TransitNetwork network;
  final Itinerary itinerary;
  final int? currentIndex;

  /// During an active trip the car steps offer Uber / inDrive, which open
  /// the app. While planning, steps only switch between car and walking.
  final bool inTrip;

  const LegTimeline({
    super.key,
    required this.network,
    required this.itinerary,
    this.currentIndex,
    this.inTrip = false,
  });

  /// Opens the app with the pickup and drop-off of the car step [index].
  Future<void> _openApp(
    BuildContext context,
    int index,
    RideHailService service,
  ) async {
    tripController.setLegApp(index, service);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final leg = itinerary.legs[index];
    final target = legTargetName(l10n, leg);
    final name = rideHailName(service);
    final result = await RideHailLauncher.open(
      service,
      pickup: leg.path.first,
      pickupName: legSourceName(l10n, leg),
      dropoff: leg.path.last,
      dropoffName: target,
    );
    switch (result) {
      case RideHailLaunch.withDestination:
        // Uber shows its own confirmation; inDrive gets a short note.
        if (service == RideHailService.indrive) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.destinationSent(name))),
          );
        }
      case RideHailLaunch.appOnly:
        // Older app versions cannot receive it: hand it over to paste.
        await Clipboard.setData(
          ClipboardData(text: '$target (${formatCoordinates(leg.path.last)})'),
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.destinationCopied(name))),
        );
      case RideHailLaunch.store:
        break; // Not installed: the store page is open.
      case RideHailLaunch.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.appNotOpened(name))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        for (var i = 0; i < itinerary.legs.length; i++)
          _TimelineRow(
            leg: itinerary.legs[i],
            title: legInstruction(l10n, network, itinerary.legs[i]),
            detail: legDetail(l10n, itinerary.legs[i]),
            subtitle: itinerary.legs[i].isRideHail
                ? l10n.rideHailRequest(
                    legSourceName(l10n, itinerary.legs[i]),
                    legTargetName(l10n, itinerary.legs[i]),
                  )
                : null,
            wait: itinerary.legs[i].isWalk
                ? null
                : l10n.waitAbout(itinerary.legs[i].waitMin.ceil()),
            active: currentIndex == null || currentIndex == i,
            done: currentIndex != null && i < currentIndex!,
            textColor: onSurface,
            onSetCar: itinerary.legs[i].isWalk
                ? (car) => tripController.setLegCar(i, car)
                : null,
            onOpenApp: inTrip && itinerary.legs[i].isWalk
                ? (service) => _openApp(context, i, service)
                : null,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatefulWidget {
  final ItineraryLeg leg;
  final String title;
  final String detail;
  final String? subtitle;
  final String? wait;
  final bool active;
  final bool done;
  final Color textColor;

  /// Walking steps: switch between walking and car.
  final ValueChanged<bool>? onSetCar;

  /// Car steps during a trip: open Uber / inDrive.
  final ValueChanged<RideHailService>? onOpenApp;

  const _TimelineRow({
    required this.leg,
    required this.title,
    required this.detail,
    required this.subtitle,
    required this.wait,
    required this.active,
    required this.done,
    required this.textColor,
    this.onSetCar,
    this.onOpenApp,
  });

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  bool _modeOptionsOpen = false;

  void _setCar(bool car) {
    setState(() => _modeOptionsOpen = false);
    widget.onSetCar!(car);
  }

  @override
  Widget build(BuildContext context) {
    final leg = widget.leg;
    final textColor = widget.textColor;
    final color = legColor(leg, Theme.of(context).brightness);
    final soft = leg.isWalk && !leg.isRideHail;
    final small = TextStyle(
      fontSize: 12,
      color: textColor.withValues(alpha: 0.7),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.active ? 1 : (widget.done ? 0.45 : 0.7),
      // The rail is painted behind the content and stretches with it, so
      // the row needs no intrinsic measuring (which breaks AnimatedSize).
      child: Stack(
        children: [
          Positioned(
            left: soft ? 16 : 15,
            top: 34,
            bottom: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: soft ? 2 : 4,
              color: color.withValues(alpha: soft ? 0.4 : 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: soft ? color.withValues(alpha: 0.25) : color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                            turns: Tween(
                              begin: 0.75,
                              end: 1.0,
                            ).animate(animation),
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          ),
                      child: widget.done
                          ? Icon(
                              Icons.check_rounded,
                              key: const ValueKey('done'),
                              size: 18,
                              color: onLineColor(color),
                            )
                          : leg.isRideHail
                          ? Icon(
                              Icons.local_taxi_rounded,
                              key: const ValueKey('car'),
                              size: 18,
                              color: onLineColor(color),
                            )
                          : ModeIcon(
                              leg.mode,
                              key: ValueKey(leg.mode),
                              size: 18,
                              color: soft ? textColor : onLineColor(color),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14, top: 4),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.wait != null)
                          Text(widget.wait!, style: small),
                        Text(widget.detail, style: small),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subtitle!,
                              style: small.copyWith(
                                color: MetroPalette.greenBright,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_modeOptionsOpen)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _ModeOptions(
                              byCar: leg.isRideHail,
                              onChoose: _setCar,
                            ),
                          ),
                        // In the trip, a car step shows the apps to request
                        // it with; switching back to walking hides them.
                        if (widget.onOpenApp != null && leg.isRideHail)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _AppOptions(
                              current: leg.rideHail,
                              onOpen: widget.onOpenApp!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onSetCar != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _RideToggle(
                    open: _modeOptionsOpen,
                    selected: leg.isRideHail,
                    onTap: () =>
                        setState(() => _modeOptionsOpen = !_modeOptionsOpen),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round car button; turns into a close button while the options show.
class _RideToggle extends StatelessWidget {
  final bool open;
  final bool selected;
  final VoidCallback onTap;

  const _RideToggle({
    required this.open,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strong = open || selected;
    return Tooltip(
      message: AppLocalizations.of(context)!.goByCar,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: strong
                ? MetroPalette.car
                : MetroPalette.car.withValues(alpha: 0.18),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.5, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              open ? Icons.close_rounded : Icons.local_taxi_rounded,
              key: ValueKey(open),
              size: 18,
              color: strong ? Colors.white : MetroPalette.car,
            ),
          ),
        ),
      ),
    );
  }
}

/// Uber, inDrive and walk, right-aligned under the step; wraps on narrow
/// screens instead of overflowing.
/// Car or walking for a step, right-aligned under it.
class _ModeOptions extends StatelessWidget {
  final bool byCar;
  final ValueChanged<bool> onChoose;

  const _ModeOptions({required this.byCar, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          _RideOption(
            index: 0,
            selected: byCar,
            background: MetroPalette.car,
            foreground: Colors.white,
            icon: Icons.local_taxi_rounded,
            label: l10n.modeCar,
            onTap: () => onChoose(true),
          ),
          _RideOption(
            index: 1,
            selected: !byCar,
            background: MetroPalette.walk.withValues(alpha: 0.3),
            foreground: Theme.of(context).colorScheme.onSurface,
            icon: Icons.directions_walk_rounded,
            label: l10n.walkInstead,
            onTap: () => onChoose(false),
          ),
        ],
      ),
    );
  }
}

/// "Request your car with" Uber / inDrive (active trip only).
class _AppOptions extends StatelessWidget {
  final RideHailService? current;
  final ValueChanged<RideHailService> onOpen;

  const _AppOptions({required this.current, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Text(
            l10n.requestWith,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          _RideOption(
            index: 0,
            selected: current == RideHailService.uber,
            background: Colors.black,
            foreground: Colors.white,
            label: rideHailName(RideHailService.uber),
            onTap: () => onOpen(RideHailService.uber),
          ),
          _RideOption(
            index: 1,
            selected: current == RideHailService.indrive,
            background: const Color(0xFFC1F11D),
            foreground: Colors.black,
            label: rideHailName(RideHailService.indrive),
            onTap: () => onOpen(RideHailService.indrive),
          ),
        ],
      ),
    );
  }
}

class _RideOption extends StatelessWidget {
  final int index;
  final bool selected;
  final Color background;
  final Color foreground;
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _RideOption({
    required this.index,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: background,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? MetroPalette.greenBright : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 7),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: foreground),
              if (icon != null && label != null) const SizedBox(width: 4),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // Slide in from the right, one after another.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 70),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(24 * (1 - t), 0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Placeholder card with a moving sheen while routes are computed.
class _SkeletonCard extends StatefulWidget {
  final int index;

  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    final highlight = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.18);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    return _Staggered(
      index: widget.index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedBuilder(
          animation: _sheen,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) {
              final t = _sheen.value * 2 - 0.5;
              return LinearGradient(
                colors: [base, highlight, base],
                stops: [
                  (t - 0.25).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.25).clamp(0.0, 1.0),
                ],
              ).createShader(rect);
            },
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    bar(54, 24),
                    const SizedBox(width: 8),
                    bar(54, 24),
                    const SizedBox(width: 8),
                    bar(40, 24),
                    const Spacer(),
                    bar(64, 26),
                  ],
                ),
                const SizedBox(height: 12),
                bar(180, 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
