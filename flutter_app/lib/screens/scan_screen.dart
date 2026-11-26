import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/coming_soon_card.dart';

class ScanScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ScanScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MekongColors.paper,
      appBar: AppBar(
        backgroundColor: MekongColors.riverGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text(
          'QR Scanner',
          style: TextStyle(fontFamily: 'Fraunces', color: Colors.white),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: ComingSoonCard(
            message: 'QR code scanning and landmark recognition are work in progress.',
            vietnameseMessage: 'Tính năng quét mã QR đang được hoàn thiện và sẽ sớm ra mắt.',
            icon: Icons.qr_code_scanner,
          ),
        ),
      ),
    );
  }
}
