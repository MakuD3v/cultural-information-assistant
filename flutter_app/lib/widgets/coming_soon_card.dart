import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ComingSoonCard extends StatelessWidget {
  final String? message;
  final String? vietnameseMessage;
  final IconData icon;

  const ComingSoonCard({
    Key? key,
    this.message,
    this.vietnameseMessage,
    this.icon = Icons.hourglass_empty_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: MekongColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MekongColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MekongColors.straw.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MekongColors.clay, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Coming soon',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MekongColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sắp ra mắt',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MekongColors.clay,
              letterSpacing: 0.2,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: MekongColors.muted,
                height: 1.35,
              ),
            ),
          ],
          if (vietnameseMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              vietnameseMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: MekongColors.muted.withOpacity(0.85),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
