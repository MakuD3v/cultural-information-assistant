import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/coming_soon_card.dart';

class MapScreen extends StatefulWidget {
  final Function(String query)? onAskAbout;

  const MapScreen({Key? key, this.onAskAbout}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _activeFilter = 'Today';
  List<LocationItem> _allLocations = [];
  Set<String> _todayLocationIds = {};
  Set<String> _cultureLocationIds = {};
  int _selectedPinIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    final broadcast = await ApiService.getBroadcast();
    final activeDay = (broadcast != null && broadcast['day_number'] is int)
        ? broadcast['day_number'] as int
        : 1;

    final results = await Future.wait([
      ApiService.getLocations(),
      ApiService.getItinerary(day: activeDay),
      ApiService.getCulturalArticles(),
    ]);

    if (!mounted) return;
    final locs = results[0] as List<LocationItem>;
    final todayActs = results[1] as List<ItineraryActivityItem>;
    final arts = results[2] as List<CulturalArticleItem>;

    setState(() {
      _allLocations = locs;
      _todayLocationIds = todayActs.map((a) => a.locationId ?? '').where((id) => id.isNotEmpty).toSet();
      _cultureLocationIds = arts.map((a) => a.locationId ?? '').where((id) => id.isNotEmpty).toSet();
      _selectedPinIndex = 0;
      _isLoading = false;
    });
  }

  List<LocationItem> get _filteredLocations {
    if (_activeFilter == 'Today') {
      return _allLocations.where((l) => _todayLocationIds.contains(l.locationId)).toList();
    } else if (_activeFilter == 'Culture sites') {
      return _allLocations.where((l) => _cultureLocationIds.contains(l.locationId)).toList();
    }
    return _allLocations;
  }

