import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Locale picker with a smooth dialog to avoid partial language updates.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  Future<void> _openDialog(BuildContext context) async {
    final rootContext = context;
    final currentLocale = rootContext.locale;

    await showGeneralDialog(
      context: rootContext,
      barrierDismissible: true,
      barrierLabel: 'language'.tr(),
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => _LanguageDialog(
        currentLocale: currentLocale,
        onSelect: (loc) async {
          if (loc == currentLocale) return;
          await rootContext.setLocale(loc);
        },
      ),
      transitionBuilder: (ctx, animation, __, child) {
        final curved = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 0.92 + (0.08 * curved),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'language'.tr(),
      onPressed: () => _openDialog(context),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              current,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  final Locale currentLocale;
  final Future<void> Function(Locale) onSelect;

  const _LanguageDialog({required this.currentLocale, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      (const Locale('ar'), 'arabic'.tr(), 'العربية'),
      (const Locale('en'), 'english'.tr(), 'English'),
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 8, 4),
                    child: Row(
                      children: [
                        Icon(Icons.language, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'language'.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          splashRadius: 20,
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...items.map(
                    (item) => _LanguageTile(
                      locale: item.$1,
                      title: item.$2,
                      nativeLabel: item.$3,
                      isSelected:
                          currentLocale.languageCode == item.$1.languageCode,
                      onTap: () async {
                        await onSelect(item.$1);
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale locale;
  final String title;
  final String nativeLabel;
  final bool isSelected;
  final Future<void> Function() onTap;

  const _LanguageTile({
    required this.locale,
    required this.title,
    required this.nativeLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bg,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                locale.languageCode.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    nativeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(Icons.check_circle, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
