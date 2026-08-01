import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders narrative prose in a serif "book page" style, with an
/// optional illustration dropped inline (matching the reference
/// screenshot, where the image sits between two blocks of text).
///
/// [illustrationId] maps to assets/images/illustrations/<id>.png.
/// If the asset is missing (e.g. you haven't added art yet), this
/// widget shows a placeholder box instead of crashing - useful while
/// you're still writing scenes before sourcing final art.
class NarrativeText extends StatelessWidget {
  final String text;
  final String? illustrationId;

  const NarrativeText({super.key, required this.text, this.illustrationId});

  @override
  Widget build(BuildContext context) {
    // Reward lines like "+ Gold, 10" get their own styling, matching
    // the green highlight in the reference screenshot.
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...(() {
          final widgets = <Widget>[];
          for (final line in lines) {
            if (line.trim().startsWith('+') || line.trim().startsWith('-')) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line.trim(),
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      color: line.trim().startsWith('+')
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            } else if (line.trim().isEmpty) {
              widgets.add(const SizedBox(height: 12));
            } else {
              widgets.add(
                Text(
                  line,
                  style: GoogleFonts.merriweather(
                    fontSize: 16,
                    height: 1.5,
                    color: const Color(0xFF2A2420),
                  ),
                ),
              );
            }
          }
          return widgets;
        })(),
        if (illustrationId != null) ...[
          const SizedBox(height: 16),
          _Illustration(illustrationId: illustrationId!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  final String illustrationId;

  const _Illustration({required this.illustrationId});

  @override
  Widget build(BuildContext context) {
    final path = 'assets/images/illustrations/$illustrationId.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 180,
          alignment: Alignment.center,
          color: Colors.black12,
          child: Text(
            '[ illustration: $illustrationId ]',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