  @override
  Widget build(BuildContext context) {
    final visibleLocations = _filteredLocations;
    final safeIdx = visibleLocations.isEmpty
        ? 0
        : _selectedPinIndex.clamp(0, visibleLocations.length - 1);
    final selectedLoc = visibleLocations.isNotEmpty ? visibleLocations[safeIdx] : null;

    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            // Dynamic Schematic Map Canvas driven purely by PostgreSQL records
            Positioned.fill(
              child: CustomPaint(
                painter: SchematicMapPainter(
                  locations: visibleLocations,
                  selectedIndex: safeIdx,
                ),
              ),
            ),

            // Top Filter Chips: Today, All days, Culture sites
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  _buildChip('Today', _activeFilter == 'Today', () {
                    setState(() {
                      _activeFilter = 'Today';
                      _selectedPinIndex = 0;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildChip('All days', _activeFilter == 'All days', () {
                    setState(() {
                      _activeFilter = 'All days';
                      _selectedPinIndex = 0;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildChip('Culture sites', _activeFilter == 'Culture sites', () {
                    setState(() {
                      _activeFilter = 'Culture sites';
                      _selectedPinIndex = 0;
                    });
                  }),
                  const Spacer(),
                  InkWell(
                    onTap: _loadMapData,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MekongColors.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.refresh, color: MekongColors.ink, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const Positioned(
              top: 76,
              left: 20,
              child: Text(
                'Schematic map',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MekongColors.muted,
                ),
              ),
            ),

            // Bottom Card or Bilingual Coming Soon
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: MekongColors.riverGreen))
                  : selectedLoc == null
                      ? ComingSoonCard(
                          message: _allLocations.isEmpty
                              ? 'No map landmarks have been added yet.'
                              : 'No landmarks mapped for "$_activeFilter".',
                          vietnameseMessage: _allLocations.isEmpty
                              ? 'Chưa có địa điểm nào trên bản đồ.'
                              : 'Chưa có địa điểm nào cho bộ lọc này.',
                          icon: Icons.map_outlined,
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: MekongColors.card,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: MekongColors.divider,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Pin selector chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(visibleLocations.length, (idx) {
                                    final item = visibleLocations[idx];
                                    final isSel = idx == safeIdx;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedPinIndex = idx),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isSel ? MekongColors.clay : MekongColors.paper,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSel ? MekongColors.clay : MekongColors.divider,
                                            ),
                                          ),
                                          child: Text(
                                            '${idx + 1}. ${item.mapReference ?? item.name}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSel ? Colors.white : MekongColors.ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: MekongColors.clay,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${safeIdx + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedLoc.name,
                                          style: const TextStyle(
                                            fontFamily: 'Fraunces',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: MekongColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedLoc.address ?? selectedLoc.mapReference ?? 'Can Tho',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: MekongColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: MekongColors.card,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          builder: (ctx) => Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedLoc.name,
                                                  style: const TextStyle(
                                                    fontFamily: 'Fraunces',
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  selectedLoc.address ?? '',
                                                  style: const TextStyle(color: MekongColors.muted),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(selectedLoc.description ?? ''),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                      label: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MekongColors.riverGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        if (widget.onAskAbout != null) {
                                          widget.onAskAbout!('Tell me about ${selectedLoc.name}');
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: MekongColors.ink,
                                        side: const BorderSide(color: MekongColors.divider, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Ask about this', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? MekongColors.riverGreen : MekongColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? MekongColors.riverGreen : MekongColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : MekongColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class SchematicMapPainter extends CustomPainter {
  final List<LocationItem> locations;
  final int selectedIndex;

  SchematicMapPainter({required this.locations, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFEBE3D3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green terrain blocks
    final greenZonePaint = Paint()..color = const Color(0xFFC7D7BE);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.14, 90, 80), const Radius.circular(30)), greenZonePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.65, size.height * 0.42, 110, 90), const Radius.circular(30)), greenZonePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-20, size.height * 0.48, 130, 110), const Radius.circular(36)), greenZonePaint);

    // Hau River
    final riverPaint = Paint()
      ..color = const Color(0xFF86AEC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(-20, size.height * 0.24);
    riverPath.quadraticBezierTo(size.width * 0.30, size.height * 0.18, size.width * 0.55, size.height * 0.21);
    riverPath.quadraticBezierTo(size.width * 0.80, size.height * 0.24, size.width * 0.88, size.height * 0.36);
    riverPath.quadraticBezierTo(size.width * 0.70, size.height * 0.50, size.width * 0.75, size.height * 0.68);
    canvas.drawPath(riverPath, riverPaint);

    const riverTextSpan = TextSpan(
      text: 'Hau River',
      style: TextStyle(color: Color(0xFF33586E), fontSize: 12, fontWeight: FontWeight.w700),
    );
    final riverPainter = TextPainter(text: riverTextSpan, textDirection: TextDirection.ltr);
    riverPainter.layout();
    riverPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.18));

    // Schematic roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.34, size.height * 0.26), Offset(size.width * 0.24, size.height * 0.66), roadPaint);
    canvas.drawLine(Offset(size.width * 0.12, size.height * 0.44), Offset(size.width * 0.88, size.height * 0.46), roadPaint);

    if (locations.isEmpty) return;

    final coords = locations.where((l) => l.latitude != null && l.longitude != null).toList();
    double minLat = coords.isNotEmpty ? coords.map((l) => l.latitude!).reduce(math.min) - 0.006 : 9.99;
    double maxLat = coords.isNotEmpty ? coords.map((l) => l.latitude!).reduce(math.max) + 0.006 : 10.08;
    double minLng = coords.isNotEmpty ? coords.map((l) => l.longitude!).reduce(math.min) - 0.006 : 105.73;
    double maxLng = coords.isNotEmpty ? coords.map((l) => l.longitude!).reduce(math.max) + 0.006 : 105.80;

    final left = 48.0;
    final right = size.width - 64.0;
    final top = 115.0;
    final bottom = math.max(size.height - 250.0, 260.0);

    final points = <Offset>[];
    for (int i = 0; i < locations.length; i++) {
      final loc = locations[i];
      if (loc.latitude != null && loc.longitude != null && maxLng > minLng && maxLat > minLat) {
        final nx = (loc.longitude! - minLng) / (maxLng - minLng);
        final ny = 1 - (loc.latitude! - minLat) / (maxLat - minLat);
        points.add(Offset(left + nx * (right - left), top + ny * (bottom - top)));
      } else {
        final col = i % 3;
        final row = i ~/ 3;
        points.add(Offset(left + ((col + 0.5) / 3) * (right - left), top + ((row + 0.5) / 3) * (bottom - top)));
      }
    }

    if (points.length > 1) {
      final dashPaint = Paint()
        ..color = MekongColors.ink.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < points.length - 1; i++) {
        _drawDashedLine(canvas, points[i], points[i + 1], dashPaint);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final isSel = i == selectedIndex;
      _drawPin(canvas, points[i], '${i + 1}', isSel ? MekongColors.clay : MekongColors.deltaBlue, isSel);
      final label = locations[i].mapReference ?? locations[i].name;
      _drawText(canvas, label, Offset(points[i].dx + 18, points[i].dy - 7), isSel);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    final total = (p2 - p1).distance;
    if (total == 0) return;
    double current = 0;
    while (current < total) {
      final s = current / total;
      final e = math.min((current + dashWidth) / total, 1.0);
      canvas.drawLine(Offset.lerp(p1, p2, s)!, Offset.lerp(p1, p2, e)!, paint);
      current += dashWidth + dashSpace;
    }
  }

  void _drawPin(Canvas canvas, Offset pos, String label, Color color, bool isSelected) {
    if (isSelected) {
      canvas.drawCircle(pos, 22, Paint()..color = MekongColors.clay.withOpacity(0.22));
    }
    canvas.drawCircle(pos, 15, Paint()..color = color);
    canvas.drawCircle(pos, 15, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    final span = TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700));
    final p = TextPainter(text: span, textDirection: TextDirection.ltr);
    p.layout();
    p.paint(canvas, Offset(pos.dx - p.width / 2, pos.dy - p.height / 2));
  }

  void _drawText(Canvas canvas, String text, Offset pos, bool isBold) {
    final span = TextSpan(
      text: text,
      style: TextStyle(color: MekongColors.ink, fontSize: isBold ? 12 : 11, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600),
    );
    final p = TextPainter(text: span, textDirection: TextDirection.ltr);
    p.layout();
    p.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant SchematicMapPainter oldDelegate) => true;
}
