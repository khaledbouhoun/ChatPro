import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../controllers/login_controller.dart';
import '../../core/theme.dart';

// ─── LoginScreen ─────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final LoginController _ctrl;
  late final AnimationController _orbCtrl;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // for register
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();

  final RxBool _obscurePass = true.obs;
  final RxBool _emailFocused = false.obs;
  final RxBool _passFocused = false.obs;
  final RxBool _nameFocused = false.obs;
  final RxString _emailError = ''.obs;
  final RxString _passError = ''.obs;
  final RxString _nameError = ''.obs;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(LoginController());
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _emailFocus.addListener(() => _emailFocused.value = _emailFocus.hasFocus);
    _passFocus.addListener(() => _passFocused.value = _passFocus.hasFocus);
    _nameFocus.addListener(() => _nameFocused.value = _nameFocus.hasFocus);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  bool _validate() {
    bool ok = true;
    _emailError.value = '';
    _passError.value = '';
    _nameError.value = '';

    if (!_ctrl.isLogin.value && _nameCtrl.text.trim().isEmpty) {
      _nameError.value = 'Full name is required';
      ok = false;
    }

    if (_emailCtrl.text.trim().isEmpty) {
      _emailError.value = 'Email is required';
      ok = false;
    } else if (!GetUtils.isEmail(_emailCtrl.text.trim())) {
      _emailError.value = 'Enter a valid email';
      ok = false;
    }

    if (_passwordCtrl.text.isEmpty) {
      _passError.value = 'Password is required';
      ok = false;
    } else if (_passwordCtrl.text.length < 6) {
      _passError.value = 'Minimum 6 characters';
      ok = false;
    }

    return ok;
  }

  Future<void> _handleAuth() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      HapticFeedback.vibrate();
      return;
    }

    final success = await _ctrl.authenticate(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
    );

    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/home');
      });
    } else {
      HapticFeedback.vibrate();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Authentication Failed',
          'Invalid credentials. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.card,
          colorText: AppTheme.textPrim,
          borderColor: AppTheme.error.withValues(alpha: 0.4),
          borderWidth: 0.5,
          borderRadius: 16,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 350),
          forwardAnimationCurve: Curves.easeOutBack,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertCircle, color: AppTheme.error, size: 18),
          ),
          shouldIconPulse: false,
        );
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _AnimatedAurora(controller: _orbCtrl),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 36),
                    _buildForm(),
                    const SizedBox(height: 20),
                    _buildForgotPassword(),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildSocialRow(),
                    const SizedBox(height: 32),
                    _buildToggleAuth(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.aurora1, AppTheme.aurora2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Chat',
                style: TextStyle(color: AppTheme.textPrim, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              TextSpan(
                text: 'Pro',
                style: TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeader() {
    return Obx(() {
      final isLogin = _ctrl.isLogin.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              isLogin ? 'Welcome back' : 'Create account',
              key: ValueKey(isLogin),
              style: const TextStyle(
                color: AppTheme.textPrim,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isLogin ? 'Sign in to continue your conversations' : 'Join the next generation of messaging',
              key: ValueKey('sub_$isLogin'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.15, end: 0, curve: Curves.easeOut);
    });
  }

  Widget _buildForm() {
    return Obx(() {
      final isLogin = _ctrl.isLogin.value;
      return Column(
        children: [
          // Name field (register only)
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: isLogin
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AnimatedField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      focused: _nameFocused,
                      label: 'Full Name',
                      hint: 'John Doe',
                      icon: LucideIcons.user,
                      textInputAction: TextInputAction.next,
                      errorText: _nameError,
                      onSubmitted: () => _emailFocus.requestFocus(),
                    ),
                  ),
          ),
          _AnimatedField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            focused: _emailFocused,
            label: 'Email address',
            hint: 'you@example.com',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onSubmitted: () => _passFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          _AnimatedField(
            controller: _passwordCtrl,
            focusNode: _passFocus,
            focused: _passFocused,
            label: 'Password',
            hint: '••••••••',
            icon: LucideIcons.lock,
            obscure: _obscurePass,
            onToggleObscure: () => _obscurePass.value = !_obscurePass.value,
            textInputAction: TextInputAction.done,
            errorText: _passError,
            onSubmitted: () => _handleAuth(),
          ),
        ],
      );
    }).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildForgotPassword() {
    return Obx(
      () => _ctrl.isLogin.value
          ? Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final loading = _ctrl.isLoading.value;
      final isLogin = _ctrl.isLogin.value;
      return GestureDetector(
        onTap: loading ? null : _handleAuth,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: loading ? [AppTheme.textMuted, AppTheme.textMuted] : [AppTheme.aurora1, AppTheme.accent, AppTheme.aurora2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                loading ? [] : [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin ? 'Sign In' : 'Create Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
    });
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
      ],
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(icon: LucideIcons.chrome, label: 'Google', onTap: () {}),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(icon: LucideIcons.github, label: 'GitHub', onTap: () {}),
        ),
      ],
    ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.15, end: 0);
  }

  Widget _buildToggleAuth() {
    return Center(
      child: GestureDetector(
        onTap: () {
          _ctrl.toggleAuthMode();
          _emailError.value = '';
          _passError.value = '';
          _nameError.value = '';
        },
        child: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: RichText(
              key: ValueKey(_ctrl.isLogin.value),
              text: TextSpan(
                text: _ctrl.isLogin.value ? "Don't have an account?  " : 'Already have an account?  ',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                children: [
                  TextSpan(
                    text: _ctrl.isLogin.value ? 'Register' : 'Sign in',
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: 500.ms).fadeIn();
  }
}

// ─── Animated Aurora ──────────────────────────────────────────────────────

class _AnimatedAurora extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedAurora({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final sin1 = math.sin(t * math.pi * 2);
        final sin2 = math.sin(t * math.pi * 2 + 2);
        return Stack(
          children: [
            Container(color: AppTheme.bg),
            Positioned(
              top: -120 + sin1 * 20,
              right: -100 + sin2 * 15,
              child: Container(
                width: 360,
                height: 360,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x200EA5E9), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.35 + sin2 * 25,
              left: -140 + sin1 * 10,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x156366F1), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: -80 + sin1 * 15,
              right: -80 + sin2 * 10,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x128B5CF6), Colors.transparent]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Animated Text Field ──────────────────────────────────────────────────

class _AnimatedField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final RxBool focused;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final RxBool? obscure;
  final VoidCallback? onToggleObscure;
  final RxString? errorText;
  final VoidCallback? onSubmitted;

  const _AnimatedField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscure,
    this.onToggleObscure,
    this.errorText,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocused = focused.value;
      final hasError = (errorText?.value ?? '').isNotEmpty;
      final isObscured = obscure?.value ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? AppTheme.error.withValues(alpha: 0.6)
                    : isFocused
                        ? AppTheme.accent.withValues(alpha: 0.6)
                        : AppTheme.border,
                width: isFocused || hasError ? 1.2 : 0.8,
              ),
              boxShadow: isFocused && !hasError
                  ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        key: ValueKey(isFocused),
                        size: 18,
                        color: hasError
                            ? AppTheme.error
                            : isFocused
                                ? AppTheme.accent
                                : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: isObscured,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    style: const TextStyle(color: AppTheme.textPrim, fontSize: 14.5),
                    onSubmitted: (_) => onSubmitted?.call(),
                    decoration: InputDecoration(
                      hintText: hint,
                      labelText: label,
                      labelStyle: TextStyle(color: isFocused ? AppTheme.accent : AppTheme.textMuted, fontSize: 13),
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    ),
                  ),
                ),
                if (obscure != null)
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: onToggleObscure,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isObscured ? LucideIcons.eye : LucideIcons.eyeOff,
                            key: ValueKey(isObscured),
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 12, color: AppTheme.error),
                        const SizedBox(width: 4),
                        Text(errorText!.value, style: const TextStyle(color: AppTheme.error, fontSize: 11)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

// ─── Social Button ────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.textSec),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSec, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
