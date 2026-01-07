import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LoadingDialog {
  static Future<T> show<T>(BuildContext context, Future<T> future) async {
    BuildContext? dialogContext;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (c) {
        dialogContext = c;
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(c).size.width * 0.28,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 54,
                  width: 54,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'loading'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'please_wait'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      return await future;
    } finally {
      final ctx = dialogContext ?? context;
      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
    }
  }
}
