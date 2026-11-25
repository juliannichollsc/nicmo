import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:nicmo/infrastructure/share/location_share.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:nicmo/state/location_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/map/metro_map.dart';
import 'package:nicmo/widget/transit/transit_style.dart';
import 'package:nicmo/widget/trip/itinerary_results.dart';

enum _Stage { intro, navigating, arrived }

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen>
    with SingleTickerProviderStateMixin {
  static const _arrivalRadiusMeters = 60.0;
  static const Distance _distance = Distance();

  final GlobalKey<MetroMapState> _mapKey = GlobalKey<MetroMapState>();
  late final AnimationController _vehicle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  _Stage _stage = _Stage.intro;
  int _step = 0;
  Timer? _introTimer;

  TripState get _trip => tripController.value;
  Itinerary? get _itinerary => _trip.selected;

  @override
  void initState() {
    super.initState();
    _vehicle.addListener(() => setState(() {}));
    // Walking legs switched to Uber / inDrive update times and icons.
    tripController.addListener(_onTripChanged);
    final resumed = ActiveTripStore.pending;
    ActiveTripStore.pending = null;
    if (resumed != null && _itinerary != null) {
      // Reopened during a trip: straight back to the saved step.
      _step = resumed.step;
      _introTimer = Timer(Duration.zero, () => _startNavigation(_step));
    } else {
      _introTimer = Timer(const Duration(milliseconds: 3200), _startNavigation);
    }
  }

  void _onTripChanged() {
    if (!mounted) return;
    setState(() {});
    if (_stage == _Stage.navigating) _save();
  }

  /// Saves the trip and the current step, to resume it if the app closes.
  void _save() {
    final itinerary = _itinerary;
    final origin = _trip.origin;
    final destination = _trip.destination;
    if (itinerary == null || origin == null || destination == null) return;
    ActiveTripStore.save(
      ActiveTrip(
        itinerary: itinerary,
        origin: origin,
        destination: destination,
        step: _step,
      ),
    ).ignore();
  }

  @override
  void dispose() {
    // Leaving the trip screen ends the trip. (When the system kills the app
    // dispose does not run, so the trip is kept and resumed.)
    ActiveTripStore.clear().ignore();
    _introTimer?.cancel();
    tripController.removeListener(_onTripChanged);
    locationController.removeListener(_onLocation);
    _vehicle.dispose();
    super.dispose();
  }

  void _startNavigation([int step = 0]) {
    if (!mounted || _itinerary == null) return;
    setState(() => _stage = _Stage.navigating);
    locationController.addListener(_onLocation);
    locationController.start();
    // While there is network, save the map along the whole route so it is
    // still shown if the signal is lost during the trip.
    OfflineVectorTiles.prefetchRoute(_itinerary!.fullPath).ignore();
    // Wait for the map to be laid out before flying the camera.
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(step));
  }

  /// Advances automatically when the live position reaches the end of the
  /// current step.
  void _onLocation() {
    final location = locationController.value;
    if (location == null || _stage != _Stage.navigating) return;
    setState(() {}); // repaint the live position marker
    final leg = _itinerary!.legs[_step];
    if (_distance(location.position, leg.path.last) < _arrivalRadiusMeters) {
      _next();
    }
  }

  void _goToStep(int step) {
    final legs = _itinerary!.legs;
    setState(() => _step = step.clamp(0, legs.length - 1));
    _save();
    _vehicle.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 120), () {
      _mapKey.currentState?.fitPoints(legs[_step].path);
    });
  }

  void _next() {
    if (_step >= _itinerary!.legs.length - 1) {
      setState(() => _stage = _Stage.arrived);
      locationController.removeListener(_onLocation);
      ActiveTripStore.clear().ignore();
      return;
    }
    _goToStep(_step + 1);
  }

  /// Message with a Google Maps link to where the rider is now (the live
  /// position, or the start of the current step without GPS).
  String _shareText() {
    final l10n = AppLocalizations.of(context)!;
    final itinerary = _itinerary!;
    final position =
        locationController.value?.position ?? itinerary.legs[_step].path.first;
    final remaining = itinerary.legs
        .skip(_step)
        .fold<double>(0, (sum, leg) => sum + leg.durationMin + leg.waitMin);
    return l10n.shareMessage(
      _trip.destination?.name ?? l10n.yourDestination,
      remaining.ceil(),
      LocationShare.mapsLink(position).toString(),
    );
  }

  void _share(Rect? origin) {
    final text = _shareText();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ShareSheet(
        text: text,
        onWhatsApp: () async {
          Navigator.of(context).pop();
          final opened = await LocationShare.whatsApp(text);
          if (!opened && mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(this.context)!.whatsAppUnavailable,
                ),
              ),
            );
          }
        },
        onOther: () {
          Navigator.of(context).pop();
          LocationShare.other(text, origin: origin);
        },
      ),
    );
  }

  void _finish() {
    ActiveTripStore.clear().ignore();
    tripController.reset();
    context.go('/home');
  }

  LatLng _vehiclePosition(ItineraryLeg leg) {
    final t = Curves.easeInOutCubic.transform(_vehicle.value);
    final path = leg.path;
    var total = 0.0;
    for (var i = 0; i + 1 < path.length; i++) {
      total += _distance(path[i], path[i + 1]);
    }
    var budget = total * t;
    for (var i = 0; i + 1 < path.length; i++) {
      final d = _distance(path[i], path[i + 1]);
      if (budget <= d) {
        final f = d == 0 ? 0.0 : budget / d;
        return LatLng(
          path[i].latitude + (path[i + 1].latitude - path[i].latitude) * f,
          path[i].longitude + (path[i + 1].longitude - path[i].longitude) * f,
        );
      }
      budget -= d;
    }
    return path.last;
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = _itinerary;
    final network = _trip.network;
    if (itinerary == null || network == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return const Scaffold(backgroundColor: MetroPalette.night);
    }

    return Scaffold(
      backgroundColor: MetroPalette.night,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.06, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: switch (_stage) {
          _Stage.intro => _Intro(
            key: const ValueKey('intro'),
            destination: _trip.destination?.name ?? '',
            itinerary: itinerary,
            onSkip: () {
              _introTimer?.cancel();
              _startNavigation();
            },
          ),
          _Stage.navigating => _navigation(context, network, itinerary),
          _Stage.arrived => _Arrived(
            key: const ValueKey('arrived'),
            destination: _trip.destination?.name ?? '',
            onFinish: _finish,
          ),
        },
      ),
    );
  }

  Widget _navigation(
    BuildContext context,
    TransitNetwork network,
    Itinerary itinerary,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final leg = itinerary.legs[_step];
    final progress = (_step + _vehicle.value) / itinerary.legs.length;

    return Stack(
      key: const ValueKey('navigating'),
      children: [
        Positioned.fill(
          child: MetroMap(
            key: _mapKey,
            network: network,
            itinerary: itinerary,
            origin: _trip.origin?.position,
            destination: _trip.destination?.position,
            userPosition: locationController.value?.position,
            userAccuracy: locationController.value?.accuracyMeters,
            vehiclePosition: _vehiclePosition(leg),
            vehicleLeg: leg,
            fitPadding: const EdgeInsets.fromLTRB(60, 220, 60, 320),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _StepBanner(
                  network: network,
                  leg: leg,
                  step: _step,
                  total: itinerary.legs.length,
                  progress: progress,
                  onClose: _finish,
                ),
                const Spacer(),
                _StepSheet(
                  network: network,
                  itinerary: itinerary,
                  step: _step,
                  onPrevious: _step == 0 ? null : () => _goToStep(_step - 1),
                  onNext: _next,
                  onShare: _share,
                  nextLabel: _step == itinerary.legs.length - 1
                      ? l10n.endTrip
                      : l10n.nextStep,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  final String destination;
  final Itinerary itinerary;
  final VoidCallback onSkip;

  const _Intro({
    super.key,
    required this.destination,
    required this.itinerary,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onSkip,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MetroPalette.greenDeep, MetroPalette.night],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FadeUp(
                delay: 0,
                child: Text(
                  l10n.tripStarting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _FadeUp(
                delay: 150,
                child: Text(
                  destination,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: MetroPalette.mint,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Lottie.asset(
                'assets/animations/metro_train.json',
                width: double.infinity,
                height: 240,
                fit: BoxFit.contain,
                repeat: false,
              ),
              const SizedBox(height: 24),
              _FadeUp(
                delay: 400,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final leg in itinerary.legs) LineBadge(leg: leg),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FadeUp(
                delay: 550,
                child: Text(
                  '${l10n.minutesShort(itinerary.totalMin.ceil())} · '
                  '${l10n.transfersCount(itinerary.transfers)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 32),
              _FadeUp(
                delay: 700,
                child: SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 3200),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        color: MetroPalette.greenBright,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: Text(l10n.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeUp extends StatelessWidget {
  final int delay;
  final Widget child;

  const _FadeUp({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 600 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, t, child) {
        // Hold still during the delay part, then ease in.
        final local = ((t * total - delay) / 600).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(local);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _StepBanner extends StatelessWidget {
  final TransitNetwork network;
  final ItineraryLeg leg;
  final int step;
  final int total;
  final double progress;
  final VoidCallback onClose;

  const _StepBanner({
    required this.network,
    required this.leg,
    required this.step,
    required this.total,
    required this.progress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = leg.isWalk && !leg.isRideHail
        ? MetroPalette.green
        : legColor(leg, Theme.of(context).brightness);
    final fg = onLineColor(color);
    return Material(
      color: color,
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: color,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 4, 10),
              child: Row(
                children: [
                  leg.isRideHail
                      ? Icon(Icons.local_taxi_rounded, size: 34, color: fg)
                      : ModeIcon(leg.mode, size: 34, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Column(
                        key: ValueKey(step),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.stepOf(step + 1, total),
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            legInstruction(l10n, network, leg),
                            style: TextStyle(
                              color: fg,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            legDetail(l10n, leg),
                            style: TextStyle(color: fg.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: fg),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSheet extends StatelessWidget {
  final TransitNetwork network;
  final Itinerary itinerary;
  final int step;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final ValueChanged<Rect?> onShare;
  final String nextLabel;

  const _StepSheet({
    required this.network,
    required this.itinerary,
    required this.step,
    required this.onPrevious,
    required this.onNext,
    required this.onShare,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 10,
      color: isDark
          ? MetroPalette.surface.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.28,
              ),
              child: SingleChildScrollView(
                child: LegTimeline(
                  network: network,
                  itinerary: itinerary,
                  currentIndex: step,
                  // Car steps offer Uber / inDrive here, during the trip.
                  inTrip: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MetroPalette.green,
                      side: const BorderSide(color: MetroPalette.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.previousStep),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MetroPalette.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(nextLabel),
                  ),
                ),
                const SizedBox(width: 8),
                // Share where I am (WhatsApp or any app).
                Builder(
                  builder: (context) => IconButton.filledTonal(
                    tooltip: l10n.shareLocation,
                    style: IconButton.styleFrom(
                      foregroundColor: MetroPalette.green,
                      backgroundColor: MetroPalette.green.withValues(
                        alpha: 0.14,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox?;
                      onShare(
                        box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrived extends StatelessWidget {
  final String destination;
  final VoidCallback onFinish;

  const _Arrived({
    super.key,
    required this.destination,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [MetroPalette.greenDeep, MetroPalette.night],
          radius: 1.1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/arrival.json',
              width: double.infinity,
              height: 260,
              repeat: false,
            ),
            _FadeUp(
              delay: 700,
              child: Text(
                l10n.arrived,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _FadeUp(
              delay: 850,
              child: Text(
                destination,
                style: const TextStyle(color: MetroPalette.mint, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            _FadeUp(
              delay: 1000,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MetroPalette.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.endTrip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share options: WhatsApp first, then the system share sheet.
class _ShareSheet extends StatelessWidget {
  final String text;
  final VoidCallback onWhatsApp;
  final VoidCallback onOther;

  const _ShareSheet({
    required this.text,
    required this.onWhatsApp,
    required this.onOther,
  });

  static const _whatsAppGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shareTripTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shareTripHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Preview of the message.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(text),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onWhatsApp,
                    style: FilledButton.styleFrom(
                      backgroundColor: _whatsAppGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOther,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(l10n.shareOtherApps),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
