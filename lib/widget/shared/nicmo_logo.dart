import 'package:flutter/material.dart';
import 'package:nicmo/theme/metro_theme.dart';

/// "N" badge of the Nicmo logo: light blue tile, white N and a small green
/// stop dot.
class NicmoBadge extends StatelessWidget {
  final double size;

  const NicmoBadge({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MetroPalette.logoBlue, MetroPalette.logoBlueDeep],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: MetroPalette.logoBlueDeep.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'N',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.62,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
            ),
          ),
          Positioned(
            right: size * 0.13,
            bottom: size * 0.13,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: MetroPalette.brand,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: size * 0.035),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Nicmo" wordmark: the N badge followed by "icmo".
class NicmoWordmark extends StatelessWidget {
  final double height;
  final Color? color;

  const NicmoWordmark({super.key, this.height = 52, this.color});

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NicmoBadge(size: height),
        SizedBox(width: height * 0.1),
        Text(
          'icmo',
          style: TextStyle(
            color: textColor,
            fontSize: height * 0.78,
            fontWeight: FontWeight.w900,
            letterSpacing: height * 0.01,
            height: 1,
          ),
        ),
      ],
    );
  }
}
