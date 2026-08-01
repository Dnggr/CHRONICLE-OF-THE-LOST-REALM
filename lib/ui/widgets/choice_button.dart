import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

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
            side: BorderSide(color: Colors.amber[700]!, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            foregroundColor: Colors.amber[100],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond_outlined, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
