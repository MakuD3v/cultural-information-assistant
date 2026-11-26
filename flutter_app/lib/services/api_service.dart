import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  // Cache for offline operations
  static List<ItineraryActivityItem> _offlineCachedSchedule = [];

  static Future<UserProfile?> login(String inviteCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'invite_code': inviteCode}),
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<ItineraryActivityItem>> getItinerary({int? day}) async {
    try {
      final url = day != null 
          ? '$baseUrl/api/itinerary?day=$day' 
          : '$baseUrl/api/itinerary';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final items = decoded.map((e) => ItineraryActivityItem.fromJson(e)).toList();
          _offlineCachedSchedule = items;
          return items;
        }
      }
    } catch (_) {
      if (_offlineCachedSchedule.isNotEmpty) {
        if (day != null) {
          return _offlineCachedSchedule.where((a) => a.dayNumber == day).toList();
        }
        return _offlineCachedSchedule;
      }
    }
    // No hardcoded data: return empty list if server has nothing or is unreachable
    return [];
  }

  static Future<List<CulturalArticleItem>> getCulturalArticles({String? category}) async {
    try {
      final url = (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
          ? '$baseUrl/api/culture/articles?category=${Uri.encodeComponent(category)}'
          : '$baseUrl/api/culture/articles';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => CulturalArticleItem.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    // No hardcoded data: return empty list if server has nothing
    return [];
  }

  static Future<CulturalArticleItem?> getLatestCulture() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/culture/latest'));
      if (response.statusCode == 200) {
        return CulturalArticleItem.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getBroadcast() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/broadcast'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<LocationItem>> getLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/locations'));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => LocationItem.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getOfflineScheduleMeta() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/itinerary/sync-offline'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> askGuide(String question, {bool offlineMode = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/guide/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'offline_mode': offlineMode,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    return {
      'question': question,
      'answer': "Offline schedule cache used. Could not reach server for dynamic cultural answers.",
      'source_type': 'schedule',
      'source_stub': 'Offline Cache',
      'status': 'offline',
      'steps': [
        'Device offline: local schedule storage queried.',
      ],
      'response_time_sec': 0.05,
      'try_next': ['Today', 'Tomorrow'],
    };
  }
}
