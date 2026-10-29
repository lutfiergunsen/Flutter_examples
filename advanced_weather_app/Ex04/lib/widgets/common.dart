import 'package:flutter/material.dart';

import '../models/place.dart';

const accentColor = Color.fromARGB(255, 0, 255, 0);

/// Translucent panel used for every block drawn over the background image.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class LocationHeader extends StatelessWidget {
  final Place place;
  final double titleSize;

  const LocationHeader({super.key, required this.place, this.titleSize = 26});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: accentColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                place.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (place.subtitle.isNotEmpty)
          Text(
            place.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
      ],
    );
  }
}

/// Centered white message used for empty and error states.
class InfoMessage extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const InfoMessage({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
