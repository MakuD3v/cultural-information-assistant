class UserProfile {
  final int id;
  final String inviteCode;
  final String fullName;
  final String email;
  final String role;
  final String cohort;
  final String avatarInitials;

  UserProfile({
    required this.id,
    required this.inviteCode,
    required this.fullName,
    required this.email,
    required this.role,
    required this.cohort,
    required this.avatarInitials,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fullName = (json['full_name'] ?? '').toString();
    final fallbackInitials = fullName.isNotEmpty
        ? fullName.trim().split(RegExp(r'\s+')).map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : '';
    return UserProfile(
      id: json['id'] ?? 0,
      inviteCode: json['invite_code'] ?? '',
      fullName: fullName,
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      cohort: json['cohort'] ?? '',
      avatarInitials: (json['avatar_initials'] ?? '').toString().isNotEmpty
          ? json['avatar_initials']
          : fallbackInitials,
    );
  }
}

class ItineraryActivityItem {
  final String activityId;
  final int dayNumber;
  final String date;
  final String startTime;
  final String? endTime;
  final String title;
  final String venueName;
  final String targetAudience;
  final String? description;
  final String? locationId;
  final String status;
  final int version;
  final int displayOrder;

  ItineraryActivityItem({
    required this.activityId,
    required this.dayNumber,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.title,
    required this.venueName,
    required this.targetAudience,
    this.description,
    this.locationId,
    required this.status,
    required this.version,
    required this.displayOrder,
  });

  factory ItineraryActivityItem.fromJson(Map<String, dynamic> json) {
    return ItineraryActivityItem(
      activityId: json['activity_id'] ?? '',
      dayNumber: json['day_number'] ?? 1,
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      title: json['title'] ?? '',
      venueName: json['venue_name'] ?? '',
      targetAudience: json['target_audience'] ?? 'Everyone',
      description: json['description'],
      locationId: json['location_id'],
      status: json['status'] ?? 'published',
      version: json['version'] ?? 1,
      displayOrder: json['display_order'] ?? 1,
    );
  }
}

class CulturalArticleItem {
  final String contentId;
  final String title;
  final String category;
  final String summary;
  final String content;
  final String? fact1;
  final String? fact2;
  final String? vietnameseWord;
  final String? wordTranslation;
  final String sourceTitle;
  final String sourceAuthor;
  final String sourceDate;
  final String sourceLabel;
  final String? locationId;
  final String status;

  CulturalArticleItem({
    required this.contentId,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    this.fact1,
    this.fact2,
    this.vietnameseWord,
    this.wordTranslation,
    required this.sourceTitle,
    required this.sourceAuthor,
    required this.sourceDate,
    required this.sourceLabel,
    this.locationId,
    required this.status,
  });

  factory CulturalArticleItem.fromJson(Map<String, dynamic> json) {
    return CulturalArticleItem(
      contentId: json['content_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      fact1: json['fact_1'],
      fact2: json['fact_2'],
      vietnameseWord: json['vietnamese_word'],
      wordTranslation: json['word_translation'],
      sourceTitle: json['source_title'] ?? '',
      sourceAuthor: json['source_author'] ?? '',
      sourceDate: json['source_date'] ?? '',
      sourceLabel: json['source_label'] ?? '',
      locationId: json['location_id'],
      status: json['status'] ?? 'published',
    );
  }
}

class LocationItem {
  final String locationId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? mapReference;
  final String? description;

  LocationItem({
    required this.locationId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.mapReference,
    this.description,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      locationId: json['location_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapReference: json['map_reference'],
      description: json['description'],
    );
  }
}
