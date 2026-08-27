import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  int _selectedIndex = 0;

  static const _cases = <_EmergencyCase>[
    _EmergencyCase(
      title: 'Zehirlenme',
      iconPath: 'assets/images/app_ikonlar/zehirlenme.png',
      color: Color(0xFFE60000),
      soft: Color(0xFFFFF7F7),
      detailTitle: 'Zehirlenme Şüphesi',
      detailSubtitle: 'Yaygın toksik maddelere ve belirtilere dikkat edin.',
      symptoms: ['Ağız salyası', 'Kusma', 'Titreme', 'Halsizlik'],
      doList: [
        'Hayvanı sakin ve güvenli alana alın.',
        'Toksik madde kaynağını uzaklaştırın.',
        'En yakın veteriner kliniğine ulaşın.',
      ],
      dontList: [
        'Kusmayı zorlamayın.',
        'İlaç vermeyin.',
        'Yiyecek veya su vermeyin.',
      ],
    ),
    _EmergencyCase(
      title: 'Kusma',
      iconPath: 'assets/images/son_ikonlar/kusma.png',
      color: Color(0xFFFF6600),
      soft: Color(0xFFFFF9F4),
      detailTitle: 'Kusma Durumu',
      detailSubtitle: 'Sıklık, içerik ve genel durumu takip edin.',
      symptoms: [
        'Tekrarlayan kusma',
        'İştahsızlık',
        'Halsizlik',
        'Dehidrasyon',
      ],
      doList: [
        'Su ve mamayı kısa süre kesin.',
        'Kusma sıklığını ve içeriğini not edin.',
        'Sürekli kusuyorsa veterinere başvurun.',
      ],
      dontList: [
        'Hemen mama vermeyin.',
        'İnsan ilaçları kullanmayın.',
        'Belirtileri yok saymayın.',
      ],
    ),
    _EmergencyCase(
      title: 'Nefes',
      iconPath: 'assets/images/son_ikonlar/nefes.png',
      color: AppColors.primary,
      soft: Color(0xFFF7FBFF),
      detailTitle: 'Nefes Darlığı',
      detailSubtitle: 'Nefes almada zorlanma acil müdahale gerektirir.',
      symptoms: ['Hızlı nefes', 'Açık ağız', 'Mavi diş eti', 'Huzursuzluk'],
      doList: [
        'Serin ve sakin ortama alın.',
        'Stresi azaltın, hareket ettirmeyin.',
        'Hemen veterinere gidin.',
      ],
      dontList: [
        'Boynuna baskı uygulamayın.',
        'Beklemeyin veya ertelemeyin.',
        'Sıcak ortamda tutmayın.',
      ],
    ),
    _EmergencyCase(
      title: 'Yaralanma',
      iconPath: 'assets/images/app_ikonlar/yaralanma.png',
      color: Color(0xFF00A859),
      soft: Color(0xFFF6FBF8),
      detailTitle: 'Yaralanma',
      detailSubtitle: 'Kanama ve kırık şüphesinde hızlı ve sakin hareket edin.',
      symptoms: ['Kanama', 'Topallama', 'Şişlik', 'Ağrı belirtisi'],
      doList: [
        'Temiz bezle hafif baskı uygulayın.',
        'Hayvanı sabitleyin, hareket ettirmeyin.',
        'En kısa sürede kliniğe gidin.',
      ],
      dontList: [
        'Yarayı dezenfektanla yıkamayın.',
        'Kırık bölgeyi çekiştirmeyin.',
        'İlaç vermeyin.',
      ],
    ),
    _EmergencyCase(
      title: 'Yabancı Cisim',
      iconPath: 'assets/images/son_ikonlar/yabanci_cisim.png',
      color: Color(0xFF9B4DCA),
      soft: Color(0xFFFBF7FF),
      detailTitle: 'Yabancı Cisim Yutma',
      detailSubtitle: 'Oyuncak, kemik veya ip yutma şüphesinde dikkatli olun.',
      symptoms: ['Kusma', 'İştahsızlık', 'Karın ağrısı', 'Kabızlık'],
      doList: [
        'Yuttuğu cismin ne olduğunu belirleyin.',
        'Su/mama vermeden klinik ile iletişime geçin.',
        'Veteriner yönlendirmesini izleyin.',
      ],
      dontList: [
        'Kusmayı zorlamayın.',
        'Yağ veya ilaç vermeyin.',
        'Bekleyip geçmesini ummayın.',
      ],
    ),
    _EmergencyCase(
      title: 'Parazit',
      iconPath: 'assets/images/app_ikonlar/parazit.png',
      color: Color(0xFFFF6600),
      soft: Color(0xFFFFF9F4),
      detailTitle: 'Parazit Acili',
      detailSubtitle:
          'Yoğun parazit yükü ve hastalık belirtilerini ciddiye alın.',
      symptoms: ['Kaşıntı', 'Tüy dökülmesi', 'Halsizlik', 'İshal'],
      doList: [
        'Paraziti mümkünse toplayıp saklayın.',
        'Ortamı temizleyin.',
        'Veteriner kontrolü ve uygun ilaç için başvurun.',
      ],
      dontList: [
        'İnsana ait ilaç kullanmayın.',
        'Doğru doz bilmeden ilaç vermeyin.',
        'Belirtileri hafife almayın.',
      ],
    ),
  ];

  _EmergencyCase get _selected => _cases[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acil bir durumda doğru bilgi, hızlı müdahale hayat kurtarır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _buildBanner(),
              const SizedBox(height: 12),
              const Text(
                'Şüphelenilen Sağlık Problemi',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _buildProblemChips(),
              const SizedBox(height: 12),
              _buildDetailCard(),
              const SizedBox(height: 10),
              _buildTipBox(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Acil Destek',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
              ),
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.emergency,
      fallbackAssets: ['assets/images/acil_destek_banner.png'],
    );
  }

  Widget _buildProblemChips() {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          for (int index = 0; index < _cases.length; index++) ...[
            if (index > 0) const SizedBox(width: 5),
            Expanded(child: _buildProblemChip(index)),
          ],
        ],
      ),
    );
  }

  Widget _buildProblemChip(int index) {
    final item = _cases[index];
    final selected = _selectedIndex == index;
    final softBorder = Color.lerp(item.color, Colors.white, 0.55) ?? item.color;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 5, 3, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? softBorder : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 2),
            Expanded(
              child: Align(
                alignment: const Alignment(0, -0.35),
                child: Image.asset(
                  item.iconPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.health_and_safety_outlined,
                    color: selected ? softBorder : item.color,
                    size: 28,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? softBorder : AppColors.text,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final item = _selected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.detailTitle,
            style: TextStyle(
              color: item.color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.detailSubtitle,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          _sectionTitle(
            icon: Icons.warning_amber_rounded,
            label: 'BELİRTİLER',
            color: AppColors.error,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in item.symptoms)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _thinSectionBox(
            color: AppColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'HEMEN YAP',
                  color: AppColors.success,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < item.doList.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.success.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 4),
                  ],
                  _numberedRow(i + 1, item.doList[i], AppColors.success),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(width: double.infinity, height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          _thinSectionBox(
            color: AppColors.error,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  icon: Icons.cancel_outlined,
                  label: 'YAPMA',
                  color: AppColors.error,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < item.dontList.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.error.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 4),
                  ],
                  _bulletRow(item.dontList[i], AppColors.error),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thinSectionBox({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _numberedRow(int no, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$no',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(Icons.close_rounded, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unutmayın',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Belirtileri doğru anlatarak veteriner hekiminize başvurun.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}

class _EmergencyCase {
  const _EmergencyCase({
    required this.title,
    required this.iconPath,
    required this.color,
    required this.soft,
    required this.detailTitle,
    required this.detailSubtitle,
    required this.symptoms,
    required this.doList,
    required this.dontList,
  });

  final String title;
  final String iconPath;
  final Color color;
  final Color soft;
  final String detailTitle;
  final String detailSubtitle;
  final List<String> symptoms;
  final List<String> doList;
  final List<String> dontList;
}
