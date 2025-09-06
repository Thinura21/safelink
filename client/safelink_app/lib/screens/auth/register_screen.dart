import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../core/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final ApiClient api;
  const RegisterScreen({super.key, required this.api});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _message;
  String? _friendlyErr;
  bool _agreed = false; // UI-only gate

  void _toggleLang() => AppState.toggleLang();
  String _msgFor(ApiException e) => I18n.error(AppState.lang.value, e.code);

  String _pwMismatchMsg(String lang) =>
      lang == 'si' ? 'මුරපද නොගැලපේ' : 'Passwords do not match';

  Future<void> _register() async {
    final lang = AppState.lang.value;

    if (_password.text != _confirm.text) {
      setState(() { _friendlyErr = _pwMismatchMsg(lang); });
      return;
    }
    if (!_agreed) {
      setState(() {
        _friendlyErr = lang == 'si'
            ? 'දෙකරණ සහ නියමයන්ට එකඟ විය යුතුය'
            : 'You must accept the Terms & Conditions to continue';
      });
      return;
    }

    setState(() { _loading = true; _message = null; _friendlyErr = null; });
    try {
      await widget.api.registerUser(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
      );
      setState(() { _message = I18n.t(lang, 'register.success'); });
    } on ApiException catch (e) {
      setState(() { _friendlyErr = _msgFor(e); });
    } catch (_) {
      setState(() { _friendlyErr = I18n.error(lang, 'NETWORK'); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phoneNumber.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState.lang.value;
    final t = (String k) => I18n.t(lang, k);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.textPrimary,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'Join SafeLink',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your emergency SafeLink account',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Form fields
                AppTextField(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t('error.required') : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t('error.required') : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneNumber,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t('error.required') : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _password,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? t('error.required') : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _register(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return t('error.required');
                    if (v != _password.text) return _pwMismatchMsg(lang);
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Terms and conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: _loading ? null : (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                        child: RichText(
                          text: TextSpan(
                            text: lang == 'si' ? 'මම ' : 'I have read and agree to the ',
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Success message
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppTheme.successColor),
                    ),
                  ),

                // Error message
                if (_friendlyErr != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      _friendlyErr!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),

                // Create Account button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider with OR
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sign in section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account ? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}