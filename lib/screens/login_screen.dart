import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _submit() async {
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (_isLogin) {
        await auth.login(_emailController.text.trim(), _passwordController.text);
        if (mounted) {
          setState(() => _isLoading = false);
          context.go(AppRoutes.main);
        }
      } else {
        await auth.signUp(_emailController.text.trim(), _passwordController.text);
        if (mounted) {
          setState(() => _isLoading = false);
          context.go(AppRoutes.welcomeName);
        }
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isLogin ? 'Login failed. Please try again.' : 'Sign up failed. Please try again.';
        });
      }
    }
  }

  void _toggleLoginMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sign-in coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  color: colorScheme.primary,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kitchenly',
                  style: textStyles.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your kitchen companion.',
                  style: textStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_errorMessage != null) ...[
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: colorScheme.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textStyles.bodySmall
                                ?.copyWith(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    labelText: 'Email',
                    filled: true,
                    fillColor: colorScheme.surface,
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Password',
                    labelText: 'Password',
                    filled: true,
                    fillColor: colorScheme.surface,
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _isLogin
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Password reset coming soon!'),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: textStyles.labelLarge
                            ?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  secondChild: const SizedBox(height: 16),
                ),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colorScheme.onPrimary))
                      : Text(
                          _isLogin ? 'Log In' : 'Sign Up',
                          style: textStyles.titleMedium
                              ?.copyWith(color: colorScheme.onPrimary),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or', style: textStyles.bodySmall),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIconButton(Icons.g_mobiledata_rounded,
                        colorScheme, () => _showComingSoon('Google')),
                    const SizedBox(width: AppSpacing.lg),
                    _buildSocialIconButton(Icons.apple_rounded, colorScheme,
                        () => _showComingSoon('Apple')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account?"
                          : "Already have an account?",
                      style: textStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _toggleLoginMode,
                      child: Text(
                        _isLogin ? 'Sign up' : 'Log in',
                        style: textStyles.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIconButton(
      IconData icon, ColorScheme colorScheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 32),
      ),
    );
  }
}
