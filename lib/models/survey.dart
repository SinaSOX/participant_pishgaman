class Survey {
  final int id;
  final String title;
  final String description;
  final int isActive;
  final String? startsAt;
  final String? endsAt;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int questionCount;
  final bool hasSubmitted;
  final List<SurveyQuestion> questions;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.questionCount,
    required this.hasSubmitted,
    required this.questions,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    List<SurveyQuestion> questions = [];
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      // Sort questions by sort_order
      questions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return Survey(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : (json['is_active'] == true || json['is_active'] == 1) ? 1 : 0,
      startsAt: json['starts_at']?.toString(),
      endsAt: json['ends_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      questionCount: json['question_count'] is int
          ? json['question_count'] as int
          : int.tryParse(json['question_count'].toString()) ?? 0,
      hasSubmitted: json['has_submitted'] == true || json['has_submitted'] == 1,
      questions: questions,
    );
  }

  bool get isActiveBool => isActive == 1;
}

class SurveyQuestion {
  final int id;
  final int surveyId;
  final String questionText;
  final String questionType; // 'rating', 'boolean', 'text'
  final int? minValue;
  final int? maxValue;
  final int? maxLength;
  final int isRequired;
  final int sortOrder;
  final String? placeholder;
  final String? createdAt;
  final String? updatedAt;

  SurveyQuestion({
    required this.id,
    required this.surveyId,
    required this.questionText,
    required this.questionType,
    required this.isRequired,
    required this.sortOrder,
    this.minValue,
    this.maxValue,
    this.maxLength,
    this.placeholder,
    this.createdAt,
    this.updatedAt,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      surveyId: json['survey_id'] is int
          ? json['survey_id'] as int
          : int.tryParse(json['survey_id'].toString()) ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'text',
      minValue: json['min_value'] != null
          ? (json['min_value'] is int
              ? json['min_value'] as int
              : int.tryParse(json['min_value'].toString()))
          : null,
      maxValue: json['max_value'] != null
          ? (json['max_value'] is int
              ? json['max_value'] as int
              : int.tryParse(json['max_value'].toString()))
          : null,
      maxLength: json['max_length'] != null
          ? (json['max_length'] is int
              ? json['max_length'] as int
              : int.tryParse(json['max_length'].toString()))
          : null,
      isRequired: json['is_required'] is int
          ? json['is_required'] as int
          : (json['is_required'] == true || json['is_required'] == 1) ? 1 : 0,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order'].toString()) ?? 0,
      placeholder: json['placeholder']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  bool get isRequiredBool => isRequired == 1;
}




