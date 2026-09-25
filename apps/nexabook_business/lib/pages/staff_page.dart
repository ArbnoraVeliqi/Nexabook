import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;

  List<dynamic> _staff = [];

  String _search = '';
  String _statusFilter = 'All';
  String _roleFilter = 'All roles';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadStaff();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await context.read<ApiClient>().get('/users');

      if (!mounted) {
        return;
      }

      setState(() {
        _staff = result is List ? List<dynamic>.from(result) : [];
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
        'Could not load team members.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredStaff {
    final query = _search.trim().toLowerCase();

    return _staff.where((member) {
      final firstName = _value(member, 'firstName').toLowerCase();
      final lastName = _value(member, 'lastName').toLowerCase();
      final email = _value(member, 'email').toLowerCase();
      final phone = _value(member, 'phone').toLowerCase();
      final username = _value(member, 'username').toLowerCase();
      final role = _roleName(member).toLowerCase();

      final matchesSearch = query.isEmpty ||
          firstName.contains(query) ||
          lastName.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          username.contains(query) ||
          role.contains(query) ||
          '$firstName $lastName'.contains(query);

      final active = _isActive(member);

      final matchesStatus = switch (_statusFilter) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      final matchesRole = _roleFilter == 'All roles' ||
          _roleName(member).toLowerCase() == _roleFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesRole;
    }).toList();
  }

  List<String> get _roles {
    final roles = _staff
        .map(_roleName)
        .where((role) => role.trim().isNotEmpty && role != '—')
        .toSet()
        .toList();

    roles.sort();

    return roles;
  }

  int get _activeCount {
    return _staff.where(_isActive).length;
  }

  int get _inactiveCount {
    return _staff.length - _activeCount;
  }

  bool _isActive(dynamic member) {
    if (member['isActive'] != null) {
      return member['isActive'] == true;
    }

    final status = _value(member, 'status').toLowerCase();

    if (status == 'inactive' ||
        status == 'disabled' ||
        status == 'blocked' ||
        status == '0') {
      return false;
    }

    return true;
  }

  String _roleName(dynamic member) {
    final role = member['role'];

    if (role is Map) {
      final name = role['name'] ??
          role['roleName'] ??
          role['title'];

      if (name != null) {
        return name.toString();
      }
    }

    if (role != null && role.toString().trim().isNotEmpty) {
      return role.toString();
    }

    final roleName = member['roleName'];

    if (roleName != null &&
        roleName.toString().trim().isNotEmpty) {
      return roleName.toString();
    }

    return '—';
  }

  String _value(dynamic object, String key) {
    final value = object[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final staff = _filteredStaff;

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Team',
            'Manage staff members, roles and availability',
            action: FilledButton.icon(
              onPressed: _showAddStaffDialog,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 19,
              ),
              label: const Text('Add staff'),
            ),
          ),

          const SizedBox(height: 26),

          _buildSummary(),

          const SizedBox(height: 22),

          _buildToolbar(),

          const SizedBox(height: 16),

          if (_loading)
            _buildLoading()
          else if (staff.isEmpty)
            _buildEmptyState()
          else
            _buildStaffTable(staff),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double cardWidth;

        if (width >= 1000) {
          cardWidth = (width - 32) / 3;
        } else if (width >= 650) {
          cardWidth = (width - 16) / 2;
        } else {
          cardWidth = width;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard(
              width: cardWidth,
              title: 'Team members',
              value: '${_staff.length}',
              icon: Icons.groups_2_outlined,
              iconBackground: const Color(0xFFF0EFFF),
              iconColor: const Color(0xFF6C63FF),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Active staff',
              value: '$_activeCount',
              icon: Icons.check_circle_outline_rounded,
              iconBackground: const Color(0xFFEAF8F0),
              iconColor: const Color(0xFF279466),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Roles',
              value: '${_roles.length}',
              icon: Icons.badge_outlined,
              iconBackground: const Color(0xFFEAF6FF),
              iconColor: const Color(0xFF4389C7),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE9EAF0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF77798A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;

          if (compact) {
            return Column(
              children: [
                _buildSearch(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleFilter(),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadStaff,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildStatusFilters(),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildSearch(),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 180,
                child: _buildRoleFilter(),
              ),
              const SizedBox(width: 14),
              _buildStatusFilters(),
              const SizedBox(width: 5),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadStaff,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search staff, email, phone or role...',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    final roles = _roles;

    final values = [
      'All roles',
      ...roles,
    ];

    if (!values.contains(_roleFilter)) {
      _roleFilter = 'All roles';
    }

    return DropdownButtonFormField<String>(
      value: _roleFilter,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.badge_outlined,
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      items: values.map((role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(
            role,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _roleFilter = value;
        });
      },
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusFilterButton('All'),
        const SizedBox(width: 7),
        _statusFilterButton('Active'),
        const SizedBox(width: 7),
        _statusFilterButton('Inactive'),
      ],
    );
  }

  Widget _statusFilterButton(String value) {
    final selected = _statusFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF555766),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtered = _search.isNotEmpty ||
        _statusFilter != 'All' ||
        _roleFilter != 'All roles';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              size: 31,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered
                ? 'No team members found'
                : 'Your team is empty',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            filtered
                ? 'Try changing your search or filters.'
                : 'Add your first staff member to get started.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77798A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTable(List<dynamic> staff) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),

          for (int index = 0; index < staff.length; index++) ...[
            _buildStaffRow(staff[index]),
            if (index != staff.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
          ],

          _buildTableFooter(staff.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      color: const Color(0xFFF8F9FC),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'TEAM MEMBER',
              style: _staffHeaderStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CONTACT',
              style: _staffHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ROLE',
              style: _staffHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: _staffHeaderStyle,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStaffRow(dynamic member) {
    final firstName = _value(member, 'firstName');
    final lastName = _value(member, 'lastName');

    final fullName = '$firstName $lastName'.trim();

    final email = _value(member, 'email');
    final phone = _value(member, 'phone');
    final username = _value(member, 'username');

    final role = _roleName(member);
    final active = _isActive(member);

    return InkWell(
      onTap: () {
        _showStaffDetails(member);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _buildAvatar(fullName),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty
                              ? 'Unnamed staff member'
                              : fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username.isNotEmpty
                              ? '@$username'
                              : _staffReference(member),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9092A1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _contactLine(
                    Icons.mail_outline_rounded,
                    email,
                  ),
                  const SizedBox(height: 6),
                  _contactLine(
                    Icons.phone_outlined,
                    phone,
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _roleBadge(role),
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(active),
              ),
            ),

            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    _showStaffDetails(member);
                  }

                  if (value == 'edit') {
                    _showEditNotConnected();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text('View details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text('Edit member'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String fullName) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _avatarColor(fullName),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(fullName),
        style: const TextStyle(
          color: Color(0xFF5F57D9),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _contactLine(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF9294A3),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6170),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 135,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF6259D7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFEAF8F0)
            : const Color(0xFFF1F1F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF279466)
                  : const Color(0xFF858795),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active
                  ? const Color(0xFF237C57)
                  : const Color(0xFF676976),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
InputDecoration _staffInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(
      icon,
      size: 19,
    ),
    filled: true,
    fillColor: const Color(0xFFF8F9FC),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFFE6E7EC),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFFE6E7EC),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFF6C63FF),
        width: 1.4,
      ),
    ),
  );
}
  Widget _buildTableFooter(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      color: const Color(0xFFFBFBFD),
      child: Text(
        '$count ${count == 1 ? 'team member' : 'team members'} shown',
        style: const TextStyle(
          color: Color(0xFF77798A),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showStaffDetails(dynamic member) {
    final firstName = _value(member, 'firstName');
    final lastName = _value(member, 'lastName');

    final fullName = '$firstName $lastName'.trim();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 570,
            ),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(fullName),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty
                                  ? 'Team member'
                                  : fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _roleName(member),
                              style: const TextStyle(
                                color: Color(0xFF77798A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 18),

                  _detailRow(
                    Icons.badge_outlined,
                    'Role',
                    _roleName(member),
                  ),
                  _detailRow(
                    Icons.alternate_email_rounded,
                    'Username',
                    _value(member, 'username'),
                  ),
                  _detailRow(
                    Icons.mail_outline_rounded,
                    'Email',
                    _value(member, 'email'),
                  ),
                  _detailRow(
                    Icons.phone_outlined,
                    'Phone',
                    _value(member, 'phone'),
                  ),
                  _detailRow(
                    Icons.circle_outlined,
                    'Status',
                    _isActive(member) ? 'Active' : 'Inactive',
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showEditNotConnected();
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        label: const Text('Edit member'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF77798A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A8C9A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _showAddStaffDialog() async {
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'Staff';
  bool isActive = true;
  bool saving = false;
  bool obscurePassword = true;

  final created = await showDialog<bool>(
    context: context,
    barrierDismissible: !saving,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> saveStaff() async {
            if (saving) {
              return;
            }

            if (!formKey.currentState!.validate()) {
              return;
            }

            setDialogState(() {
              saving = true;
            });

            try {
              await context.read<ApiClient>().post(
                '/users',
                data: {
                  'firstName': firstNameController.text.trim(),
                  'lastName': lastNameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'username': usernameController.text.trim(),
                  'password': passwordController.text,
                  'role': selectedRole,
                  'isActive': isActive,
                },
              );

              if (!dialogContext.mounted) {
                return;
              }

              Navigator.pop(dialogContext, true);
            } catch (e) {
              setDialogState(() {
                saving = false;
              });

              if (!dialogContext.mounted) {
                return;
              }

              ScaffoldMessenger.of(dialogContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFFD94343),
                    content: Text(
                      'Could not add team member.',
                    ),
                  ),
                );
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 620,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EFFF),
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add team member',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create a new staff account.',
                                  style: TextStyle(
                                    color: Color(0xFF77798A),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: saving
                                ? null
                                : () {
                                    Navigator.pop(
                                      dialogContext,
                                      false,
                                    );
                                  },
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              decoration:
                                  _staffInputDecoration(
                                label: 'First name',
                                icon:
                                    Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'First name is required.';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              decoration:
                                  _staffInputDecoration(
                                label: 'Last name',
                                icon:
                                    Icons.person_outline_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: _staffInputDecoration(
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty) {
                            return null;
                          }

                          if (!email.contains('@') ||
                              !email.contains('.')) {
                            return 'Enter a valid email.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _staffInputDecoration(
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: usernameController,
                        decoration: _staffInputDecoration(
                          label: 'Username',
                          icon:
                              Icons.alternate_email_rounded,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Username is required.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: _staffInputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Password is required.';
                          }

                          if (value.length < 6) {
                            return 'Use at least 6 characters.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: _staffInputDecoration(
                          label: 'Role',
                          icon: Icons.badge_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Staff',
                            child: Text('Staff'),
                          ),
                          DropdownMenuItem(
                            value: 'Manager',
                            child: Text('Manager'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setDialogState(() {
                                  selectedRole = value;
                                });
                              },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isActive,
                          title: const Text(
                            'Active account',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'The team member can access the system.',
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isActive = value;
                                  });
                                },
                        ),
                      ),

                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: saving
                                ? null
                                : () {
                                    Navigator.pop(
                                      dialogContext,
                                      false,
                                    );
                                  },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed:
                                saving ? null : saveStaff,
                            icon: saving
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
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              saving
                                  ? 'Adding...'
                                  : 'Add staff',
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
        },
      );
    },
  );

  firstNameController.dispose();
  lastNameController.dispose();
  emailController.dispose();
  phoneController.dispose();
  usernameController.dispose();
  passwordController.dispose();

  if (created == true && mounted) {
    _showMessage(
      'Team member added successfully.',
    );

    await _loadStaff();
  }
}

  void _showEditNotConnected() {
    _showMessage(
      'Staff editing will be connected to the user API.',
    );
  }

  String _staffReference(dynamic member) {
    final id = member['id'] ?? member['userId'];

    if (id == null) {
      return 'Team member';
    }

    return 'Staff #${id.toString().padLeft(4, '0')}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'T';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFFF0EFFF),
      const Color(0xFFEAF6FF),
      const Color(0xFFEAF8F0),
      const Color(0xFFFFF4E8),
      const Color(0xFFFFEDF3),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}

const TextStyle _staffHeaderStyle = TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);