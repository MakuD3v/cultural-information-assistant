import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/ticket_stub.dart';

class GuideScreen extends StatefulWidget {
  final String? initialQuery;

  const GuideScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOffline = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _sendMessage(widget.initialQuery!);
    }
  }

  void _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    _inputController.clear();

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': query,
      });
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await ApiService.askGuide(query, offlineMode: _isOffline);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'sender': 'guide',
          'status': response['status'] ?? 'success',
          'source_type': response['source_type'] ?? 'schedule',
          'source_stub': response['source_stub'],
          'answer': response['answer'] ?? '',
          'note': response['note'],
          'steps': List<String>.from(response['steps'] ?? []),
          'show_steps': false,
          'try_next': List<String>.from(response['try_next'] ?? []),
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Deep green header matching PDF pages 4, 5, 6
            Container(
              color: MekongColors.riverGreen,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ask the guide',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      // Online / Offline toggle pill
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isOffline = !_isOffline;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isOffline ? MekongColors.mustard : const Color(0xFF55D46B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOffline ? 'Offline' : 'Online',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Automated guide. Answers come only from your schedule and the approved Can Tho articles.',
                    style: TextStyle(
                      color: Color(0xFFC7DEC9),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Offline banner if active
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: MekongColors.mustard,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wifi_off, color: MekongColors.ink, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You're offline. Searching the saved exchange schedule.",
                        style: TextStyle(
                          color: MekongColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Quick suggestion chips: Today, Tomorrow, Now and next
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChip('Today', () => _sendMessage('What is on today?')),
                    const SizedBox(width: 8),
                    _buildQuickChip('Tomorrow', () => _sendMessage("What's on tomorrow?")),
                    const SizedBox(width: 8),
                    _buildQuickChip('Now and next', () => _sendMessage('Now and next')),
                  ],
                ),
              ),
            ),

            // Chat messages view
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Automated Can Tho Guide',
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: MekongColors.ink,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ask about the exchange itinerary or verified Can Tho culture.\nHỏi về lịch trình giao lưu hoặc văn hóa Cần Thơ đã kiểm duyệt.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13.5, color: MekongColors.muted, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        if (msg['sender'] == 'user') {
                          return _buildUserBubble(msg['text']);
                        } else {
                          return _buildGuideCard(msg);
                        }
                      },
                    ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),

            // Bottom Input bar matching PDF pages 4, 5, 6
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: MekongColors.paper,
                border: Border(top: BorderSide(color: MekongColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: MekongColors.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: MekongColors.divider, width: 1.2),
                      ),
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: _sendMessage,
                        style: const TextStyle(fontSize: 14, color: MekongColors.ink),
                        decoration: InputDecoration(
                          hintText: _isOffline 
                              ? 'Type a date or a place name' 
                              : 'Ask about the schedule or Can Tho',
                          hintStyle: TextStyle(color: MekongColors.muted.withOpacity(0.8), fontSize: 13.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _sendMessage(_inputController.text),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: MekongColors.clay,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: MekongColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MekongColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MekongColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: MekongColors.riverGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> msg) {
    final status = msg['status'] as String? ?? 'success';
    final isUnsupported = status == 'not_in_sources';
    final isOffline = status == 'offline';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MekongColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MekongColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stub / badge
          if (isUnsupported) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: MekongColors.straw,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Not in my sources',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MekongColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (isOffline) ...[
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: MekongColors.muted),
                SizedBox(width: 6),
                Text(
                  'From the saved schedule',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MekongColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            Row(
              children: [
                Icon(
                  msg['source_type'] == 'culture' ? Icons.menu_book : Icons.calendar_today,
                  size: 16,
                  color: MekongColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  msg['source_type'] == 'culture' ? 'From Can Tho articles' : 'From the itinerary',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MekongColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Answer text
          Text(
            msg['answer'] as String,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: MekongColors.ink,
            ),
          ),
          const SizedBox(height: 14),

          // Citation stub if available
          if (msg['source_stub'] != null && !isUnsupported) ...[
            SourceTicketStub(
              label: msg['source_stub'] as String,
            ),
            const SizedBox(height: 10),
          ],

          // Coordinator note
          if (msg['note'] != null) ...[
            Text(
              msg['note'] as String,
              style: const TextStyle(
                fontSize: 12,
                color: MekongColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Contact coordinator button if unsupported (PDF page 5)
          if (isUnsupported) ...[
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to SorSU-CTU Exchange Secretariat (+84 292 3832 663)...')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MekongColors.riverGreen, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Contact your coordinator',
                style: TextStyle(
                  color: MekongColors.riverGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // How I answered accordion matching PDF pages 4, 5
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Icon(Icons.alt_route, color: MekongColors.deltaBlue, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'How I answered',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MekongColors.deltaBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: MekongColors.muted),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback saved. Thank you!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 16, color: MekongColors.muted),
                    onPressed: () {},
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MekongColors.paper,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (msg['steps'] as List<String>? ?? []).asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: MekongColors.riverGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12, color: MekongColors.ink, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Try next chips
          if (msg['try_next'] != null && (msg['try_next'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isUnsupported ? 'Try asking' : 'Try next',
              style: const TextStyle(fontSize: 12, color: MekongColors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (msg['try_next'] as List<String>).map((nextQ) {
                return InkWell(
                  onTap: () => _sendMessage(nextQ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MekongColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MekongColors.divider),
                    ),
                    child: Text(
                      nextQ,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MekongColors.ink),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
