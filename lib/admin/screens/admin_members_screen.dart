import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_auth.dart';
import 'package:geliyor_app/admin/admin_member.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

enum _MemberFilter { all, members, guests, admins, inactive }

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _search = TextEditingController();
  _MemberFilter _filter = _MemberFilter.all;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.users);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  _MemberFilter get _currentFilter {
    final value = _filter;
    for (final item in _MemberFilter.values) {
      if (item == value) return item;
    }
    return _MemberFilter.all;
  }

  List<AdminMember> _sorted(List<AdminMember> members) {
    return [...members]..sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  }

  bool _matchesFilter(AdminMember member) {
    switch (_currentFilter) {
      case _MemberFilter.all:
        return true;
      case _MemberFilter.members:
        return !member.isGuest && !member.isAdminRole;
      case _MemberFilter.guests:
        return member.isGuest;
      case _MemberFilter.admins:
        return member.isAdminRole;
      case _MemberFilter.inactive:
        return !member.active;
    }
  }

  List<AdminMember> _applyFilter(List<AdminMember> members) {
    final query = _search.text.trim().toLowerCase();
    final filtered = <AdminMember>[];
    for (final member in _sorted(members)) {
      if (!_matchesFilter(member)) continue;
      if (query.isNotEmpty) {
        final haystack =
            '${member.displayName} ${member.phoneNumber} ${member.email}'
                .toLowerCase();
        if (!haystack.contains(query)) continue;
      }
      filtered.add(member);
    }
    return filtered;
  }

  Future<void> _saveMember(AdminMember member, {required bool isNew}) async {
    await _col
        .doc(member.id)
        .set(member.toMap(includeCreated: isNew), SetOptions(merge: true));
  }

  Future<void> _deleteMember(AdminMember member) async {
    if (member.id == AdminAuth.instance.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi hesabınızı silemezsiniz.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üyeyi sil'),
        content: Text(
          '${member.displayName.isEmpty ? 'Bu üye' : member.displayName} '
          'silinsin mi? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _col.doc(member.id).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${member.displayName.isEmpty ? 'Üye' : member.displayName} silindi',
        ),
      ),
    );
  }

  Future<void> _editMember(AdminMember? existing) async {
    final saved = await showDialog<AdminMember>(
      context: context,
      builder: (ctx) => _MemberFormDialog(member: existing),
    );
    if (saved == null) return;
    await _saveMember(saved, isNew: existing == null);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = <AdminMember>[];
        for (final doc in snapshot.data!.docs) {
          try {
            all.add(AdminMember.fromDoc(doc));
          } catch (_) {}
        }
        final visible = _applyFilter(all);
        final members = all.where((m) => !m.isGuest && !m.isAdminRole).length;
        final guests = all.where((m) => m.isGuest).length;
        final admins = all.where((m) => m.isAdminRole).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Üyeler',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kayıtlı müşterileri arayın, durumunu değiştirin veya düzenleyin.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildStats(
              total: all.length,
              members: members,
              guests: guests,
              admins: admins,
            ),
            const SizedBox(height: 16),
            _buildSearchRow(),
            const SizedBox(height: 12),
            _buildFilters(visible.length),
            const SizedBox(height: 14),
            if (visible.isEmpty) _emptyState() else _buildList(visible),
          ],
        );
      },
    );
  }

  Widget _buildStats({
    required int total,
    required int members,
    required int guests,
    required int admins,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final width = wide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              width: width,
              value: '$total',
              label: 'Toplam',
              icon: Icons.groups_rounded,
              selected: _currentFilter == _MemberFilter.all,
              onTap: () => setState(() => _filter = _MemberFilter.all),
            ),
            _statCard(
              width: width,
              value: '$members',
              label: 'Üye',
              icon: Icons.person_rounded,
              selected: _currentFilter == _MemberFilter.members,
              onTap: () => setState(() => _filter = _MemberFilter.members),
            ),
            _statCard(
              width: width,
              value: '$guests',
              label: 'Misafir',
              icon: Icons.person_outline_rounded,
              selected: _currentFilter == _MemberFilter.guests,
              onTap: () => setState(() => _filter = _MemberFilter.guests),
            ),
            _statCard(
              width: width,
              value: '$admins',
              label: 'Admin',
              icon: Icons.verified_user_outlined,
              selected: _currentFilter == _MemberFilter.admins,
              onTap: () => setState(() => _filter = _MemberFilter.admins),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required double width,
    required String value,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: selected ? AppColors.selected : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ad, telefon veya e-posta ile ara',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => _editMember(null),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Üye'),
        ),
      ],
    );
  }

  Widget _buildFilters(int visibleCount) {
    Widget chip(String label, _MemberFilter value) {
      final selected = _currentFilter == value;
      return FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.selected,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        backgroundColor: AppColors.surface,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('Tümü', _MemberFilter.all),
        chip('Üyeler', _MemberFilter.members),
        chip('Misafir', _MemberFilter.guests),
        chip('Admin', _MemberFilter.admins),
        chip('Pasif', _MemberFilter.inactive),
        Text(
          '$visibleCount sonuç',
          style: const TextStyle(
            color: AppColors.subText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, size: 42, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Üye bulunamadı',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _search.text.trim().isEmpty
                ? 'Henüz kayıtlı üye yok. Yeni üye ekleyebilirsiniz.'
                : 'Aramaya uygun üye yok. Filtreyi veya aramayı değiştirin.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AdminMember> members) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _MemberTile(
              member: members[i],
              onEdit: () => _editMember(members[i]),
              onToggleActive: () => _saveMember(
                members[i].copyWith(active: !members[i].active),
                isNew: false,
              ),
              onDelete: () => _deleteMember(members[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AdminMember member;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contact = [
      if (member.phoneNumber.isNotEmpty) member.phoneNumber,
      if (member.email.isNotEmpty) member.email,
    ].join('  ·  ');
    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(
          member.roleLabel,
          member.isAdminRole ? AppColors.primary : AppColors.subText,
        ),
        _chip(
          member.active ? 'Aktif' : 'Pasif',
          member.active ? AppColors.success : AppColors.error,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.selected,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName.isEmpty
                            ? 'İsimsiz üye'
                            : member.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          contact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (compact) ...[const SizedBox(height: 8), chips],
                    ],
                  ),
                ),
                if (!compact) ...[
                  chips,
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 88,
                    child: Text(
                      member.createdAtShort,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                PopupMenuButton<String>(
                  tooltip: 'İşlemler',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'toggle':
                        onToggleActive();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(member.active ? 'Pasife al' : 'Aktife al'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.subText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({this.member});

  final AdminMember? member;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late String _role;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _name = TextEditingController(text: member?.displayName ?? '');
    _email = TextEditingController(text: member?.email ?? '');
    _phone = TextEditingController(text: member?.phoneNumber ?? '');
    _role = member?.isAdminRole == true ? 'admin' : 'customer';
    _active = member?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.member == null ? 'Yeni Üye' : 'Üyeyi Düzenle'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Adı Soyadı'),
              ),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Üye')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ad soyad gerekli.')),
              );
              return;
            }
            final existing = widget.member;
            Navigator.pop(
              context,
              AdminMember(
                id:
                    existing?.id ??
                    FirebaseFirestore.instance.collection('users').doc().id,
                displayName: name,
                phoneNumber: _phone.text.trim(),
                email: _email.text.trim(),
                membershipType: existing?.membershipType ?? 'bireysel',
                memberGroup: existing?.memberGroup ?? '',
                specialDiscount: existing?.specialDiscount ?? 0,
                riskyCustomer: existing?.riskyCustomer ?? false,
                active: _active,
                isGuest: existing?.isGuest ?? false,
                userRole: _role,
                createdAt: existing?.createdAt,
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
