import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF8F9FC);
  static const Color textPrimary = Color(0xFF191B2A);
  static const Color textSecondary = Color(0xFF77798A);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ColoredBox(
      color: background,
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            36,
          ),
          children: [
            _buildHeader(context),

            const SizedBox(height: 24),

            _ProfileHero(auth: auth),

            const SizedBox(height: 28),

            const _SectionTitle(
              title: 'Account',
            ),

            const SizedBox(height: 10),

            _ProfileSection(
              children: [
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal information',
                  subtitle: 'Name, email and phone number',
                  onTap: () {
                    _openPersonalInformation(context);
                  },
                ),
                const _ProfileDivider(),
                _ProfileMenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Security',
                  subtitle: 'Password and account security',
                  onTap: () {
                    _openSecurity(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            const _SectionTitle(
              title: 'Preferences',
            ),

            const SizedBox(height: 10),

            _ProfileSection(
              children: [
                _ProfileMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage booking notifications',
                  onTap: () {
                    _showInfoMessage(
                      context,
                      'Notification preferences will be added next.',
                    );
                  },
                ),
                const _ProfileDivider(),
                _ProfileMenuItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {
                    _openLanguage(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            const _SectionTitle(
              title: 'Support',
            ),

            const SizedBox(height: 10),

            _ProfileSection(
              children: [
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  subtitle: 'Get help with NexaBook',
                  onTap: () {
                    _openHelp(context);
                  },
                ),
                const _ProfileDivider(),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About NexaBook',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    _openAbout(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  _confirmSignOut(
                    context,
                    auth,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFFD94343),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFFF0DADA),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'NexaBook',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB1B2BD),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(
          'Profile',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }

  Future<void> _openPersonalInformation(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return const _PersonalInformationSheet();
      },
    );
  }

  Future<void> _openSecurity(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return const _ChangePasswordSheet();
      },
    );
  }

  void _openLanguage(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),

              const SizedBox(height: 22),

              const Text(
                'Language',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choose your preferred language.',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              _LanguageTile(
                title: 'English',
                selected: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                },
              ),

              const SizedBox(height: 8),

              _LanguageTile(
                title: 'Shqip',
                selected: false,
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  _showInfoMessage(
                    context,
                    'Albanian language will be added next.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHelp(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return const _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),

              SizedBox(height: 22),

              Icon(
                Icons.support_agent_rounded,
                color: primary,
                size: 44,
              ),

              SizedBox(height: 14),

              Text(
                'Help & support',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Need help with a booking or your account? '
                'Support options will be available here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAbout(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return const _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),

              SizedBox(height: 22),

              _NexaBookLogo(),

              SizedBox(height: 16),

              Text(
                'NexaBook',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),

              SizedBox(height: 18),

              Text(
                'A simpler way to discover services '
                'and manage your appointments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final shouldLogout =
        await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),

              const SizedBox(height: 22),

              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFD94343),
                  size: 27,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Sign out?',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Are you sure you want to sign out '
                'of your NexaBook account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop(false);
                        },
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              textPrimary,
                          side: const BorderSide(
                            color:
                                Color(0xFFE2E3E9),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop(true);
                        },
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFD94343,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      await auth.logout();
    }
  }

  static void _showInfoMessage(
    BuildContext context,
    String message,
  ) {
    final messenger =
        ScaffoldMessenger.maybeOf(context);

    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
}

// ============================================================
// PERSONAL INFORMATION
// ============================================================

class _PersonalInformationSheet
    extends StatefulWidget {
  const _PersonalInformationSheet();

  @override
  State<_PersonalInformationSheet> createState() =>
      _PersonalInformationSheetState();
}

