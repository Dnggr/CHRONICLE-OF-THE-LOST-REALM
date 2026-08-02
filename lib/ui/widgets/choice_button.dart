import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PROBLEM: choice text was rendered in `Colors.amber[100]` (a very pale
/// yellow) with no explicit Text color override, inherited as the
/// button's `foregroundColor`. That's fine on a dark background, but
/// SceneScreen's page is a light parchment color (0xFFE9E2D3) - pale
/// yellow on pale parchment is nearly unreadable, which is exactly the
/// bug reported (screenshot showed choice text ghosted out, barely
/// visible against the border). SOLUTION: use a dark, warm brown for
/// the text (matching NarrativeText's prose color) so it reads clearly
/// on the parchment background, keep amber only as the accent
/// (border/icon), and give the button a faint fill so it's visually a
/// distinct tappable shape even before you notice the border.
class ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  static const _textColor = Color(0xFF3A2E22);

  const ChoiceButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            backgroundColor: Colors.amber.withOpacity(0.12),
            side: BorderSide(color: Colors.amber[800]!, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            // NOTE: foregroundColor still set (drives the button's tap/
            // hover/focus overlay tint) but every Text/Icon below also
            // sets its OWN explicit color rather than inheriting this,
            // so a future style tweak here can't silently break
            // readability again the way the amber[100] bug did.
            foregroundColor: _textColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond_outlined, size: 14, color: Colors.amber[800]),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    color: _textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
