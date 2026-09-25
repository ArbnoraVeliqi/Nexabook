import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode lastNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;

  String? error;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _setError('Please fill in all required fields.');
      return;
    }

    if (!_isValidEmail(email)) {
      _setError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _setError('Password must contain at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _setError('Passwords do not match.');
      return;
    }

    if (!acceptedTerms) {
      _setError(
        'Please accept the Terms of Service and Privacy Policy.',
      );
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final success = await context.read<AuthProvider>().register(
            firstName,
            lastName,
            email,
            password,
            phone,
          );

      if (!mounted) {
        return;
      }

      if (success) {
        Navigator.pop(context);
        return;
      }

      _setError(
        'Could not create your account. The email may already be in use.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _setError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      error = message;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Stack(
          children: [
            const _RegisterBackground(),

            Positioned(
              top: 8,
              left: 12,
              child: _buildBackButton(),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  72,
                  24,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 460,
                  ),
                  child: Column(
                    children: [
                      _buildLogo(),

                      const SizedBox(height: 24),

                      Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF191B2A),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Join NexaBook and book your favorite\nservices in just a few taps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF77798A),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildRegisterCard(),

                      const SizedBox(height: 22),

                      _buildLoginSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEBECF2),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 21,
            color: Color(0xFF252733),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8B80FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(
              alpha: 0.22,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFEBECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 35,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameFields(),

          const SizedBox(height: 16),

          _buildEmailField(),

          const SizedBox(height: 16),

          _buildPhoneField(),

          const SizedBox(height: 16),

          _buildPasswordField(),

          const SizedBox(height: 16),

          _buildConfirmPasswordField(),

          const SizedBox(height: 16),

          _buildTerms(),

          if (error != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(),
          ],

          const SizedBox(height: 24),

          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            children: [
              _buildFirstNameField(),
              const SizedBox(height: 16),
              _buildLastNameField(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildFirstNameField(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLastNameField(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirstNameField() {
    return TextField(
      controller: firstNameController,
      focusNode: firstNameFocusNode,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.givenName,
      ],
      onSubmitted: (_) {
        lastNameFocusNode.requestFocus();
      },
      decoration: _inputDecoration(
        label: 'First name',
        hint: 'John',
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildLastNameField() {
    return TextField(
      controller: lastNameController,
      focusNode: lastNameFocusNode,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.familyName,
      ],
      onSubmitted: (_) {
        emailFocusNode.requestFocus();
      },
      decoration: _inputDecoration(
        label: 'Last name',
        hint: 'Doe',
        icon: Icons.badge_outlined,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      focusNode: emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.email,
      ],
      onSubmitted: (_) {
        phoneFocusNode.requestFocus();
      },
      decoration: _inputDecoration(
        label: 'Email address',
        hint: 'you@example.com',
        icon: Icons.mail_outline_rounded,
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: phoneController,
      focusNode: phoneFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.telephoneNumber,
      ],
      onSubmitted: (_) {
        passwordFocusNode.requestFocus();
      },
      decoration: _inputDecoration(
        label: 'Phone number',
        hint: '+383 44 000 000',
        icon: Icons.phone_outlined,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      focusNode: passwordFocusNode,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.newPassword,
      ],
      onSubmitted: (_) {
        confirmPasswordFocusNode.requestFocus();
      },
      decoration: _inputDecoration(
        label: 'Password',
        hint: 'Create a password',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF8A8C9B),
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: confirmPasswordController,
      focusNode: confirmPasswordFocusNode,
      obscureText: obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [
        AutofillHints.newPassword,
      ],
      onSubmitted: (_) {
        _register();
      },
      decoration: _inputDecoration(
        label: 'Confirm password',
        hint: 'Repeat your password',
        icon: Icons.lock_reset_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscureConfirmPassword = !obscureConfirmPassword;
            });
          },
          icon: Icon(
            obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF8A8C9B),
            size: 21,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 21,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      labelStyle: const TextStyle(
        color: Color(0xFF737586),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB2B4C0),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFEBECF2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF6C63FF),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          acceptedTerms = !acceptedTerms;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: acceptedTerms,
                activeColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (value) {
                  setState(() {
                    acceptedTerms = value ?? false;
                  });
                },
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Color(0xFF77798A),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'I agree to the ',
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' and ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE5484D),
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFB42328),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : _register,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          disabledBackgroundColor:
              const Color(0xFF6C63FF).withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Row(
                  key: ValueKey('register'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            color: Color(0xFF77798A),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Sign in',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(
                  alpha: 0.07,
                ),
              ),
            ),
          ),
          Positioned(
            top: 320,
            left: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B94FF).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}