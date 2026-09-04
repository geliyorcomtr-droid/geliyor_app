import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/notifications_screen.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/notifications_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

/// Push gelmese bile yeni bildirimi uygulama içinde gösterir.
class InAppNoticeHost extends StatefulWidget {
  const InAppNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  State<InAppNoticeHost> createState() => _InAppNoticeHostState();
}

class _InAppNoticeHostState extends State<InAppNoticeHost> {
  final Set<String> _seen = {};
  String? _uid;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    NotificationsStore.instance.addListener(_onStore);
    AuthStore.instance.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStore());
  }

  @override
  void dispose() {
    NotificationsStore.instance.removeListener(_onStore);
    AuthStore.instance.removeListener(_onStore);
    _entry?.remove();
    super.dispose();
  }

  void _onStore() {
    final uid = AuthStore.instance.uid;
    if (uid != _uid) {
      _uid = uid;
      _seen.clear();
      _hide();
    }

    final items = NotificationsStore.instance.items;
    final fresh = items.where((item) => !_seen.contains(item.id)).toList();
    _seen.addAll(items.map((item) => item.id));
    if (fresh.isEmpty) return;

    fresh.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    final newest = fresh.first;
    if (!newest.unread) return;
    final created = newest.createdAt;
    if (created != null &&
        DateTime.now().difference(created) > const Duration(hours: 6)) {
      return;
    }
    _show(newest);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  void _show(AppNotification notice) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _hide();
    _entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.of(ctx).padding.top + 8;
        return Positioned(
          top: top,
          left: AppPageFrame.contentHorizontalPadding,
          right: AppPageFrame.contentHorizontalPadding,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  _hide();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: notice.iconBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          notice.icon,
                          color: AppColors.surface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              notice.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notice.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _hide,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.subText,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) _hide();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
