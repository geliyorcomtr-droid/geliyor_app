import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/data/coupon_repository.dart';
import 'package:geliyor_app/state/coupon_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class CouponSheet {
  CouponSheet._();

  static Future<void> show(BuildContext context, {required double subtotal}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
              child: _CouponSheetBody(subtotal: subtotal),
            ),
          ),
        );
      },
    );
  }
}

class _CouponSheetBody extends StatefulWidget {
  const _CouponSheetBody({required this.subtotal});

  final double subtotal;

  @override
  State<_CouponSheetBody> createState() => _CouponSheetBodyState();
}

class _CouponSheetBodyState extends State<_CouponSheetBody> {
  final _code = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    CouponStore.instance.ensureLoaded();
    CouponStore.instance.addListener(_onStore);
  }

  @override
  void dispose() {
    CouponStore.instance.removeListener(_onStore);
    _code.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  String _format(double value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  void _applyCode() {
    final error = CouponStore.instance.applyCode(_code.text, widget.subtotal);
    setState(() => _error = error);
    if (error == null && mounted) Navigator.of(context).pop();
  }

  void _applyCoupon(AppCoupon coupon) {
    final error = CouponStore.instance.applyCoupon(coupon, widget.subtotal);
    setState(() => _error = error);
    if (error == null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = CouponStore.instance;
    final coupons = store.usableCoupons;
    final selectedId = store.selected?.id;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.subText,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Kupon kullan',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tanımlı veya kazandığınız kuponları uygulayın.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Kupon kodu',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onSubmitted: (_) => _applyCode(),
                  ),
                ),
                const SizedBox(width: 8),
                AppPressableButton.primary(
                  onTap: _applyCode,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('Uygula'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (store.selected != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    store.clearSelected();
                    setState(() => _error = null);
                  },
                  child: const Text(
                    'Kuponu kaldır',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Kuponlarım',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: coupons.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Kullanabileceğiniz kupon yok. Kodunuz varsa yukarıya yazın.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: coupons.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        final selected = coupon.id == selectedId;
                        final earned = store.earnedIds.contains(coupon.id);
                        final blocked = coupon.eligibilityError(widget.subtotal);
                        return GestureDetector(
                          onTap: blocked == null
                              ? () => _applyCoupon(coupon)
                              : () => setState(() => _error = blocked),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.selected
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryLight
                                    : AppColors.border,
                                width: selected ? 1.6 : 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        coupon.title,
                                        style: TextStyle(
                                          color: selected
                                              ? AppColors.primary
                                              : AppColors.text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${coupon.code} · ${coupon.discountLabel}'
                                        '${earned ? ' · Kazanıldı' : ''}',
                                        style: const TextStyle(
                                          color: AppColors.subText,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${coupon.discountLabel}',
                                  style: TextStyle(
                                    color: blocked == null
                                        ? AppColors.primary
                                        : AppColors.subText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (store.selected != null) ...[
              const SizedBox(height: 8),
              Text(
                '${store.selected!.title} ile ${_format(store.discountFor(widget.subtotal))} TL indirim uygulanacak.',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
