import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/filter_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/services/assistant_service.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/market_product_helpers.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage.assistant(
        text:
            'Merhaba! Ben Geliyor.tr pet asistanıyım. Mama, aşı, kilo, tüy bakımı ve ürün önerilerinde yardımcı olurum. '
            'Dostunuz kayıtlıysa cevaplarımı ona göre kişiselleştiririm. Sorunuzu yazın veya hızlı seçenekleri kullanın.',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage.user(text: trimmed));
      _messages.add(_ChatMessage.typing());
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final history = <({String role, String text})>[];
      for (final message in _messages) {
        if (message.isTyping || message.text.trim().isEmpty) continue;
        // Skip the just-added user message duplicate; include prior turns only.
        history.add((
          role: message.isUser ? 'user' : 'model',
          text: message.text,
        ));
      }
      // Last item is the current user question — Gemini gets it separately.
      if (history.isNotEmpty && history.last.role == 'user') {
        history.removeLast();
      }

      final reply = await AssistantService.instance.ask(
        trimmed,
        history: history,
      );
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage.assistant(
            text: reply.text,
            products: reply.products,
            actions: reply.actions,
          ),
        );
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage.assistant(
            text: 'Şu anda yanıt veremiyorum. Lütfen biraz sonra tekrar deneyin.',
          ),
        );
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
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
            Expanded(child: _buildChatArea()),
            _buildInputBar(),
          ],
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.assistant),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FilterScreen()),
              );
            },
            icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 28),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Asistan',
                      style: AppTextStyles.pageHeader,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.pets_rounded,
                      color: AppColors.primary.withValues(alpha: 0.85),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  'Akıllı Pet Asistanınız',
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.9),
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

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildBanner(),
          );
        }
        return _buildMessageBubble(_messages[index - 1]);
      },
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/asistan_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 148,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Merhaba! Ben Geliyor.tr Asistanı.\nDostunuz için her zaman buradayım.',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                Expanded(
                  child: _BannerQuickAction(
                    onTap: () => _sendMessage(
                      'Kedim için mama önerisi isterim.',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _BannerQuickAction(
                    onTap: () => _sendMessage(
                      'Aşı takvimi hakkında bilgi verir misin?',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _BannerQuickAction(
                    onTap: () => _sendMessage(
                      'Kısır kedim için nelere dikkat etmeliyim?',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    if (message.isTyping) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assistantAvatar(),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.time),
                        style: TextStyle(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 12,
                        color: AppColors.surface.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assistantAvatar(),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                if (message.products.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.actions
                        .map(
                          (action) => _ActionChip(
                            label: action.label,
                            primary: action.label.startsWith('Evet'),
                            onTap: () => _sendMessage(action.prompt),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assistantAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.selected,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: AppColors.primary,
        size: 16,
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
      ),
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

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_isSending,
                      onSubmitted: _sendMessage,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Bir soru sor...',
                        hintStyle: TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : () {},
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.subText,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(_inputController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.primaryLight.withValues(alpha: 0.6)
                    : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.surface,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isTyping = false,
    this.products = const [],
    this.actions = const [],
  });

  factory _ChatMessage.user({required String text}) {
    return _ChatMessage(text: text, isUser: true, time: DateTime.now());
  }

  factory _ChatMessage.assistant({
    required String text,
    List<AssistantProduct> products = const [],
    List<AssistantAction> actions = const [],
  }) {
    return _ChatMessage(
      text: text,
      isUser: false,
      time: DateTime.now(),
      products: products,
      actions: actions,
    );
  }

  factory _ChatMessage.typing() {
    return _ChatMessage(
      text: '',
      isUser: false,
      time: DateTime.now(),
      isTyping: true,
    );
  }

  final String text;
  final bool isUser;
  final bool isTyping;
  final DateTime time;
  final List<AssistantProduct> products;
  final List<AssistantAction> actions;
}

class _BannerQuickAction extends StatelessWidget {
  const _BannerQuickAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: primary ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: primary ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? AppColors.primary : AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
