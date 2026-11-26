import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SourceTicketStub extends StatelessWidget {
  final String label;
  final String? code;
  final VoidCallback? onTap;

  const SourceTicketStub({
    Key? key,
    required this.label,
    this.code,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: MekongColors.card,
          border: Border.all(
            color: MekongColors.stubBorder,
            width: 1.2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MekongColors.riverGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: MekongColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItineraryStub extends StatelessWidget {
  final int day;
  final VoidCallback? onTap;

  const ItineraryStub({Key? key, required this.day, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: MekongColors.card,
          border: Border.all(color: MekongColors.stubBorder, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MekongColors.riverGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Itinerary · Day $day',
              style: const TextStyle(
                color: MekongColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
