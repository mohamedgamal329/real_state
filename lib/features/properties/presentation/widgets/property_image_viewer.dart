import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_network_image.dart';

class PropertyImageViewer extends StatefulWidget {
  const PropertyImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<PropertyImageViewer> createState() => _PropertyImageViewerState();
}

class _PropertyImageViewerState extends State<PropertyImageViewer> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceDim.withValues(alpha: 0.98);
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (_, index) {
              final url = widget.images[index];
              return InteractiveViewer(
                child: Center(
                  child: AppNetworkImage(
                    url: url,
                    fit: BoxFit.contain,
                    borderRadius: 0,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close),
              onPressed: () => GoRouter.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
