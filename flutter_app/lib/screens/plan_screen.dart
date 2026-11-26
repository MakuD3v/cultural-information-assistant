import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/coming_soon_card.dart';

class PlanScreen extends StatefulWidget {
  final UserProfile user;
  final Function(ItineraryActivityItem activity)? onSelectActivity;

  const PlanScreen({Key? key, required this.user, this.onSelectActivity}) : super(key: key);

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _selectedDay = 1;
  List<ItineraryActivityItem> _activities = [];
  Map<String, dynamic>? _broadcastNotice;
  String? _lastUpdatedLabel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlan();
  }

  void _initPlan() async {
    final notice = await ApiService.getBroadcast();
    final meta = await ApiService.getOfflineScheduleMeta();
    final defaultDay = (notice != null && notice['day_number'] is int)
        ? notice['day_number'] as int
        : 1;
    if (mounted) {
      setState(() {
        _broadcastNotice = notice;
        _selectedDay = defaultDay;
        _lastUpdatedLabel = (meta != null && (meta['last_updated'] ?? '').toString().isNotEmpty)
            ? meta['last_updated'].toString()
            : null;
      });
    }
    _loadDayActivities(defaultDay);
  }

  void _loadBroadcast() async {
    final notice = await ApiService.getBroadcast();
    if (mounted) {
      setState(() => _broadcastNotice = notice);
    }
  }

  void _loadDayActivities(int day) async {
    setState(() => _isLoading = true);
    final items = await ApiService.getItinerary(day: day);
    if (mounted) {
      setState(() {
        _selectedDay = day;
        _activities = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastMsg = (_broadcastNotice?['message'] as String? ?? '').trim();
    final broadcastTime = (_broadcastNotice?['time_label'] as String? ?? '').trim();

    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadBroadcast();
            _loadDayActivities(_selectedDay);
          },
          color: MekongColors.riverGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deep green header
                Container(
                  color: MekongColors.riverGreen,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Plan',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.cohort.isNotEmpty
                            ? 'Day $_selectedDay · ${widget.user.cohort}'
                            : 'Day $_selectedDay',
                        style: const TextStyle(
                          color: Color(0xFFC7DEC9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Day pills Day 1 .. Day 7
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(7, (index) {
                            final dayNum = index + 1;
                            final isSelected = dayNum == _selectedDay;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () => _loadDayActivities(dayNum),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 52,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected ? MekongColors.clay : Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Day',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFFC7DEC9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$dayNum',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
                      // Coordinator broadcast banner if present
                      if (broadcastMsg.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: MekongColors.mustard,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notifications_active, color: MekongColors.ink, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  broadcastTime.isNotEmpty
                                      ? 'Coordinator update, $broadcastTime. $broadcastMsg'
                                      : 'Coordinator update: $broadcastMsg',
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
                        const SizedBox(height: 20),
                      ],

                      // Day activities header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Day $_selectedDay',
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: MekongColors.ink,
                            ),
                          ),
                          Text(
                            '${_activities.length} ${_activities.length == 1 ? 'activity' : 'activities'}',
                            style: const TextStyle(
                              color: MekongColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Activities list or Coming Soon
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: MekongColors.riverGreen),
                          ),
                        )
                      else if (_activities.isEmpty)
                        ComingSoonCard(
                          message: 'No activities scheduled for Day $_selectedDay.',
                          vietnameseMessage: 'Chưa có lịch trình hoạt động nào cho Ngày $_selectedDay.',
                          icon: Icons.calendar_today,
                        )
                      else ...[
                        ..._activities.map((act) => _buildPlanCard(act)),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _lastUpdatedLabel != null
                                ? 'Updated by coordinator ($_lastUpdatedLabel) · Works offline'
                                : 'Synced from coordinator console · Works offline',
                            style: TextStyle(
                              color: MekongColors.muted.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPlanCard(ItineraryActivityItem act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (widget.onSelectActivity != null) {
            widget.onSelectActivity!(act);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MekongColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MekongColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 52,
                decoration: BoxDecoration(
                  color: MekongColors.straw,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    act.startTime,
                    style: const TextStyle(
                      color: MekongColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.title,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${act.venueName} · ${act.targetAudience}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: MekongColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MekongColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
