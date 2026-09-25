
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _cancellationHoursController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;
  bool _saving = false;

  String _currency = 'EUR';

  final List<String> _currencies = [
    'EUR',
    'USD',
    'GBP',
    'CHF',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxRateController.dispose();
    _cancellationHoursController.dispose();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final response = await context
          .read<ApiClient>()
          .get('/settings');

      if (!mounted) {
        return;
      }

      final data = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};

      _businessNameController.text =
          data['businessName']?.toString() ?? '';

      _emailController.text =
          data['email']?.toString() ?? '';

      _phoneController.text =
          data['phone']?.toString() ?? '';

      _taxRateController.text =
          _numberText(data['taxRate'], '0');

      _cancellationHoursController.text =
          _numberText(
            data['cancellationHours'],
            '24',
          );

      final currency =
          data['currency']?.toString().trim();

      if (currency != null &&
          currency.isNotEmpty &&
          _currencies.contains(currency)) {
        _currency = currency;
      } else {
        _currency = 'EUR';
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Could not load settings.',
        error: true,
      );
    }
  }

  Future<void> _saveSettings() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final taxRate = double.tryParse(
          _taxRateController.text.trim(),
        ) ??
        0;

    final cancellationHours = int.tryParse(
          _cancellationHoursController.text.trim(),
        ) ??
        0;

    setState(() {
      _saving = true;
    });

    try {
await context.read<ApiClient>().put(
  '/settings',
  data: {
    'businessName': _businessNameController.text.trim(),
    'email': _emailController.text.trim(),
    'phone': _phoneController.text.trim(),
    'currency': _currency,
    'taxRate': taxRate,
    'cancellationHours': cancellationHours,
  },
);
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Settings saved successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Could not save settings.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const PageHeader(
            'Settings',
            'Manage your business information and booking preferences',
          ),

          const SizedBox(height: 26),

          if (_loading)
            _buildLoading()
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBusinessSection(),

                  const SizedBox(height: 18),

                  _buildFinancialSection(),

                  const SizedBox(height: 18),

                  _buildBookingSection(),

                  const SizedBox(height: 24),

                  _buildSaveSection(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection() {
    return _section(
      icon: Icons.storefront_outlined,
      title: 'Business information',
      subtitle:
          'Basic information shown across your NexaBook workspace.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns =
              constraints.maxWidth >= 700;

          if (!twoColumns) {
            return Column(
              children: [
                _businessNameField(),
                const SizedBox(height: 16),
                _emailField(),
                const SizedBox(height: 16),
                _phoneField(),
              ],
            );
          }

          return Column(
            children: [
              _businessNameField(),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _emailField(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _phoneField(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _businessNameField() {
    return TextFormField(
      controller: _businessNameController,
      decoration: _inputDecoration(
        label: 'Business name',
        hint: 'Enter your business name',
        icon: Icons.business_outlined,
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Business name is required.';
        }

        return null;
      },
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType:
          TextInputType.emailAddress,
      decoration: _inputDecoration(
        label: 'Email',
        hint: 'business@example.com',
        icon: Icons.mail_outline_rounded,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return null;
        }

        if (!text.contains('@') ||
            !text.contains('.')) {
          return 'Enter a valid email.';
        }

        return null;
      },
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _inputDecoration(
        label: 'Phone',
        hint: '+383...',
        icon: Icons.phone_outlined,
      ),
    );
  }

  Widget _buildFinancialSection() {
    return _section(
      icon: Icons.payments_outlined,
      title: 'Financial settings',
      subtitle:
          'Configure the currency and tax used by your business.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns =
              constraints.maxWidth >= 700;

          final currency = DropdownButtonFormField<String>(
            value: _currency,
            decoration: _inputDecoration(
              label: 'Currency',
              hint: 'Select currency',
              icon:
                  Icons.currency_exchange_rounded,
            ),
            items: _currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(
                  _currencyLabel(currency),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _currency = value;
              });
            },
          );

          final tax = TextFormField(
            controller: _taxRateController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _inputDecoration(
              label: 'Tax rate',
              hint: '0',
              icon: Icons.percent_rounded,
              suffix: '%',
            ),
            validator: (value) {
              final number = double.tryParse(
                value?.trim() ?? '',
              );

              if (number == null) {
                return 'Enter a valid tax rate.';
              }

              if (number < 0 ||
                  number > 100) {
                return 'Tax must be between 0 and 100.';
              }

              return null;
            },
          );

          if (!twoColumns) {
            return Column(
              children: [
                currency,
                const SizedBox(height: 16),
                tax,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: currency,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: tax,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingSection() {
    return _section(
      icon: Icons.calendar_month_outlined,
      title: 'Booking settings',
      subtitle:
          'Configure how cancellations are handled.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final field = TextFormField(
            controller:
                _cancellationHoursController,
            keyboardType:
                TextInputType.number,
            decoration: _inputDecoration(
              label: 'Cancellation notice',
              hint: '24',
              icon: Icons.schedule_rounded,
              suffix: 'hours',
            ),
            validator: (value) {
              final number = int.tryParse(
                value?.trim() ?? '',
              );

              if (number == null) {
                return 'Enter a valid number.';
              }

              if (number < 0) {
                return 'Hours cannot be negative.';
              }

              return null;
            },
          );

          if (constraints.maxWidth >= 700) {
            return Row(
              children: [
                Expanded(
                  child: field,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: _CancellationInfo(),
                ),
              ],
            );
          }

          return Column(
            children: [
              field,
              const SizedBox(height: 14),
              const _CancellationInfo(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaveSection() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed:
              _saving ? null : _loadSettings,
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Reset changes',
          ),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed:
              _saving ? null : _saveSettings,
          icon: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.check_rounded,
                  size: 19,
                ),
          label: Text(
            _saving
                ? 'Saving...'
                : 'Save changes',
          ),
          style: FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 17,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E9EF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF0EFFF),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color:
                        const Color(0xFF6C63FF),
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
                              Color(0xFF30313C),
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF898B98),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Divider(
              height: 1,
              color: Color(0xFFEEEEF2),
            ),

            const SizedBox(height: 24),

            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
      ),
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFAFC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE2E3E9),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE2E3E9),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6C63FF),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD94343),
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD94343),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 430,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E9EF),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _numberText(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    if (value is int) {
      return value.toString();
    }

    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    final text = value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  String _currencyLabel(
    String currency,
  ) {
    switch (currency) {
      case 'EUR':
        return 'EUR — Euro';

      case 'USD':
        return 'USD — US Dollar';

      case 'GBP':
        return 'GBP — British Pound';

      case 'CHF':
        return 'CHF — Swiss Franc';

      default:
        return currency;
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}

class _CancellationInfo
    extends StatelessWidget {
  const _CancellationInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FF),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3E0FF),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Customers should cancel before this period to comply with your cancellation policy.',
              style: TextStyle(
                color: Color(0xFF6D698C),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}