import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/survey.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'survey_detail_page.dart';

class SurveyListPage extends StatefulWidget {
  const SurveyListPage({super.key});

  @override
  State<SurveyListPage> createState() => _SurveyListPageState();
}

class _SurveyListPageState extends State<SurveyListPage> {
  final AuthService _authService = AuthService();
  List<Survey> _surveys = [];
  bool _isLoading = false;
  String? _error;
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

      if (userId != null) {
        await _fetchSurveys();
      } else {
        setState(() {
          _error = 'برای مشاهده نظرسنجی‌ها ابتدا وارد حساب کاربری شوید.';
        });
      }
    });
  }

  Future<void> _fetchSurveys() async {
    final userId = _userId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getSurveys(userId: userId);

    if (!mounted) return;

    if (response['success'] == true) {
      final List<Survey> surveys =
          (response['data'] as List<Survey>).toList();
      setState(() {
        _surveys = surveys;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response['message']?.toString() ?? 'خطا در دریافت نظرسنجی‌ها';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نظرسنجی‌ها',
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
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_userId == null) {
      return _buildLoginRequired();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_surveys.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchSurveys,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _surveys.length,
        separatorBuilder: (context, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final survey = _surveys[index];
          return _buildSurveyCard(survey);
        },
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(FontAwesomeIcons.userLock, color: AppColors.primary, size: 48),
          SizedBox(height: 16),
          Text(
            'برای مشاهده نظرسنجی‌ها، ابتدا وارد حساب کاربری شوید.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Farhang', color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.triangleExclamation,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'خطا در دریافت اطلاعات',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Farhang',
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchSurveys,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'تلاش مجدد',
              style: TextStyle(fontFamily: 'Farhang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchSurveys,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            margin: const EdgeInsets.only(top: 48),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  FontAwesomeIcons.clipboardCheck,
                  color: AppColors.primary,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'نظرسنجی فعالی وجود ندارد',
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'هنگامی که نظرسنجی جدیدی اضافه شود، در اینجا نمایش داده می‌شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(Survey survey) {
    final isSubmitted = survey.hasSubmitted;
    final isActive = survey.isActiveBool;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: !isSubmitted
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurveyDetailPage(survey: survey),
                  ),
                ).then((_) {
                  // Refresh surveys after returning from detail page
                  _fetchSurveys();
                });
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: !isSubmitted
                ? Colors.white
                : Colors.grey.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      survey.title,
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: !isSubmitted
                            ? AppColors.darkGray
                            : AppColors.grey,
                      ),
                    ),
                  ),
                  if (isSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'تکمیل شده',
                        style: TextStyle(
                          fontFamily: 'Farhang',
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'غیرفعال',
                        style: TextStyle(
                          fontFamily: 'Farhang',
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (survey.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  survey.description,
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.listCheck,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${survey.questionCount} سوال',
                    style: const TextStyle(
                      fontFamily: 'Farhang',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (!isSubmitted)
                    Row(
                      children: [
                        Text(
                          isActive ? 'شروع نظرسنجی' : 'مشاهده نظرسنجی',
                          style: TextStyle(
                            fontFamily: 'Farhang',
                            fontSize: 12,
                            color: isActive ? AppColors.primary : AppColors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          FontAwesomeIcons.arrowLeft,
                          size: 12,
                          color: isActive ? AppColors.primary : AppColors.grey,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

