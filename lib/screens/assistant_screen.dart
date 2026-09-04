import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/screens/vaccine_calendar_screen.dart';
import 'package:geliyor_app/services/assistant_service.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/market_product_helpers.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  static const _starters = [
    (
      icon: Icons.restaurant_rounded,
      title: 'Mama öner',
      subtitle: 'Dostuna uygun mama',
      prompt: 'Kedim için mama önerisi isterim.',
    ),
    (
      icon: Icons.vaccines_rounded,
      title: 'Aşı takvimi',
      subtitle: 'Ne zaman yaptırmalıyım?',
      prompt: 'Aşı takvimi hakkında bilgi verir misin?',
    ),
    (
      icon: Icons.monitor_weight_rounded,
      title: 'Günlük porsiyon',
      subtitle: 'Ne kadar mama vermeliyim?',
      prompt: 'Günlük mama porsiyonu ne kadar olmalı?',
    ),
    (
      icon: Icons.spa_rounded,
      title: 'Tüy bakımı',
      subtitle: 'Dökülme ve tarama',
      prompt: 'Tüy dökülmesi için ne yapmalıyım?',
    ),
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  bool get _hasConversation => _messages.any((message) => message.isUser);

  @override
  void dispose() {
    AssistantService.instance.cancelActive();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNewChat() {
    AssistantService.instance.cancelActive();
    setState(() {
      _messages.clear();
      _isSending = false;
      _inputController.clear();
    });
  }

  void _stopGenerating() {
    AssistantService.instance.cancelActive();
    if (!_isSending) return;
    setState(() => _isSending = false);
    if (_messages.isNotEmpty && _messages.last.isStreaming) {
      setState(() {
        _messages[_messages.length - 1] = _messages.last.copyWith(
          isStreaming: false,
        );
      });
    }
  }

  void _onAction(AssistantAction action) {
    if (_isSending) return;
    switch (action.intent) {
      case AssistantIntent.enableVaccineReminder:
        _enableVaccineReminder();
      case AssistantIntent.openVaccineCalendar:
        _openVaccineCalendar(fromChip: action.label);
      case AssistantIntent.declineVaccineReminder:
        _replyLocally(
          userText: action.label,
          assistantText:
              'Tamam, şimdilik hatırlatıcı açmadım. İstediğin zaman Aşı Takvimi’nden açabilirsin.',
        );
      case AssistantIntent.postponeVaccineReminder:
        _replyLocally(
          userText: action.label,
          assistantText:
              'Tamam, daha sonra hatırlatırım. İstediğin zaman Aşı Takvimi’nden de açabilirsin.',
        );
      case AssistantIntent.none:
        final prompt = action.prompt.trim();
        if (prompt.isNotEmpty) _sendMessage(prompt);
    }
  }

  void _replyLocally({
    required String userText,
    required String assistantText,
    List<AssistantAction> actions = const [],
  }) {
    setState(() {
      _messages.add(_ChatMessage.user(text: userText));
      _messages.add(
        _ChatMessage.assistant(text: assistantText, actions: actions),
      );
    });
    _scrollToBottom();
  }

  void _enableVaccineReminder() {
    final store = NotificationSettingsStore.instance;
    store.setVaccineCalendarEnabled(true);
    store.setHealthRemindersEnabled(true);
    _replyLocally(
      userText: 'Evet, hatırlatıcıyı aç',
      assistantText:
          'Aşı hatırlatıcısını açtım. Takvimden tarihleri işaretleyebilirsin.',
      actions: const [
        AssistantAction(
          label: 'Aşı takvimini aç',
          intent: AssistantIntent.openVaccineCalendar,
        ),
      ],
    );
    _openVaccineCalendar();
  }

  void _openVaccineCalendar({String? fromChip}) {
    if (fromChip != null) {
      _replyLocally(
        userText: fromChip,
        assistantText: 'Aşı takvimini açıyorum.',
      );
    }
    NotificationSettingsStore.instance.setVaccineCalendarEnabled(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VaccineCalendarScreen(openReminder: true),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage.user(text: trimmed));
      _messages.add(_ChatMessage.assistant(text: '', isStreaming: true));
      _inputController.clear();
    });
    _scrollToBottom();

    final history = <({String role, String text})>[];
    for (final message in _messages) {
      if (message.isStreaming || message.text.trim().isEmpty) continue;
      history.add((
        role: message.isUser ? 'user' : 'model',
        text: message.text,
      ));
    }
    if (history.isNotEmpty && history.last.role == 'user') {
      history.removeLast();
    }

    final buffer = StringBuffer();
    try {
      await for (final delta in AssistantService.instance.askStream(
        trimmed,
        history: history,
      )) {
        if (!mounted) return;
        buffer.write(delta);
        setState(() {
          _messages[_messages.length - 1] = _ChatMessage.assistant(
            text: buffer.toString(),
            isStreaming: true,
          );
        });
        _scrollToBottom();
      }
      if (!mounted) return;
      final reply = AssistantService.instance.decorate(
        buffer.toString(),
        trimmed,
      );
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage.assistant(
          text: reply.text.isEmpty
              ? 'Şu anda yanıt veremiyorum. Lütfen biraz sonra tekrar deneyin.'
              : reply.text,
          products: reply.products,
          actions: reply.actions,
        );
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (buffer.isNotEmpty) {
        setState(() {
          _messages[_messages.length - 1] = _ChatMessage.assistant(
            text: buffer.toString(),
          );
          _isSending = false;
        });
      } else {
        setState(() {
          _messages[_messages.length - 1] = _ChatMessage.assistant(
            text:
                'Şu anda yanıt veremiyorum. Lütfen biraz sonra tekrar deneyin.',
          );
          _isSending = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.assistant,
        header: _buildHeader(),
        content: Column(
          children: [
            Expanded(
              child: _hasConversation ? _buildChatArea() : _buildEmptyState(),
            ),
            _buildComposer(),
          ],
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.assistant),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          AppPressableButton(
            onTap: _hasConversation || _isSending ? _startNewChat : null,
            enabled: _hasConversation || _isSending,
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            pressedBackgroundColor: AppColors.selected,
            foregroundColor: AppColors.primary,
            pressedForegroundColor: AppColors.primary,
            borderColor: Colors.transparent,
            pressedBorderColor: Colors.transparent,
            borderWidth: 0,
            child: const Icon(Icons.edit_square, size: 22),
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Asistan', style: AppTextStyles.pageHeader),
                SizedBox(height: 2),
                Text(
                  'Yapay zeka sohbeti',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const AppNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final name = AuthStore.instance.firstName;
    final greeting = name.isEmpty
        ? 'Nerede yardımcı olayım?'
        : 'Merhaba $name, nerede yardımcı olayım?';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppPageFrame.contentHorizontalPadding,
        12,
        AppPageFrame.contentHorizontalPadding,
        8,
      ),
      children: [
        const SizedBox(height: 28),
        const Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: 8),
        const Text(
          'Mama, aşı, bakım veya aklına gelen her şeyi sor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            for (final starter in _starters)
              AppPressableButton.soft(
                onTap: () => _sendMessage(starter.prompt),
                width: double.infinity,
                height: double.infinity,
                borderRadius: 18,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(starter.icon, size: 18),
                    const Spacer(),
                    Text(
                      starter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      starter.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppPageFrame.contentHorizontalPadding,
        0,
        AppPageFrame.contentHorizontalPadding,
        8,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessage(_messages[index]),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.selected,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text.isEmpty && message.isStreaming)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            SelectableText(
              message.text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          if (message.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: message.products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => SizedBox(
                  width: 340,
                  child: _buildProductCard(message.products[i]),
                ),
              ),
            ),
          ],
          if (message.actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.actions
                  .map(
                    (action) => _ActionChip(
                      label: action.label,
                      primary: action.label.startsWith('Evet'),
                      onTap: () => _onAction(action),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(AssistantProduct product) {
    return marketProductListCard(
      product: buildSimpleMarketProduct(
        id: product.name,
        imagePath: product.imagePath,
        title: product.name,
        subtitle: product.subtitle,
        rating: product.rating,
        reviewCount: 24,
        price: 1249,
        oldPrice: 1470,
      ),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProductDetailScreen())),
      onAddToCart: (_, price, oldPrice, qty) {
        for (var i = 0; i < qty; i++) {
          CartStore.instance.addItem(
            id: product.name,
            imagePath: product.imagePath,
            title: product.name,
            unitPrice: price,
            oldPrice: oldPrice,
          );
        }
      },
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPageFrame.contentHorizontalPadding,
        0,
        AppPageFrame.contentHorizontalPadding,
        6,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: _sendMessage,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Herhangi bir şey sorun...',
                      hintStyle: TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AppPressableButton.primary(
                  onTap: _isSending
                      ? _stopGenerating
                      : (_inputController.text.trim().isEmpty
                            ? null
                            : () => _sendMessage(_inputController.text)),
                  enabled: _isSending || _inputController.text.trim().isNotEmpty,
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.zero,
                  child: Icon(
                    _isSending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Asistan hata yapabilir. Ciddi sağlık konularında veterinere danışın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subText.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.products = const [],
    this.actions = const [],
  });

  factory _ChatMessage.user({required String text}) {
    return _ChatMessage(text: text, isUser: true);
  }

  factory _ChatMessage.assistant({
    required String text,
    List<AssistantProduct> products = const [],
    List<AssistantAction> actions = const [],
    bool isStreaming = false,
  }) {
    return _ChatMessage(
      text: text,
      isUser: false,
      isStreaming: isStreaming,
      products: products,
      actions: actions,
    );
  }

  final String text;
  final bool isUser;
  final bool isStreaming;
  final List<AssistantProduct> products;
  final List<AssistantAction> actions;

  _ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<AssistantProduct>? products,
    List<AssistantAction>? actions,
  }) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      isStreaming: isStreaming ?? this.isStreaming,
      products: products ?? this.products,
      actions: actions ?? this.actions,
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      backgroundColor: primary ? AppColors.selected : AppColors.surface,
      pressedBackgroundColor: AppColors.primary,
      foregroundColor: primary ? AppColors.primary : AppColors.text,
      pressedForegroundColor: AppColors.surface,
      borderColor: primary ? AppColors.primary : AppColors.border,
      pressedBorderColor: AppColors.primary,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
