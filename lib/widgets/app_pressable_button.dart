import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Tüm projede ortak basılabilir buton.
/// Basılıyken arka plan / yazı / çerçeve rengi değişir.
class AppPressableButton extends StatefulWidget {
  const AppPressableButton({
    super.key,
    required this.onTap,
    this.child,
    this.builder,
    this.backgroundColor = AppColors.selected,
    this.pressedBackgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.primary,
    this.pressedForegroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.pressedBorderColor = AppColors.primary,
    this.borderWidth = 1,
    this.borderRadius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.width,
    this.height,
    this.enabled = true,
    this.disabledBackgroundColor = AppColors.border,
    this.disabledForegroundColor = AppColors.subText,
  }) : assert(child != null || builder != null);

  /// Soft stil: açık mavi zemin → basınca primary.
  factory AppPressableButton.soft({
    Key? key,
    required VoidCallback? onTap,
    required Widget child,
    double borderRadius = 999,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    double? width,
    double? height,
    bool enabled = true,
  }) {
    return AppPressableButton(
      key: key,
      onTap: onTap,
      backgroundColor: AppColors.selected,
      pressedBackgroundColor: AppColors.primary,
      foregroundColor: AppColors.primary,
      pressedForegroundColor: AppColors.surface,
      borderColor: AppColors.border,
      pressedBorderColor: AppColors.primary,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      enabled: enabled,
      builder: (pressed) => DefaultTextStyle.merge(
        style: TextStyle(
          color: !enabled
              ? AppColors.subText
              : (pressed ? AppColors.surface : AppColors.primary),
          fontWeight: FontWeight.w800,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: !enabled
                ? AppColors.subText
                : (pressed ? AppColors.surface : AppColors.primary),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Primary stil: mavi zemin → basınca daha koyu / seçili ton.
  factory AppPressableButton.primary({
    Key? key,
    required VoidCallback? onTap,
    required Widget child,
    double borderRadius = 999,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    double? width,
    double? height,
    bool enabled = true,
  }) {
    return AppPressableButton(
      key: key,
      onTap: onTap,
      backgroundColor: AppColors.primaryLight,
      pressedBackgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      pressedForegroundColor: AppColors.surface,
      borderColor: AppColors.primaryLight,
      pressedBorderColor: AppColors.primary,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      enabled: enabled,
      builder: (pressed) => DefaultTextStyle.merge(
        style: TextStyle(
          color: enabled ? AppColors.surface : AppColors.subText,
          fontWeight: FontWeight.w800,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: enabled ? AppColors.surface : AppColors.subText,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Border/outline stil: beyaz zemin → basınca selected.
  factory AppPressableButton.outline({
    Key? key,
    required VoidCallback? onTap,
    required Widget child,
    double borderRadius = 999,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    double? width,
    double? height,
    bool enabled = true,
  }) {
    return AppPressableButton(
      key: key,
      onTap: onTap,
      backgroundColor: AppColors.border,
      pressedBackgroundColor: AppColors.primary,
      foregroundColor: AppColors.text,
      pressedForegroundColor: AppColors.surface,
      borderColor: AppColors.border,
      pressedBorderColor: AppColors.primary,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      enabled: enabled,
      builder: (pressed) => DefaultTextStyle.merge(
        style: TextStyle(
          color: !enabled
              ? AppColors.subText
              : (pressed ? AppColors.surface : AppColors.text),
          fontWeight: FontWeight.w800,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: !enabled
                ? AppColors.subText
                : (pressed ? AppColors.surface : AppColors.text),
          ),
          child: child,
        ),
      ),
    );
  }

  final VoidCallback? onTap;
  final Widget? child;
  final Widget Function(bool pressed)? builder;
  final Color backgroundColor;
  final Color pressedBackgroundColor;
  final Color foregroundColor;
  final Color pressedForegroundColor;
  final Color borderColor;
  final Color pressedBorderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool enabled;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;

  @override
  State<AppPressableButton> createState() => _AppPressableButtonState();
}

class _AppPressableButtonState extends State<AppPressableButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed && widget.enabled;
    final bg = !widget.enabled
        ? widget.disabledBackgroundColor
        : (pressed ? widget.pressedBackgroundColor : widget.backgroundColor);
    final border = !widget.enabled
        ? widget.disabledBackgroundColor
        : (pressed ? widget.pressedBorderColor : widget.borderColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTap: !widget.enabled
          ? null
          : () {
              _setPressed(false);
              widget.onTap?.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: border, width: widget.borderWidth),
        ),
        child: widget.builder?.call(pressed) ?? widget.child,
      ),
    );
  }
}
