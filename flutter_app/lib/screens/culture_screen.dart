import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/coming_soon_card.dart';

class CultureScreen extends StatefulWidget {
  final Function(CulturalArticleItem article) onSelectArticle;

  const CultureScreen({Key? key, required this.onSelectArticle}) : super(key: key);

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  String _selectedCategory = 'All';
  List<CulturalArticleItem> _articles = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Markets', 'icon': Icons.sailing, 'color': MekongColors.clay},
    {'name': 'Heritage', 'icon': Icons.home_outlined, 'color': MekongColors.deltaBlue},
    {'name': 'Music', 'icon': Icons.music_note, 'color': MekongColors.mustard},
    {'name': 'Food', 'icon': Icons.restaurant, 'color': MekongColors.riverGreen},
    {'name': 'Words', 'icon': Icons.chat_bubble_outline, 'color': MekongColors.ink},
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles([String? category]) async {
    setState(() => _isLoading = true);
    final list = await ApiService.getCulturalArticles(category: category);
    if (mounted) {
      setState(() {
        _articles = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic word to learn derived from approved articles
    CulturalArticleItem? wordArticle;
    try {
      wordArticle = _articles.firstWhere(
        (a) => a.vietnameseWord != null && a.vietnameseWord!.trim().isNotEmpty,
      );
    } catch (_) {
      wordArticle = null;
    }

    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadArticles(_selectedCategory == 'All' ? null : _selectedCategory),
          color: MekongColors.riverGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deep green header
                Container(
                  color: MekongColors.riverGreen,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Culture',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Places and traditions from verified program sources.',
                        style: TextStyle(
                          color: Color(0xFFC7DEC9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Curved sheet content
                Container(
                  transform: Matrix4.translationValues(0, -12, 0),
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
                      // Browse by category
                      const Text(
                        'Browse by',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: MekongColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _categories.map((c) {
                          final isSelected = _selectedCategory == c['name'];
                          return InkWell(
                            onTap: () {
                              final newCat = isSelected ? 'All' : (c['name'] as String);
                              setState(() => _selectedCategory = newCat);
                              _loadArticles(newCat == 'All' ? null : newCat);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: c['color'] as Color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: MekongColors.ink, width: 3)
                                        : null,
                                  ),
                                  child: Icon(c['icon'] as IconData, color: Colors.white, size: 24),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: MekongColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Articles section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == 'All' ? 'All Articles' : _selectedCategory,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: MekongColors.ink,
                            ),
                          ),
                          Text(
                            '${_articles.length} articles',
                            style: const TextStyle(
                              color: MekongColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Grid or Coming Soon
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: MekongColors.riverGreen),
                          ),
                        )
                      else if (_articles.isEmpty)
                        ComingSoonCard(
                          message: 'No articles published in "${_selectedCategory}" yet.',
                          vietnameseMessage: 'Chưa có bài viết nào trong danh mục "${_selectedCategory}".',
                          icon: Icons.article_outlined,
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _articles.length,
                          itemBuilder: (context, index) {
                            return _buildArticleGridCard(_articles[index]);
                          },
                        ),

                      const SizedBox(height: 24),

                      // Dynamic Word to learn widget
                      if (wordArticle != null)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: MekongColors.straw,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Word to learn',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: MekongColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      wordArticle.vietnameseWord!,
                                      style: const TextStyle(
                                        fontFamily: 'Fraunces',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: MekongColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      wordArticle.wordTranslation ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: MekongColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: wordArticle!.vietnameseWord!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Copied "${wordArticle.vietnameseWord}" to clipboard!')),
                                  );
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: MekongColors.card,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.copy, color: MekongColors.ink, size: 20),
                                ),
                              ),
                            ],
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

  Widget _buildArticleGridCard(CulturalArticleItem art) {
    return InkWell(
      onTap: () => widget.onSelectArticle(art),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: MekongColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MekongColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 104,
              decoration: const BoxDecoration(
                color: Color(0xFFF7E8C8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  art.category.toLowerCase().contains('market')
                      ? Icons.sailing
                      : art.category.toLowerCase().contains('heritage')
                          ? Icons.home_work
                          : art.category.toLowerCase().contains('music')
                              ? Icons.music_note
                              : Icons.menu_book,
                  color: MekongColors.riverGreen,
                  size: 38,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MekongColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    art.sourceLabel.isNotEmpty ? art.sourceLabel : art.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MekongColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
