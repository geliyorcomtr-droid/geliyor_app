import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/adoption_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminAdoptionScreen extends StatefulWidget {
  const AdminAdoptionScreen({super.key, this.initialStatus = 'pending'});

  final String initialStatus;

  @override
  State<AdminAdoptionScreen> createState() => _AdminAdoptionScreenState();
}

class _AdminAdoptionScreenState extends State<AdminAdoptionScreen> {
  late String _status = widget.initialStatus;
  String? _selectedId;

  Color _color(String status) => switch (status) {
    AdoptionStatuses.approved => AppColors.success,
    AdoptionStatuses.rejected => AppColors.error,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdoptionListing>>(
      stream: AdoptionRepository.instance.watchAll(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AdoptionListing>[];
        final list = _status.isEmpty
            ? all
            : all.where((item) => item.status == _status).toList();
        AdoptionListing? selected;
        for (final item in list) {
          if (item.id == _selectedId) {
            selected = item;
            break;
          }
        }
        selected ??= list.isEmpty ? null : list.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPageHeader(
                title: 'Sahiplendirme ilanları',
                subtitle:
                    'Müşteri ilanı onaya düşer. Onayladıktan sonra uygulama sayfasında yayınlanır.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  _chip('', 'Tümü'),
                  _chip(AdoptionStatuses.pending, 'Bekleyen'),
                  _chip(AdoptionStatuses.approved, 'Yayında'),
                  _chip(AdoptionStatuses.rejected, 'Reddedilen'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: AdminPanel(
                        padding: const EdgeInsets.all(8),
                        child: list.isEmpty
                            ? const Center(child: Text('İlan yok'))
                            : ListView(
                                children: [
                                  for (final item in list)
                                    ListTile(
                                      selected: selected?.id == item.id,
                                      selectedTileColor: AppColors.selected,
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: item.coverImage.isEmpty
                                              ? const ColoredBox(
                                                  color: AppColors.selected,
                                                )
                                              : buildProductImage(
                                                  item.coverImage,
                                                  fit: BoxFit.cover,
                                                  width: 44,
                                                  height: 44,
                                                ),
                                        ),
                                      ),
                                      title: Text(item.name),
                                      subtitle: Text(
                                        '${item.categoryLabel} · ${AdoptionStatuses.label(item.status)}',
                                      ),
                                      onTap: () =>
                                          setState(() => _selectedId = item.id),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: selected == null
                          ? const AdminPanel(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('Onay için bir ilan seç'),
                              ),
                            )
                          : _detail(selected),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String value, String label) {
    final selected = _status == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _status = value;
        _selectedId = null;
      }),
    );
  }

  Widget _detail(AdoptionListing item) {
    return AdminPanel(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          if (item.coverImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: buildProductImage(
                  item.coverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('${item.categoryLabel} · ${item.speciesLine}'),
          Text('${item.gender} · ${item.age} · ${item.weight} · ${item.city}'),
          const SizedBox(height: 8),
          Text(item.description),
          const SizedBox(height: 8),
          Text('Telefon: ${item.phone}'),
          Text('Üye: ${item.contactName}'),
          const SizedBox(height: 8),
          AdminStatusChip(
            label: AdoptionStatuses.label(item.status),
            color: _color(item.status),
          ),
          if (item.rejectReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Ret nedeni: ${item.rejectReason}'),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => AdoptionRepository.instance.setStatus(
                  id: item.id,
                  status: AdoptionStatuses.approved,
                ),
                child: const Text('Onayla ve yayınla'),
              ),
              OutlinedButton(
                onPressed: () => _reject(item),
                child: const Text('Reddet'),
              ),
              OutlinedButton(
                onPressed: () => _delete(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reject(AdoptionListing item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı reddet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Neden (isteğe bağlı)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await AdoptionRepository.instance.setStatus(
      id: item.id,
      status: AdoptionStatuses.rejected,
      rejectReason: reason,
    );
  }

  Future<void> _delete(AdoptionListing item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı sil'),
        content: Text(
          item.name.trim().isEmpty
              ? 'Bu ilan silinsin mi?'
              : '“${item.name}” ilanı silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AdoptionRepository.instance.delete(item);
    if (!mounted) return;
    setState(() => _selectedId = null);
  }
}
