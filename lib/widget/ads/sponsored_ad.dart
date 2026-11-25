import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nicmo/infrastructure/ads/ads_service.dart';
import 'package:nicmo/theme/metro_theme.dart';

/// Small native ad (AdMob "small" template) styled as a Nicmo card. Takes no
/// space until an ad has loaded, and none at all when ads are unavailable
/// (web, tests, no consent, no ad unit), so screens look as before.
class SponsoredAd extends StatefulWidget {
  final AdPlacement placement;

  /// Forces the dark style on screens that are always dark (arrival).
  final bool dark;

  const SponsoredAd({super.key, required this.placement, this.dark = false});

  @override
  State<SponsoredAd> createState() => _SponsoredAdState();
}

class _SponsoredAdState extends State<SponsoredAd> {
  // Tall enough for the small template's icon, two text rows and button.
  static const _height = 100.0;

  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdsService.ready.addListener(_onReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _onReady() => _load();

  void _load() {
    if (!AdsService.ready.value || _ad != null) return;
    final unit = AdsService.unitId(widget.placement);
    if (unit == null) return;
    final dark = widget.dark || Theme.of(context).brightness == Brightness.dark;
    final text = dark ? Colors.white : MetroPalette.ink;
    _ad = NativeAd(
      adUnitId: unit,
      request: const AdRequest(nonPersonalizedAds: true),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: dark
            ? MetroPalette.surfaceHigh
            : MetroPalette.paper,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: MetroPalette.green,
          style: NativeTemplateFontStyle.bold,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: text,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: text.withValues(alpha: 0.7),
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: text.withValues(alpha: 0.7),
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        // No fill or no network: the slot simply stays empty.
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    AdsService.ready.removeListener(_onReady);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _loaded
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: _height,
                width: double.infinity,
                child: AdWidget(ad: _ad!),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
