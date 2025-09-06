// lib/screens/incident_chat_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../widgets/simple_guided_bot.dart';

class IncidentChatPage extends StatelessWidget {
  final ApiClient api;
  final String ref;
  const IncidentChatPage({super.key, required this.api, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SimpleGuidedBot(
          incidentRef: ref,
          patchIncident: (patch) async {
            await api.updateIncident(ref, patch);
          },
          uploadImages: (List<File> files) async {
            await api.uploadIncidentImages(ref, files);
          },
        ),
      ),
    );
  }
}
