import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class SakinlerScreen extends StatefulWidget {
  const SakinlerScreen({super.key});
  @override State<SakinlerScreen> createState() => _SakinlerScreenState();
}

class _SakinlerScreenState extends State<SakinlerScreen> {
  List<Sakin> sakinler = [];
  List<Daire> daireler = [];
  bool loading = true;
  String search = '';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await ApiService.getSakinler();
      final d = await ApiService.getDaireler();
      setState(() { sakinler = s; daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  String _daireLabel(int id) {
    final d = daireler.where((x) => x.id == id).firstOrNull;
    return d?.label ?? 'Daire $id';
  }

  List<Sakin> get _filtered => sakinler.where((s) {
    final q = search.toLowerCase();
    return s.adSoyad.toLowerCase().contains(q) || s.telefon.contains(q);
  }).toList();

  void _showForm({Sakin? item}) {
    if (daireler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce daire ekleyin')));
      return;
    }
    final adCtrl = TextEditingController(text: item?.ad ?? '');
    final soyadCtrl = TextEditingController(text: item?.soyad ?? '');
    final telCtrl = TextEditingController(text: item?.telefon ?? '');
    final mailCtrl = TextEditingController(text: item?.email ?? '');
    final girisTarihiCtrl = TextEditingController(text: item?.girisTarihi ?? '');
    final daireId = ValueNotifier<int>(item?.daireId ?? daireler.first.id);
    final tip = ValueNotifier(item?.tip ?? 'kiracı');
    final aktif = ValueNotifier(item?.aktif ?? true);

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Sakin' : 'Sakini Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: TextField(controller: adCtrl, decoration: dec('Ad'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: soyadCtrl, decoration: dec('Soyad'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: telCtrl, decoration: dec('Telefon'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: mailCtrl, decoration: dec('E-posta'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: daireId, builder: (_, v, __) =>
              DropdownButtonFormField<int>(
                value: v,
                decoration: dec('Daire'),
                items: daireler.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => daireId.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: tip, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v,
                decoration: dec('Tip'),
                items: const [
                  DropdownMenuItem(value: 'ev_sahibi', child: Text('Ev Sahibi')),
                  DropdownMenuItem(value: 'kiracı', child: Text('Kiracı')),
                ],
                onChanged: (v) => tip.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: girisTarihiCtrl, decoration: dec('Giriş Tarihi (YYYY-MM-DD)')),
            const SizedBox(height: 8),
            ValueListenableBuilder(valueListenable: aktif, builder: (_, v, __) =>
              CheckboxListTile(
                title: const Text('Aktif Sakin', style: TextStyle(fontSize: 14)),
                value: v,
                onChanged: (x) => aktif.value = x ?? true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'ad': adCtrl.text,
                'soyad': soyadCtrl.text,
                'telefon': telCtrl.text,
                'email': mailCtrl.text,
                'daire_id': daireId.value,
                'tip': tip.value,
                'giris_tarihi': girisTarihiCtrl.text.isEmpty ? null : girisTarihiCtrl.text,
                'aktif': aktif.value,
              };
              if (item != null) await ApiService.updateSakin(item.id, data);
              else await ApiService.createSakin(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Sakin s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sakini Sil'),
      content: Text('${s.adSoyad} silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteSakin(s.id);
            if (mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final aktifSakin = sakinler.where((s) => s.aktif).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Sakin'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              _chip('${sakinler.length} Toplam', Colors.blue),
              const SizedBox(width: 8),
              _chip('$aktifSakin Aktif', Colors.green),
              const SizedBox(width: 8),
              _chip('${sakinler.where((s) => s.tip == 'ev_sahibi').length} Sahibi', Colors.purple),
            ]),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'İsim veya telefon ara...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Sakin bulunamadı', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: s.tip == 'ev_sahibi' ? Colors.purple.shade100 : Colors.blue.shade100,
                                child: Text(
                                  s.ad.isNotEmpty ? s.ad[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: s.tip == 'ev_sahibi' ? Colors.purple.shade700 : Colors.blue.shade700),
                                ),
                              ),
                              title: Text(s.adSoyad,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_daireLabel(s.daireId),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  if (s.telefon.isNotEmpty)
                                    Text(s.telefon,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                              isThreeLine: s.telefon.isNotEmpty,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  StatusBadge(
                                    text: s.tip == 'ev_sahibi' ? 'Sahibi' : 'Kiracı',
                                    color: s.tip == 'ev_sahibi' ? Colors.purple.shade100 : Colors.blue.shade100,
                                    textColor: s.tip == 'ev_sahibi' ? Colors.purple.shade700 : Colors.blue.shade700,
                                  ),
                                  if (!s.aktif)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: StatusBadge.forDurum('iptal'),
                                    ),
                                ]),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(item: s);
                                    if (v == 'delete') _confirmDelete(s);
                                  },
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.w500)),
  );
}
