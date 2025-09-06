// lib/screens/terms/terms_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _lastUpdated = 'Last updated: Sep 3, 2025';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.textPrimary,
        ),
        title: const Text('Terms & Conditions',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SafeLink Terms & Conditions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text('Welcome to SafeLink, the Emergency Application',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                Text('By using SafeLink, you agree to the following terms and conditions:',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Section('1. Proper Usage',
                        'You agree to use SafeLink only for legitimate emergency situations. Misuse of emergency services is a serious offense.'),
                    _Section('2. Legal Consequences',
                        'Making false emergency reports or prank calls is punishable by law. Penalties may include fines and imprisonment.'),
                    _Section('3. Accurate Information',
                        'Provide accurate and truthful information when reporting emergencies. False reporting may result in legal action.'),
                    _Section('4. Location Services',
                        'By using SafeLink, you consent to location tracking during emergency situations to ensure proper response.'),
                    _Section('5. Data Privacy',
                        'Your personal information and emergency data are handled per our privacy policy and may be shared with authorities when required.'),
                    _Section('6. Service Availability',
                        'We strive for 24/7 availability but cannot guarantee uninterrupted service due to technical or network issues.'),
                    _Section('7. User Responsibility',
                        'Keep your contact information updated and ensure your device is functional.'),
                    _Section('8. Limitation of Liability',
                        'SafeLink is a communication platform and is not responsible for response times or outcomes.'),
                    _Section('9. Updates to Terms',
                        'These terms may be updated periodically. Continued use constitutes acceptance of revised terms.'),
                    _Section('10. Contact',
                        'For questions, email support@safelink.lk'),
                    SizedBox(height: 24),
                    Text(_lastUpdated,
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Accept and Continue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
