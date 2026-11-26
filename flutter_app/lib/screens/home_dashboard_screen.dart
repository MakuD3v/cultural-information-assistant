import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  final UserProfile user;
  final Function(int tabIndex) onNavigateTab;
  final Function(CulturalArticleItem article) onOpenArticle;

  const HomeDashboardScreen({
    Key? key,
    required this.user,
    required this.onNavigateTab,
    required this.onOpenArticle,
  }) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Map<String, dynamic>? _broadcastNotice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBroadcast();
  }

  void _loadBroadcast() async {
    final broadcast = await ApiService.getBroadcast();
    if (mounted) {
      setState(() {
        _broadcastNotice = broadcast;
        _isLoading = false;
      });
    }
  }

  void _showScanWipDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: MekongColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MekongColors.straw,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: MekongColors.ink, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Scanner',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.ink,
                      ),
                    ),
                    Text(
                      'Work in progress · Sắp ra mắt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.clay,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Field verification badges and physical plaque scanning for Can Tho heritage sites will be activated in the next release.',
              style: TextStyle(fontSize: 14, color: MekongColors.ink, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Tính năng quét mã QR tại các điểm di tích Cần Thơ đang được hoàn thiện.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: MekongColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MekongColors.riverGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Close / Đóng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBroadcast = _broadcastNotice != null &&
        (_broadcastNotice!['message'] as String? ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: MekongColors.riverGreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar: greeting + avatar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning,',
                        style: TextStyle(color: Color(0xFFC7DEC9), fontSize: 14),
                      ),
                      Text(
                        widget.user.fullName.split(' ').first,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.user.cohort,
                        style: const TextStyle(color: Color(0xFFC7DEC9), fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _loadBroadcast,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => widget.onNavigateTab(5),
                        borderRadius: BorderRadius.circular(21),
                        child: CircleAvatar(
                          radius: 21,
                          backgroundColor: MekongColors.mustard,
                          child: Text(
                            widget.user.avatarInitials,
                            style: const TextStyle(
                              color: MekongColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Search bar → routes to Ask guide ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GestureDetector(
                onTap: () => widget.onNavigateTab(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MekongColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: MekongColors.muted, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ask the guide about schedules, places, words...',
                          style: TextStyle(color: MekongColors.muted, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Spacer pushes tiles to vertical centre ──
            const Spacer(),

            // ── The 4 navigation tiles ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where to?',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7DEC9),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Plan',
                        sublabel: 'Itinerary',
                        bgColor: MekongColors.clay,
                        onTap: () => widget.onNavigateTab(1),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _buildTile(
                        icon: Icons.map_outlined,
                        label: 'Map',
                        sublabel: 'Locations',
                        bgColor: MekongColors.deltaBlue,
                        onTap: () => widget.onNavigateTab(3),
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildTile(
                        icon: Icons.menu_book_outlined,
                        label: 'Culture',
                        sublabel: 'Articles',
                        bgColor: const Color(0xFF8B6914),
                        onTap: () => widget.onNavigateTab(4),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _buildTile(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan',
                        sublabel: 'Coming soon',
                        bgColor: MekongColors.ink.withOpacity(0.45),
                        onTap: _showScanWipDialog,
                        isWip: true,
                      )),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Coordinator broadcast banner (dynamic, only if present) ──
            if (!_isLoading && hasBroadcast)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MekongColors.mustard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active, color: MekongColors.ink, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_broadcastNotice!['time_label'] ?? ''} · ${_broadcastNotice!['message']}',
                          style: const TextStyle(
                            color: MekongColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Coming soon card if no broadcast and nothing loaded ──
            if (!_isLoading && !hasBroadcast)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Coming soon · Sắp ra mắt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Coordinator updates will appear here · Thông báo sẽ sớm cập nhật',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFC7DEC9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color bgColor,
    required VoidCallback onTap,
    bool isWip = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                if (isWip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'WIP',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Fraunces',
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
