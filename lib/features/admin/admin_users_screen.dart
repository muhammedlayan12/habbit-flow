import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _Filter { all, active, inactive, admins }

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _users = await context.read<AuthProvider>().fetchAllUsers();
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not load users', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  List<AppUser> get _filtered {
    return _users.where((u) {
      final matchesQuery = _query.isEmpty ||
          u.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          u.email.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.active => u.isActive,
        _Filter.inactive => !u.isActive,
        _Filter.admins => u.isAdmin,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _loading
          ? const LoadingView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _Filter.values.map((f) {
                        final labels = {
                          _Filter.all: 'All',
                          _Filter.active: 'Active',
                          _Filter.inactive: 'Inactive',
                          _Filter.admins: 'Admins',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(labels[f]!),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const EmptyState(icon: Icons.people_outline, title: 'No users found', message: 'Try a different search or filter.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _UserTile(user: _filtered[i], onChanged: _load),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onChanged;
  const _UserTile({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isSelf = auth.currentUser?.id == user.id;

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.14),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(user.fullName.isEmpty ? '(no name)' : user.fullName, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Admin', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!isSelf)
            Switch(
              value: user.isActive,
              onChanged: (v) async {
                await auth.setUserActive(user.id, v);
                onChanged();
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('You', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
            ),
        ],
      ),
    );
  }
}
