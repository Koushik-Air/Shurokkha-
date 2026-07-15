class SosEvent {
  final String id;
  final String userId;
  final String status; // active, cancelled, resolved
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? audioUrl;
  final List<String> contactsNotified;

  SosEvent({
    required this.id,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.audioUrl,
    required this.contactsNotified,
  });

  static const String kStatusActive = 'active';
  static const String kStatusCancelled = 'cancelled';
  static const String kStatusResolved = 'resolved';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'audioUrl': audioUrl,
      'contactsNotified': contactsNotified,
    };
  }

  factory SosEvent.fromMap(Map<String, dynamic> map) {
    return SosEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? '',
      startedAt: DateTime.parse(map['startedAt']),
      endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
      audioUrl: map['audioUrl'],
      contactsNotified: List<String>.from(map['contactsNotified'] ?? []),
    );
  }
}
