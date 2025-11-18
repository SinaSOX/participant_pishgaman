import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/survey.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SurveyDetailPage extends StatefulWidget {
  final Survey survey;

  const SurveyDetailPage({super.key, required this.survey});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  final AuthService _authService = AuthService();
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  void _initPage() {
    Future.microtask(() async {
      await _authService.init();
      final userId = _authService.getUserId();
      if (!mounted) return;
      setState(() => _userId = userId);
    });
  }

  void _setAnswer(int questionId, dynamic value) {
    // Don't allow setting answers if survey is inactive
    if (!widget.survey.isActiveBool) return;
    setState(() {
      _answers[questionId] = value;
    });
  }

  bool _validateAnswers() {
    for (final question in widget.survey.questions) {
      if (question.isRequiredBool) {
        if (!_answers.containsKey(question.id) || _answers[question.id] == null) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _submitSurvey() async {
    // Don't allow submitting if survey is inactive
    if (!widget.survey.isActiveBool) {
      _showSnack('این نظرسنجی غیرفعال است و امکان ثبت پاسخ وجود ندارد.', isError: true);
      return;
    }

    if (_userId == null) {
      _showSnack('برای ثبت نظرسنجی ابتدا وارد حساب کاربری شوید.', isError: true);
      return;
    }

    if (!_validateAnswers()) {
      _showSnack('لطفا به تمام سوالات اجباری پاسخ دهید.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    // Prepare answers in the format expected by API
    final List<Map<String, dynamic>> answersList = [];
    for (final entry in _answers.entries) {
      answersList.add({
        'question_id': entry.key,
        'answer': entry.value,
      });
    }

    final response = await ApiService.submitSurvey(
      surveyId: widget.survey.id,
      userId: _userId!,
      answers: answersList,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (response['success'] == true) {
      _showSnack(
        response['message']?.toString() ?? 'پاسخ شما با موفقیت ثبت شد',
      );
      // Wait a bit then go back
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } else {
      _showSnack(
        response['message']?.toString() ?? 'ثبت پاسخ با خطا مواجه شد.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Farhang')),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نظرسنجی',
            style: TextStyle(fontFamily: 'Farhang'),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      ...widget.survey.questions.map((question) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildQuestionWidget(question),
                          )),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.survey.title,
              style: const TextStyle(
                fontFamily: 'Farhang',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (widget.survey.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.survey.description,
                style: const TextStyle(
                  fontFamily: 'Farhang',
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.listCheck,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.survey.questionCount} سوال',
                  style: const TextStyle(
                    fontFamily: 'Farhang',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                if (!widget.survey.isActiveBool) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'غیرفعال',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(SurveyQuestion question) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question.questionText,
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.survey.isActiveBool
                            ? AppColors.darkGray
                            : AppColors.grey,
                      ),
                    ),
                  ),
                  if (question.isRequiredBool)
                    const Text(
                      '*',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestion question) {
    switch (question.questionType) {
      case 'rating':
        return _buildRatingInput(question);
      case 'boolean':
        return _buildBooleanInput(question);
      case 'text':
      default:
        return _buildTextInput(question);
    }
  }

  Widget _buildRatingInput(SurveyQuestion question) {
    final minValue = question.minValue ?? 1;
    final maxValue = question.maxValue ?? 5;
    final currentValue = _answers[question.id] as int? ?? minValue;
    final isActive = widget.survey.isActiveBool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            maxValue - minValue + 1,
            (index) {
              final value = minValue + index;
              final isSelected = currentValue == value;
              return GestureDetector(
                onTap: isActive ? () => _setAnswer(question.id, value) : null,
                child: Opacity(
                  opacity: isActive ? 1.0 : 0.6,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isActive ? AppColors.primary : Colors.grey.shade400)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isActive ? AppColors.primary : Colors.grey.shade400)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontFamily: 'Farhang',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isSelected ? Colors.white : AppColors.darkGray,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$minValue',
              style: const TextStyle(
                fontFamily: 'Farhang',
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
            Text(
              '$maxValue',
              style: const TextStyle(
                fontFamily: 'Farhang',
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBooleanInput(SurveyQuestion question) {
    final currentValue = _answers[question.id] as bool?;
    final isActive = widget.survey.isActiveBool;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isActive ? () => _setAnswer(question.id, true) : null,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: currentValue == true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentValue == true
                        ? (isActive ? Colors.green : Colors.grey.shade400)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentValue == true
                          ? FontAwesomeIcons.solidCircleCheck
                          : FontAwesomeIcons.circle,
                      color: currentValue == true ? Colors.green : AppColors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'بله',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: isActive ? () => _setAnswer(question.id, false) : null,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: currentValue == false
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentValue == false
                        ? (isActive ? Colors.red : Colors.grey.shade400)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentValue == false
                          ? FontAwesomeIcons.solidCircleXmark
                          : FontAwesomeIcons.circle,
                      color: currentValue == false ? Colors.red : AppColors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'خیر',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(SurveyQuestion question) {
    final controller = TextEditingController(
      text: _answers[question.id]?.toString() ?? '',
    );
    final isActive = widget.survey.isActiveBool;

    return TextField(
      controller: controller,
      enabled: isActive,
      onChanged: isActive ? (value) => _setAnswer(question.id, value) : null,
      maxLines: question.maxLength != null ? 5 : 3,
      maxLength: question.maxLength,
      decoration: InputDecoration(
        hintText: question.placeholder ?? 'پاسخ خود را وارد کنید...',
        hintStyle: const TextStyle(
          fontFamily: 'Farhang',
          color: AppColors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontFamily: 'Farhang'),
    );
  }

  Widget _buildSubmitButton() {
    final hasAllRequiredAnswers = _validateAnswers();
    final isActive = widget.survey.isActiveBool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'این نظرسنجی غیرفعال است و امکان ثبت پاسخ وجود ندارد.',
                        style: const TextStyle(
                          fontFamily: 'Farhang',
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive && !_isSubmitting && hasAllRequiredAnswers
                    ? _submitSurvey
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'ثبت پاسخ',
                    style: TextStyle(
                      fontFamily: 'Farhang',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

