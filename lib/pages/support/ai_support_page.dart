import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../constants/app_colors.dart';
import '../../services/ai_support_service.dart';

class AiSupportPage extends StatefulWidget {
  const AiSupportPage({super.key});

  @override
  State<AiSupportPage> createState() => _AiSupportPageState();
}

class _AiSupportPageState extends State<AiSupportPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiChatMessage> _messages = [];
  final List<String> _quickPrompts = const [
    'چطور سریع وارد داشبورد بشم؟',
    'کد تایید نمیاد، چکار کنم؟',
    'چطور با پشتیبانی تماس بگیرم؟',
    'از کجا رزومه یا دستاوردهایم را ببینم؟',
    'چطور مسیر یادگیری برای من شخصی‌سازی میشه؟',
    'روش دانلود یا اسکن کارت شرکت کننده چیه؟',
    'چطور می‌تونم نتایج آزمون یا پیشرفت رو ببینم؟',
    'چطور پروفایل حرفه‌ای‌م رو کامل کنم؟',
    'از کجا کارت شناسایی دیجیتال رو فعال کنم؟',
    'چطور مسیر دوره‌ها و کلاس‌های فعال رو ببینم؟',
    'کجا می‌تونم محتوا و گالری آموزشی رو جستجو کنم؟',
    'چطور بازخورد یا نظرسنجی هر رویداد رو ثبت کنم؟',
    'اگر جواب نگرفتم چه راه‌های پشتیبانی دیگه‌ای دارم؟',
    'چطور تنظیمات و خروج امن از حساب رو انجام بدم؟',
    'چطور راهنمای سریع برای شروع بگیرم؟',
  ];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _seedConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _seedConversation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(
          _AiChatMessage(
            text:
                'سلام! من همیار هوشمند پیشگامان رهایی هستم. هر سوالی درباره ورود، دوره‌ها یا پشتیبانی داری همین‌جا بپرس 🌱',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  Future<void> _handleSend([String? manualText]) async {
    final rawMessage = manualText ?? _inputController.text;
    final text = rawMessage.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(
        _AiChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isSending = true;
    });

    _inputController.clear();
    _scrollToBottom();

    setState(() {
      _messages.add(
        _AiChatMessage(
          text: 'در حال تایپ...',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ),
      );
    });

    try {
      final reply = await AiSupportService().sendMessage(text);
      _replaceTypingMessage(reply);
    } catch (e) {
      _replaceTypingMessage(
        'فعلاً به مشکل خوردیم ولی دوباره امتحان کن. اگر فوریه با پشتیبانی تماس بگیر.',
      );
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _replaceTypingMessage(String newText) {
    final index = _messages.lastIndexWhere(
      (message) => message.isTyping && !message.isUser,
    );
    if (index == -1) {
      setState(() {
        _messages.add(
          _AiChatMessage(
            text: newText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      return;
    }

    setState(() {
      _messages[index] = _messages[index].copyWith(
        text: newText,
        isTyping: false,
        timestamp: DateTime.now(),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'پشتیبانی هوشمند',
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
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(child: _buildHeroCard()),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildMessagesSliver(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildQuickPromptChips()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF01B2C6), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            offset: const Offset(0, 18),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              FontAwesomeIcons.robot,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'همیار هوشمند آنلاین است',
                      style: TextStyle(
                        fontFamily: 'Farhang',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.lightGreenAccent,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontFamily: 'Farhang',
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'هر سوالی درباره ورود، دوره‌ها و خدمات داشتی، همین‌جا بپرس. پاسخ هوشمند در چند ثانیه حاضر می‌شود.',
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

  SliverList _buildMessagesSliver() {
    if (_messages.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const SizedBox.shrink(),
          childCount: 0,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final message = _messages[index];
        final isLast = index == _messages.length - 1;
        return Padding(
          padding: EdgeInsets.only(top: 8, bottom: isLast ? 16 : 8),
          child: Align(
            alignment: message.isUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(message.isUser ? 20 : 6),
                    topRight: Radius.circular(message.isUser ? 6 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  border: message.isUser
                      ? null
                      : Border.all(color: Colors.grey.shade200),
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
                      Text(
                        message.text,
                        style: TextStyle(
                          fontFamily: 'Farhang',
                          color: message.isUser
                              ? Colors.white
                              : AppColors.darkGray,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            message.isUser
                                ? FontAwesomeIcons.solidCircleCheck
                                : FontAwesomeIcons.robot,
                            size: 12,
                            color: message.isUser
                                ? Colors.white70
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              fontFamily: 'Farhang',
                              fontSize: 11,
                              color: message.isUser
                                  ? Colors.white70
                                  : AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (message.isTyping) ...[
                        const SizedBox(height: 6),
                        const _TypingDots(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }, childCount: _messages.length),
    );
  }

  Widget _buildQuickPromptChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                FontAwesomeIcons.wandMagicSparkles,
                color: AppColors.secondaryColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'سوالات پیشنهادی آماده پاسخ',
                style: TextStyle(
                  fontFamily: 'Farhang',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'برای دریافت جواب فوری، یکی از سوالات آماده را بزن یا پیام جدید بنویس.',
            style: TextStyle(
              fontFamily: 'Farhang',
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  avatar: const Icon(
                    FontAwesomeIcons.wandMagicSparkles,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      fontFamily: 'Farhang',
                      fontSize: 13,
                      color: AppColors.darkGray,
                    ),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _quickPrompts.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 10),
              blurRadius: 30,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _isSending
                  ? null
                  : () {
                      _inputController.text = '';
                      _handleSend('دریافت راهنمای سریع');
                    },
              icon: const Icon(
                FontAwesomeIcons.wandMagicSparkles,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'پیامت را بنویس...',
                  hintStyle: TextStyle(
                    fontFamily: 'Farhang',
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'Farhang'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      FontAwesomeIcons.paperPlane,
                      size: 16,
                      color: Colors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final time = TimeOfDay.fromDateTime(timestamp);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'صبح' : 'عصر';
    return '$hour:$minute $period';
  }
}

class _AiChatMessage {
  const _AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  _AiChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return _AiChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final animationValue = (_controller.value + (index * 0.2)) % 1.0;
            final scale =
                0.6 +
                (animationValue < 0.5 ? animationValue : 1 - animationValue);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: const CircleAvatar(
                  radius: 3,
                  backgroundColor: AppColors.primary,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
