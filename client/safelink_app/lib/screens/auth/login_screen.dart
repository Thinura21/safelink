import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;
  String? _friendlyErr;

  Future<void> _login() async {
    setState(() { _loading = true; _friendlyErr = null; });
    try {
      final res = await widget.api.login(_email.text.trim(), _password.text);
      await AuthStorage.saveTokens(res.token, res.refreshToken);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _friendlyErr = 'Unable to sign in. Please check your credentials or try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text('Welcome Back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  )),
              const SizedBox(height: 8),
              Text('Sign in to your SafeLink account',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  )),
              const SizedBox(height: 40),

              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _login(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: _loading ? null : (v) => setState(() => _rememberMe = v ?? false),
                  ),
                  Text('Remember me', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: _loading ? null : () {},
                    child: Text('Forgot password?', style: TextStyle(color: AppTheme.primaryRed)),
                  ),
                ],
              ),

              const SizedBox(height: 12),
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
                  child: Text(_friendlyErr!, style: const TextStyle(color: AppTheme.errorColor)),
                ),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign In',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Divider(color: AppTheme.borderColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider(color: AppTheme.borderColor)),
              ]),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account ? ", style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pushNamed(context, '/register'),
                    child: Text('Sign Up',
                        style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
