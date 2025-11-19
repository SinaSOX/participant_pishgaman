class FeedbackEntry {
  final int id;
  final String userIdentifier;
  final String category;
  final String subject;
  final String message;
  final String? contactInfo;
  final String status;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FeedbackEntry({
    required this.id,
    required this.userIdentifier,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    this.contactInfo,
    this.adminNote,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return FeedbackEntry(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      userIdentifier: json['user_identifier']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      contactInfo: json['contact_info']?.toString(),
      status: json['status']?.toString() ?? '',
      adminNote: json['admin_note']?.toString(),
      createdAt: parseDate(json['created_at']?.toString()),
      updatedAt: parseDate(json['updated_at']?.toString()),
    );
  }
}