class _PersonalInformationSheetState
    extends State<_PersonalInformationSheet> {
  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadProfile();
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data =
          await context.read<ApiClient>().get(
        '/client/profile',
      );

      if (!mounted) {
        return;
      }

      if (data is! Map) {
        setState(() {
          _loading = false;
          _loadError =
              'Invalid profile response.';
        });

        return;
      }

      _firstNameController.text =
          data['firstName']?.toString() ?? '';

      _lastNameController.text =
          data['lastName']?.toString() ?? '';

      _emailController.text =
          data['email']?.toString() ?? '';

      _phoneController.text =
          data['phone']?.toString() ?? '';

      setState(() {
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadError =
            'Could not load profile.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }

    final firstName =
        _firstNameController.text.trim();

    final lastName =
        _lastNameController.text.trim();

    final email =
        _emailController.text.trim();

    final phone =
        _phoneController.text.trim();

    if (firstName.isEmpty) {
      _showMessage(
        'First name is required.',
      );

      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Email is required.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<ApiClient>().put(
        '/client/profile',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      return;
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Could not update profile.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      child: AnimatedPadding(
        duration:
            const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.viewInsetsOf(context)
                  .bottom,
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          SizedBox(height: 42),
          CircularProgressIndicator(),
          SizedBox(height: 42),
        ],
      );
    }

    if (_loadError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),

          const SizedBox(height: 28),

          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFD94343),
          ),

          const SizedBox(height: 12),

          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfilePage.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });

                _loadProfile();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),

          const SizedBox(height: 22),

          const Text(
            'Personal information',
            style: TextStyle(
              color: ProfilePage.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Update your account details.',
            style: TextStyle(
              color: ProfilePage.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _AppField(
                  controller:
                      _firstNameController,
                  label: 'First name',
                  icon:
                      Icons.person_outline_rounded,
                  textInputAction:
                      TextInputAction.next,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _AppField(
                  controller:
                      _lastNameController,
                  label: 'Last name',
                  icon:
                      Icons.person_outline_rounded,
                  textInputAction:
                      TextInputAction.next,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _AppField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _AppField(
            controller: _phoneController,
            label: 'Phone',
            icon: Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            textInputAction:
                TextInputAction.done,
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed:
                  _saving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor:
                    ProfilePage.primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHANGE PASSWORD
// ============================================================

class _ChangePasswordSheet
    extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState
    extends State<_ChangePasswordSheet> {
  final TextEditingController _currentController =
      TextEditingController();

  final TextEditingController _newController =
      TextEditingController();

  final TextEditingController _confirmController =
      TextEditingController();

  bool _saving = false;

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();

    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_saving) {
      return;
    }

    final currentPassword =
        _currentController.text;

    final newPassword =
        _newController.text;

    final confirmPassword =
        _confirmController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Complete all password fields.',
      );

      return;
    }

    if (newPassword.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
      );

      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<ApiClient>().put(
        '/client/profile/password',
        data: {
          'currentPassword':
              currentPassword,
          'newPassword':
              newPassword,
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      return;
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Could not change password. '
        'Check your current password.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      child: AnimatedPadding(
        duration:
            const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.viewInsetsOf(context)
                  .bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),

              const SizedBox(height: 22),

              const Text(
                'Security',
                style: TextStyle(
                  color: ProfilePage.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Change your account password.',
                style: TextStyle(
                  color:
                      ProfilePage.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              _AppField(
                controller:
                    _currentController,
                label: 'Current password',
                icon:
                    Icons.lock_outline_rounded,
                obscureText: !_showCurrent,
                textInputAction:
                    TextInputAction.next,
                suffixIcon: IconButton(
                  tooltip: _showCurrent
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: () {
                    setState(() {
                      _showCurrent =
                          !_showCurrent;
                    });
                  },
                  icon: Icon(
                    _showCurrent
                        ? Icons
                            .visibility_off_outlined
                        : Icons
                            .visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _AppField(
                controller: _newController,
                label: 'New password',
                icon: Icons.key_rounded,
                obscureText: !_showNew,
                textInputAction:
                    TextInputAction.next,
                suffixIcon: IconButton(
                  tooltip: _showNew
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: () {
                    setState(() {
                      _showNew = !_showNew;
                    });
                  },
                  icon: Icon(
                    _showNew
                        ? Icons
                            .visibility_off_outlined
                        : Icons
                            .visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _AppField(
                controller:
                    _confirmController,
                label: 'Confirm new password',
                icon: Icons.key_rounded,
                obscureText: !_showConfirm,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  if (!_saving) {
                    _changePassword();
                  }
                },
                suffixIcon: IconButton(
                  tooltip: _showConfirm
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: () {
                    setState(() {
                      _showConfirm =
                          !_showConfirm;
                    });
                  },
                  icon: Icon(
                    _showConfirm
                        ? Icons
                            .visibility_off_outlined
                        : Icons
                            .visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : _changePassword,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        ProfilePage.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Change password',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE COMPONENTS
// ============================================================

class _ProfileHero extends StatelessWidget {
  final AuthProvider auth;

  const _ProfileHero({
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        auth.name?.trim().isNotEmpty == true
            ? auth.name!
            : 'NexaBook User';

    final displayEmail =
        auth.email?.trim().isNotEmpty == true
            ? auth.email!
            : 'No email available';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFEBECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF9288FF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ProfilePage.primary
                      .withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 22,
                  offset:
                      const Offset(0, 9),
                ),
              ],
            ),
            child: Text(
              auth.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfilePage.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            displayEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  ProfilePage.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0EFFF),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons
                      .verified_user_outlined,
                  size: 15,
                  color: ProfilePage.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'NexaBook Client',
                  style: TextStyle(
                    color:
                        ProfilePage.primary,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF999BA8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ProfileSection
    extends StatelessWidget {
  final List<Widget> children;

  const _ProfileSection({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEBECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.02,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfileMenuItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3F2FF),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: ProfilePage.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF252733),
                        fontSize: 14.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF999BA8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB0B2BD),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDivider
    extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 72,
        right: 16,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF0F1F5),
      ),
    );
  }
}

// ============================================================
// COMMON COMPONENTS
// ============================================================

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _AppField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            const Color(0xFFF8F9FC),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE7E8EE),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE7E8EE),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: ProfilePage.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetContainer
    extends StatelessWidget {
  final Widget child;

  const _BottomSheetContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(
        22,
        12,
        22,
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHandle
    extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E3E9),
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _LanguageTile
    extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFF3F2FF)
          : const Color(0xFFF8F9FC),
      borderRadius:
          BorderRadius.circular(15),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: ProfilePage.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: ProfilePage.primary,
              )
            : null,
      ),
    );
  }
}

class _NexaBookLogo
    extends StatelessWidget {
  const _NexaBookLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8B80FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}