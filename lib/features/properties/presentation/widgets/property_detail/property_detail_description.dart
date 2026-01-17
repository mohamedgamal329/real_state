import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PropertyDetailDescription extends StatelessWidget {
  const PropertyDetailDescription({
    super.key,
    required this.description,
    required this.isExpanded,
    required this.canExpand,
    required this.onToggle,
    required this.textStyle,
  });

  final String description;
  final bool isExpanded;
  final bool canExpand;
  final VoidCallback onToggle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: textStyle,
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (canExpand)
            TextButton(
              onPressed: onToggle,
              child: Text(isExpanded ? 'show_less'.tr() : 'read_more'.tr()),
            ),
        ],
      ),
    );
  }
}
