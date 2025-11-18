import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../constants/app_colors.dart';
import '../../models/feedback_entry.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _inputController = TextEditingController();
  final AuthService _authService = AuthService();
  final List<FeedbackEntry> _feedbackHistory = [];

  bool _isSending = false;
  bool _isLoadingHistory = false;
  String? _historyError;
  String? _userIdentifier;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _initPage() {
    Future.microtask(() async {
      await _authService.init();
      final identifier = _authService.getPhone();
      if (!mounted) return;

      setState(() => _userIdentifier = identifier);

      if (identifier != null) {
        await _fetchFeedbackHistory();
      } else {
        _showSnack(
          'برای ثبت بازخورد ابتدا وارد حساب کاربری شوید.',
          isError: true,
        );
      }
    });
  }

  Future<void> _fetchFeedbackHistory() async {
    final identifier = _userIdentifier;
    if (identifier == null) return;

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    final response = await ApiService.getFeedbackList(identifier);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      List<FeedbackEntry> entries = [];
      if (data is List) {
        entries = data
            .map(
              (item) => item is FeedbackEntry
                  ? item
                  : FeedbackEntry.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
            )
            .toList();
      }
      setState(() {
        _feedbackHistory
          ..clear()
          ..addAll(entries);
        _isLoadingHistory = false;
      });
    } else {
      setState(() {
        _historyError =
            response['message']?.toString() ?? 'خطا در دریافت بازخوردها';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    final identifier = _userIdentifier;

    if (text.isEmpty || _isSending) return;

    if (identifier == null) {
      _showSnack(
        'برای ثبت بازخورد ابتدا وارد حساب کاربری شوید.',
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    final subject = _deriveSubject(text);

    final response = await ApiService.submitFeedback(
      userIdentifier: identifier,
      message: text,
      category: 'suggestion',
      subject: subject,
      contactInfo: identifier,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    if (response['success'] == true) {
      _inputController.clear();
      _showSnack(
        response['message']?.toString() ??
            'پیامت ثبت شد و خیلی زود بررسی می‌شه 💚',
      );
      await _fetchFeedbackHistory();
    } else {
      _showSnack(
        response['message']?.toString() ?? 'ارسال پیام با خطا مواجه شد.',
        isError: true,
      );
    }
  }

  String _deriveSubject(String input) {
    if (input.isEmpty) return 'بازخورد اپلیکیشن';
    final trimmed = input.trim();
    if (trimmed.length <= 30) return trimmed;
    return '${trimmed.substring(0, 27)}...';
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
            'پیشنهادات و انتقادات',
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeroCard(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildHistorySection(),
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              FontAwesomeIcons.commentDots,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'صدای شما مهمه',
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'هر ایده یا چالشی داشتی سریعاً بگو. تیم محصول پیام‌هات رو می‌خونه و پیگیری می‌کنه.',
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_userIdentifier == null) {
      return _buildLoginRequired();
    }

    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyError != null) {
      return _buildErrorState();
    }

    if (_feedbackHistory.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchFeedbackHistory,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24, top: 4),
        itemCount: _feedbackHistory.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _feedbackHistory[index];
          return _buildFeedbackCard(entry);
        },
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(FontAwesomeIcons.userLock, color: AppColors.primary, size: 36),
          SizedBox(height: 16),
          Text(
            'برای مشاهده و ثبت بازخورد، ابتدا وارد حساب کاربری شوید.',
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
            size: 36,
          ),
          const SizedBox(height: 16),
          Text(
            _historyError ?? 'خطا در دریافت اطلاعات',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Farhang',
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchFeedbackHistory,
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
      onRefresh: _fetchFeedbackHistory,
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
                  FontAwesomeIcons.message,
                  color: AppColors.primary,
                  size: 36,
                ),
                SizedBox(height: 16),
                Text(
                  'هنوز پیامی ثبت نکردی',
                  style: TextStyle(
                    fontFamily: 'Farhang',
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اولین بازخورد رو همین پایین بنویس؛ تیم ما داره منتظر صدای توئه!',
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

  Widget _buildFeedbackCard(FeedbackEntry entry) {
    final statusColor = _statusColor(entry.status);
    final hasAdminReply =
        entry.adminNote != null && entry.adminNote!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 12),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(entry.status),
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 12,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#${entry.id}',
                            style: const TextStyle(
                              fontFamily: 'Farhang',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.message,
                        style: const TextStyle(
                          fontFamily: 'Farhang',
                          color: Colors.white,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.clock,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimestamp(entry.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Farhang',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasAdminReply) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: const Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              FontAwesomeIcons.solidCircleCheck,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'پاسخ تیم پشتیبانی',
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.adminNote!.trim(),
                          style: const TextStyle(
                            fontFamily: 'Farhang',
                            color: AppColors.darkGray,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'done':
        return Colors.green;
      case 'in_progress':
      case 'processing':
        return Colors.orange;
      case 'rejected':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'done':
        return 'انجام شد';
      case 'in_progress':
      case 'processing':
        return 'در حال بررسی';
      case 'rejected':
        return 'رد شده';
      default:
        return 'ثبت شده';
    }
  }

  Widget _buildInputBar() {
    final isEnabled = _userIdentifier != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _inputController,
                enabled: isEnabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: isEnabled
                      ? 'متن پیام...'
                      : 'برای ارسال ابتدا وارد شوید',
                  hintStyle: const TextStyle(
                    fontFamily: 'Farhang',
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontFamily: 'Farhang'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: !_isSending && isEnabled ? _handleSend : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: AppColors.primary,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(FontAwesomeIcons.paperPlane, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';
    final date =
        '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$date | $hour:$minute';
  }
}
