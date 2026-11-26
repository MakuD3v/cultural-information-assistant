import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/ticket_stub.dart';
import '../widgets/mekong_illustration.dart';

class CultureDetailScreen extends StatefulWidget {
  final CulturalArticleItem article;
  final VoidCallback onBack;
  final Function(String query) onAskAboutThis;
  final VoidCallback? onOpenMap;

  const CultureDetailScreen({
    Key? key,
    required this.article,
    required this.onBack,
    required this.onAskAboutThis,
    this.onOpenMap,
  }) : super(key: key);

  @override
  State<CultureDetailScreen> createState() => _CultureDetailScreenState();
}

class _CultureDetailScreenState extends State<CultureDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasWord = widget.article.vietnameseWord != null &&
        widget.article.vietnameseWord!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top illustration with back button
              Stack(
                children: [
                  const MekongIllustration(height: 180),
                  Positioned(
                    top: 14,
                    left: 16,
                    child: InkWell(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MekongColors.card.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: MekongColors.ink, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              // Curved sheet content
              Container(
                transform: Matrix4.translationValues(0, -20, 0),
                decoration: const BoxDecoration(
                  color: MekongColors.paper,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.title,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.article.category} · ${widget.article.sourceAuthor} (${widget.article.sourceDate})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: MekongColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tabs: Overview, Facts, Words, Sources
                    TabBar(
                      controller: _tabController,
                      labelColor: MekongColors.clay,
                      unselectedLabelColor: MekongColors.muted,
                      indicatorColor: MekongColors.clay,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Facts'),
                        Tab(text: 'Words'),
                        Tab(text: 'Sources'),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      height: 260,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Overview
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.summary,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: MekongColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  widget.article.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: MekongColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Facts
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                if (widget.article.fact1 != null && widget.article.fact1!.isNotEmpty) ...[
                                  _buildFactCard('Fact 1', widget.article.fact1!, MekongColors.straw),
                                  const SizedBox(height: 10),
                                ],
                                if (widget.article.fact2 != null && widget.article.fact2!.isNotEmpty)
                                  _buildFactCard('Fact 2', widget.article.fact2!, const Color(0xFFD4E7F2)),
                                if ((widget.article.fact1 == null || widget.article.fact1!.isEmpty) &&
                                    (widget.article.fact2 == null || widget.article.fact2!.isEmpty))
                                  const Text(
                                    'Coming soon · Sắp ra mắt',
                                    style: TextStyle(color: MekongColors.muted),
                                  ),
                              ],
                            ),
                          ),

                          // Words
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasWord)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: MekongColors.card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: MekongColors.divider),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.article.vietnameseWord!,
                                            style: const TextStyle(
                                              fontFamily: 'Fraunces',
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: MekongColors.ink,
                                            ),
                                          ),
                                          Text(
                                            widget.article.wordTranslation ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: MekongColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, color: MekongColors.ink),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: widget.article.vietnameseWord!));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Copied word to clipboard!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Text(
                                  'Coming soon · Sắp ra mắt',
                                  style: TextStyle(color: MekongColors.muted),
                                ),
                            ],
                          ),

                          // Sources
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.sourceTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: MekongColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Author: ${widget.article.sourceAuthor} (${widget.article.sourceDate})',
                                  style: const TextStyle(fontSize: 13, color: MekongColors.muted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${widget.article.status.toUpperCase()}',
                                  style: const TextStyle(fontSize: 13, color: MekongColors.riverGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (widget.article.sourceLabel.isNotEmpty)
                      SourceTicketStub(
                        code: widget.article.sourceDate.isNotEmpty ? widget.article.sourceDate : 'SRC',
                        label: widget.article.sourceLabel,
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => widget.onAskAboutThis('Tell me about ${widget.article.title}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MekongColors.clay,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Ask the guide about this',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (widget.onOpenMap != null) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: widget.onOpenMap,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                border: Border.all(color: MekongColors.divider, width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.map_outlined, color: MekongColors.ink),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactCard(String title, String fact, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MekongColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fact,
            style: const TextStyle(
              fontSize: 14,
              color: MekongColors.ink,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
