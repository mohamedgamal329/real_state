import 'package:flutter/widgets.dart';

import 'property_page_body.dart';

class PropertyPage extends StatelessWidget {
  final String id;
  final bool readOnly;

  const PropertyPage({super.key, required this.id, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return PropertyPageBody(id: id, readOnly: readOnly);
  }
}
