import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/features/properties/domain/services/property_upload_service.dart';

class PropertyUploadInitializer extends StatefulWidget {
  const PropertyUploadInitializer({super.key, required this.child});

  final Widget child;

  @override
  State<PropertyUploadInitializer> createState() =>
      _PropertyUploadInitializerState();
}

class _PropertyUploadInitializerState extends State<PropertyUploadInitializer>
    with WidgetsBindingObserver {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumePending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumePending();
    }
  }

  void _resumePending() {
    if (_started) return;
    _started = true;
    context.read<PropertyUploadService>().resumePendingUploads().whenComplete(
      () => _started = false,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
