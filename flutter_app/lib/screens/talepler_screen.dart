import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class TaleplerScreen extends StatefulWidget {
  const TaleplerScreen({super.key});
  @override State<TaleplerScreen> createState() => _TaleplerScreenState();
}

class _TaleplerScreenState extends State<TaleplerScreen> {
  List<Talep> talepler = [];
  List<Daire> daireler = [];
  bool loading = true;
  String filterDurum = '';

  final kategoriler = ['tadilat', 'temizlik', 'teknik', 'guvenlik', 'diger'];
  final kategoriLabels = {'tadilat': 'Tadilat', 'temizlik': 'Temizlik', 'teknik': 'Teknik', 'guvenlik': 'Güvenlik', 'diger': 'Diğer'};
  final oncelikler = ['dusuk', 'orta', 'yuksek', 'acil'];
  final durumlar = ['beklemede', 'isleniyor', 'tamamlandi', 'iptal'];
  final durumLabels = {'beklemede': 'Beklemede', 'isleniyor': 'İşleniyor', 'tamamlandi': 'Tamamlandı', 'iptal': 'İptal'};

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final t = await ApiService.getTalepler(durum: filterDurum.isEmpty ? null : filterDurum);
      final d = await ApiService.getDaireler();
      setState(() { talepler = t; daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  String _daireLabel(int id) => daireler.where((x) => x.id == id).firstOrNull?.label ?? 'Daire $id';

  void _showForm({Talep? item}) {
    if (daireler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce daire ekleyin')));
      return;
    }
    final daireId = ValueNotifier<int>(item?.daireId ?? daireler.first.id);
    final baslikCtrl = TextEditingController(text: item?.baslik ?? '');
    final aciklamaCtrl = TextEditingController(text: item?.aciklama ?? '');
    final kategori = ValueNotifier(item?.kategori ?? 'teknik');
    final oncelik = ValueNotifier(item?.oncelik ?? 'orta');
    final durum = ValueNotifier(item?.durum ?? 'beklemede');

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Talep' : 'Talebi Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ValueListenableBuilder(valueListenable: daireId, builder: (_, v, __) =>
              DropdownButtonFormField<int>(
                value: v,
                decoration: dec('Daire'),
                items: daireler.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => daireId.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: baslikCtrl, decoration: dec('Başlık')),
            const SizedBox(height: 12),
            TextField(controller: aciklamaCtrl, decoration: dec('Açıklama'), maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ValueListenableBuilder(valueListenable: kategori, builder: (_, v, __) =>
                DropdownButtonFormField<String>(
                  value: v, decoration: dec('Kategori'),
                  items: kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(kategoriLabels[k] ?? k))).toList(),
                  onChanged: (v) => kategori.value = v!,
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: ValueListenableBuilder(valueListenable: oncelik, builder: (_, v, __) =>
                DropdownButtonFormField<String>(
                  value: v, decoration: dec('Öncelik'),
                  items: oncelikler.map((o) => DropdownMenuItem(value: o, child: StatusBadge.forOncelik(o))).toList(),
                  onChanged: (v) => oncelik.value = v!,
                ),
              )),
            ]),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: durum, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v, decoration: dec('Durum'),
                items: durumlar.map((d) => DropdownMenuItem(value: d, child: Text(durumLabels[d] ?? d))).toList(),
                onChanged: (v) => durum.value = v!,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'daire_id': daireId.value,
                'baslik': baslikCtrl.text,
                'aciklama': aciklamaCtrl.text,
                'kategori': kategori.value,
                'oncelik': oncelik.value,
                'durum': durum.value,
              };
              if (item != null) await ApiService.updateTalep(item.id, data);
              else await ApiService.createTalep(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _quickStatus(Talep t, String newDurum) async {
    await ApiService.updateTalep(t.id, {'durum': newDurum});
    _load();
  }

  void _confirmDelete(Talep t) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Talebi Sil'),
      content: Text('"${t.baslik}" silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteTalep(t.id);
            if (mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Color _oncelikColor(String o) => switch(o) {
    'acil' => Colors.red, 'yuksek' => Colors.orange,
    'orta' => Colors.yellow.shade700, _ => Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    final bekleyen = talepler.where((t) => t.durum == 'beklemede' || t.durum == 'isleniyor').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Talep'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('Tümü', ''),
                const SizedBox(width: 8),
                _filterChip('Beklemede', 'beklemede'),
                const SizedBox(width: 8),
                _filterChip('İşleniyor', 'isleniyor'),
                const SizedBox(width: 8),
                _filterChip('Tamamlandı', 'tamamlandi'),
                const SizedBox(width: 8),
                _filterChip('İptal', 'iptal'),
              ]),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _chip('${talepler.length} Talep', Colors.blue),
              const SizedBox(width: 8),
              if (bekleyen > 0) _chip('$bekleyen Aktif', Colors.red),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : talepler.isEmpty
                    ? const Center(child: Text('Talep bulunamadı', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: talepler.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = talepler[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _oncelikColor(t.oncelik).withOpacity(0.4),
                                width: t.oncelik == 'acil' ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    StatusBadge.forOncelik(t.oncelik),
                                    const SizedBox(width: 8),
                                    StatusBadge.forDurum(t.durum),
                                    const Spacer(),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                                      itemBuilder: (_) => [
                                        if (t.durum == 'beklemede')
                                          const PopupMenuItem(value: 'isleniyor', child: Text('İşleniyor İşaretle')),
                                        if (t.durum != 'tamamlandi')
                                          const PopupMenuItem(value: 'tamamlandi', child: Text('Tamamlandı İşaretle')),
                                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                      ],
                                      onSelected: (v) {
                                        if (v == 'edit') _showForm(item: t);
                                        else if (v == 'delete') _confirmDelete(t);
                                        else _quickStatus(t, v as String);
                                      },
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(t.baslik,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(_daireLabel(t.daireId),
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                  if (t.aciklama.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(t.aciklama,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(Icons.category_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(kategoriLabels[t.kategori] ?? t.kategori,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.schedule, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(t.createdAt.length > 10 ? t.createdAt.substring(0, 10) : t.createdAt,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ]),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = filterDurum == value;
    return GestureDetector(
      onTap: () { setState(() => filterDurum = value); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: selected ? Colors.white : Colors.grey.shade700,
        )),
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.w500)),
  );
}
