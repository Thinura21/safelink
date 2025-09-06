import 'dart:io';

import 'package:flutter/material.dart';
import '../../widgets/simple_guided_bot.dart';

class AssistantPage extends StatelessWidget {
  final String incidentRef;
  final Future<void> Function(Map<String, dynamic>) patchIncident;
  final Future<void> Function(List<File>) uploadImages;

  const AssistantPage({
    super.key,
    required this.incidentRef,
    required this.patchIncident,
    required this.uploadImages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SimpleGuidedBot(
          incidentRef: incidentRef,
          patchIncident: patchIncident,
          uploadImages: uploadImages,
        ),
      ),
    );
  }
}
