import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MoreScreen extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onSignOut;
  final VoidCallback onOpenApprovedSources;

  const MoreScreen({
    Key? key,
    required this.user,
    required this.onSignOut,
    required this.onOpenApprovedSources,
  }) : super(key: key);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _showHowIAnswered = true;
  bool _keepScheduleOffline = true;
  bool _isLargeText = false;

  int _articleCount = 0;
  String _sourcesLabel = 'Coming soon · Sắp ra mắt';
  String _itineraryLabel = 'Coming soon · Sắp ra mắt';
  String _offlineSavedLabel = 'Coming soon · Sắp ra mắt';

  @override
  void initState() {
    super.initState();
    _loadDynamicCounts();
  }

  Future<void> _loadDynamicCounts() async {
    final results = await Future.wait([
      ApiService.getCulturalArticles(),
      ApiService.getOfflineScheduleMeta(),
    ]);

    if (!mounted) return;
    final articles = results[0] as List<CulturalArticleItem>;
    final meta = results[1] as Map<String, dynamic>?;

    final sourceLabels = articles
        .map((a) => a.sourceLabel)
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _articleCount = articles.length;
      if (articles.isEmpty) {
        _sourcesLabel = 'Coming soon · Sắp ra mắt';
      } else {
        _sourcesLabel = sourceLabels.take(2).join(', ') +
            (sourceLabels.length > 2 ? ' +${sourceLabels.length - 2} more' : '');
      }

      if (meta != null && (meta['total_activities'] ?? 0) > 0) {
        final total = meta['total_activities'];
        final ver = meta['version'] ?? 1;
        final updated = (meta['last_updated'] ?? '').toString();
        _itineraryLabel = '$total activities · v$ver${updated.isNotEmpty ? ' ($updated)' : ''}';
        _offlineSavedLabel = updated.isNotEmpty ? 'Saved $updated' : 'Synced';
      } else {
        _itineraryLabel = 'Coming soon · Sắp ra mắt';
        _offlineSavedLabel = 'Coming soon · Sắp ra mắt';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDynamicCounts,
          color: MekongColors.riverGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // River green header with user badge
                Container(
                  color: MekongColors.riverGreen,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: MekongColors.mustard,
                        child: Text(
                          widget.user.avatarInitials,
                          style: const TextStyle(
                            color: MekongColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.user.role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.user.cohort,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFC7DEC9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Curved sheet content
                Container(
                  transform: Matrix4.translationValues(0, -14, 0),
                  decoration: const BoxDecoration(
                    color: MekongColors.paper,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What the guide knows',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: MekongColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Program itinerary item (dynamic)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MekongColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MekongColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: MekongColors.clay,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Program itinerary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: MekongColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _itineraryLabel,
                                    style: const TextStyle(fontSize: 13, color: MekongColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Approved articles item (dynamic)
                      InkWell(
                        onTap: widget.onOpenApprovedSources,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MekongColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: MekongColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, color: MekongColors.deltaBlue, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_articleCount approved ${_articleCount == 1 ? 'article' : 'articles'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: MekongColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _sourcesLabel,
                                      style: const TextStyle(fontSize: 13, color: MekongColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: MekongColors.muted),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Settings card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: MekongColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: MekongColors.divider),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Show how I answered',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MekongColors.ink),
                                    ),
                                    SizedBox(height: 2),
                                    Text('Steps under every answer', style: TextStyle(fontSize: 13, color: MekongColors.muted)),
                                  ],
                                ),
                                Switch(
                                  value: _showHowIAnswered,
                                  activeColor: MekongColors.riverGreen,
                                  onChanged: (val) => setState(() => _showHowIAnswered = val),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: MekongColors.divider),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Keep schedule offline',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MekongColors.ink),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(_offlineSavedLabel, style: const TextStyle(fontSize: 13, color: MekongColors.muted)),
                                  ],
                                ),
                                Switch(
                                  value: _keepScheduleOffline,
                                  activeColor: MekongColors.riverGreen,
                                  onChanged: (val) => setState(() => _keepScheduleOffline = val),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: MekongColors.divider),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Text size',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MekongColors.ink),
                                ),
                                Row(
                                  children: [
                                    _buildTextSizeBtn('A', 14, !_isLargeText, () => setState(() => _isLargeText = false)),
                                    const SizedBox(width: 8),
                                    _buildTextSizeBtn('A', 18, _isLargeText, () => setState(() => _isLargeText = true)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Privacy notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MekongColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MekongColors.divider),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline, color: MekongColors.muted, size: 18),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privacy',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: MekongColors.ink),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'We keep your name, email and role. Questions you type are saved without your name.',
                                    style: TextStyle(fontSize: 12.5, color: MekongColors.muted, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign out button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: widget.onSignOut,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: MekongColors.riverGreen, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: const Text(
                            'Sign out',
                            style: TextStyle(
                              color: MekongColors.riverGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextSizeBtn(String label, double fontSize, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? MekongColors.riverGreen : MekongColors.paper,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : MekongColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
