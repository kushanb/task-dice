import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../widgets/press_scale.dart';

/// First screen for a signed-out user. Single action: continue with Google.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.onSignIn});

  /// Performs the sign-in. Throwing surfaces the message inline.
  final Future<void> Function() onSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignIn();
      // On success the auth stream swaps this screen out; no navigation here.
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _DiceMark()),
                  const SizedBox(height: AppSpacing.s24),
                  Text('TaskDice', style: AppText.pageTitle, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Roll for what to work on, then track the focus behind it.',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _GoogleButton(busy: _busy, onTap: _busy ? null : _signIn),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      _error!,
                      style: AppText.meta.copyWith(color: AppColors.redSoftText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  Text(
                    'Your tasks sync privately to your account.',
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.rButton),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.inverseText),
                ),
              )
            : Text(
                'Continue with Google',
                style: AppText.buttonLarge.copyWith(color: AppColors.inverseText),
              ),
      ),
    );
  }
}

/// The app mark — the Roll screen's five-face, at rest.
class _DiceMark extends StatelessWidget {
  const _DiceMark();

  @override
  Widget build(BuildContext context) {
    const filled = {0, 2, 4, 6, 8};
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadii.rDice * 88 / 120),
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 9; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: filled.contains(i)
                        ? AppColors.green
                        : const Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
