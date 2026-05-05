import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MwButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? bgColor;
  final Color? fgColor;

  const MwButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.bgColor,
    this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (loading || onTap == null) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 52,
        decoration: BoxDecoration(
          color: (loading || onTap == null)
              ? (bgColor ?? AppTheme.primary).withOpacity(0.55)
              : (bgColor ?? AppTheme.primary),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fgColor ?? Colors.white,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: fgColor ?? Colors.white, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
