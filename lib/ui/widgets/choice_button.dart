import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A choice should read like a line the player is about to speak, not like a
/// large call-to-action. The short underline and quiet arrow make it legible
/// without competing with the prose above it.
class ChoiceButton extends StatefulWidget {
  final String label;
  final String? preview;
  final VoidCallback? onTap;

  const ChoiceButton({
    super.key,
    required this.label,
    this.preview,
    required this.onTap,
  });

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final color = enabled ? const Color(0xFF3A2E22) : Colors.brown[300]!;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(4),
          splashColor: Colors.brown.withOpacity(0.08),
          highlightColor: Colors.brown.withOpacity(0.04),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _pressed
                        ? Colors.brown[500]!
                        : Colors.brown.withOpacity(0.18),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 140),
                    offset: _pressed ? const Offset(0.16, 0) : Offset.zero,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: Text('›', style: TextStyle(fontSize: 22, color: color)),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 140),
                          style: GoogleFonts.merriweather(
                            fontSize: 14,
                            height: 1.45,
                            color: color,
                            fontWeight: _pressed ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(widget.label),
                        ),
                        if (widget.preview != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.preview!,
                            style: GoogleFonts.merriweather(
                              fontSize: 11,
                              height: 1.35,
                              color: Colors.brown[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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
