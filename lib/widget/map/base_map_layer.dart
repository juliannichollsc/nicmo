import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/infrastructure/map/map_style_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// Free base map, no API key, that keeps working offline.
///
/// * OpenStreetMap raster tiles are painted from the very first frame, so the
///   map is never blank and they also fill any gap while vector tiles load.
///   They are kept on disk ([_rasterCache]) for offline use.
/// * OpenFreeMap vector tiles (OpenStreetMap data) on top, with label layers
///   removed so street names are not drawn. Their style is saved on the
///   device ([MapStyleStore]) and the rendered tiles are cached on disk by
///   vector_map_tiles, so after the first visit an area is painted again
///   from the cache (also when zooming back to it) instead of re-rendered.
class BaseMapLayer extends StatelessWidget {
  const BaseMapLayer({super.key});

  /// Disk cache of the raster tiles: tiles stay usable offline for 30 days
  /// (OpenStreetMap asks clients to cache for at least 7).
  static final MapCachingProvider _rasterCache =
      BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 300 * 1024 * 1024,
        overrideFreshAge: const Duration(days: 30),
      );

  static final Map<Brightness, vtr.Theme> _themes = {};

  /// Style without label layers, with an id per brightness.
  ///
  /// Both OpenFreeMap styles come without an `id`, so the renderer would call
  /// them both "default" and share its rendered-tile caches between them:
  /// while zooming, light tiles showed up on the dark map and vice versa.
  static vtr.Theme _theme(Brightness brightness, Style style) {
    return _themes[brightness] ??= style.theme.copyWith(
      id: 'nicmo-${brightness.name}-nolabels',
      types: {
        vtr.ThemeLayerType.background,
        vtr.ThemeLayerType.fill,
        vtr.ThemeLayerType.line,
      },
    );
  }

  /// Restores the saved style and starts downloading it when missing.
  static Future<void> preload(Brightness brightness) async {
    await MapStyleStore.restore();
    MapStyleStore.load(brightness).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    // Keyed by brightness: switching theme rebuilds the layer from scratch,
    // so a style of the other theme is never painted with this theme's
    // colours, and tiles cached for one theme are not reused for the other.
    return _ThemedBaseMap(
      key: ValueKey(brightness),
      brightness: brightness,
      isDark: isDark,
    );
  }

  /// Gives the dark vector basemap a soft green-grey cast (same hue as the
  /// app palette, low saturation).
  static const List<double> _greenTintMatrix = [
    0.85, 0, 0, 0, 0, //
    0, 1.0, 0, 0, 6, //
    0, 0, 0.8, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  /// Mutes the colourful OpenStreetMap tiles (30 % saturation, same
  /// brightness and contrast) so raster gaps while zooming sit close to the
  /// soft light vector style.
  static const List<double> _lightRasterMatrix = [
    0.449, 0.501, 0.051, 0, 0, //
    0.149, 0.801, 0.051, 0, 0, //
    0.149, 0.501, 0.351, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  /// Inverts the light OpenStreetMap tiles into the dark palette: white
  /// becomes the app background (#10150F), black a muted green-grey.
  static const List<double> _darkRasterMatrix = [
    -0.069, -0.136, -0.025, 0, 75, //
    -0.079, -0.155, -0.029, 0, 88, //
    -0.065, -0.127, -0.024, 0, 70, //
    0, 0, 0, 1, 0,
  ];
}

class _ThemedBaseMap extends StatefulWidget {
  final Brightness brightness;
  final bool isDark;

  const _ThemedBaseMap({
    super.key,
    required this.brightness,
    required this.isDark,
  });

  @override
  State<_ThemedBaseMap> createState() => _ThemedBaseMapState();
}

class _ThemedBaseMapState extends State<_ThemedBaseMap>
    with WidgetsBindingObserver {
  Style? _style;

  /// Fade only when the style arrives after the map is already on screen.
  bool _fade = false;

  /// Bumped to reload the raster tiles that failed (no network).
  int _rasterGeneration = 0;
  bool _rasterFailed = false;
  Timer? _retry;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _style = MapStyleStore.ready(widget.brightness);
    if (_style == null) {
      _fade = true;
      _loadStyle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background: the network is often available again.
    if (state == AppLifecycleState.resumed && _needsRetry) {
      _retry?.cancel();
      _attempt = 0;
      _recover();
    }
  }

  bool get _needsRetry => _style == null || _rasterFailed;

  void _loadStyle() {
    MapStyleStore.load(widget.brightness).then(
      (style) {
        if (!mounted) return;
        setState(() => _style = style);
        // The network is back: reload any raster tile that failed meanwhile.
        if (_rasterFailed) _recover();
      },
      onError: (Object error) {
        debugPrint('Vector base map unavailable, keeping raster: $error');
        if (mounted) _scheduleRetry();
      },
    );
  }

  void _onRasterError(TileImage tile, Object error, StackTrace? stackTrace) {
    _rasterFailed = true;
    _scheduleRetry();
  }

  /// Retries with back-off (2 s, 4 s, 8 s … up to 30 s) while offline.
  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    final seconds = (2 << _attempt).clamp(2, 30);
    _attempt++;
    _retry = Timer(Duration(seconds: seconds), _recover);
  }

  void _recover() {
    if (!mounted) return;
    if (_style == null) _loadStyle();
    if (_rasterFailed) {
      setState(() {
        _rasterFailed = false;
        _rasterGeneration++;
      });
    }
    if (_style != null && !_rasterFailed) _attempt = 0;
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final Widget raster = ColorFiltered(
      colorFilter: ColorFilter.matrix(
        widget.isDark
            ? BaseMapLayer._darkRasterMatrix
            : BaseMapLayer._lightRasterMatrix,
      ),
      child: TileLayer(
        key: ValueKey(_rasterGeneration),
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: kAppPackage,
        panBuffer: 1,
        keepBuffer: 4,
        tileProvider: NetworkTileProvider(
          cachingProvider: BaseMapLayer._rasterCache,
        ),
        errorTileCallback: _onRasterError,
        evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
        tileDisplay: const TileDisplay.fadeIn(
          duration: Duration(milliseconds: 180),
        ),
      ),
    );
    if (style == null) return raster;

    Widget vector = VectorTileLayer(
      theme: BaseMapLayer._theme(widget.brightness, style),
      tileProviders: style.providers,
      maximumZoom: 18,
      // Bigger memory caches: zooming back to an area reuses its tiles.
      memoryTileCacheMaxSize: 32 * 1024 * 1024,
      memoryTileDataCacheMaxSize: 60,
      fileCacheMaximumSizeInBytes: 200 * 1024 * 1024,
      fileCacheTtl: const Duration(days: 60),
    );
    if (widget.isDark) {
      vector = ColorFiltered(
        colorFilter: const ColorFilter.matrix(BaseMapLayer._greenTintMatrix),
        child: vector,
      );
    }
    if (_fade) {
      vector = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: vector,
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: raster),
        Positioned.fill(child: vector),
      ],
    );
  }
}
