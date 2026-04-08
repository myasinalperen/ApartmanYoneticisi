import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class SikayetlerScreen extends StatefulWidget {
  const SikayetlerScreen({super.key});
  @override State<SikayetlerScreen> createState() => _SikayetlerScreenState();
}

class _SikayetlerScreenState extends State<SikayetlerScreen> {
  List<Sikayet> sikayetler = [];
  List<Daire> daireler = [];
  bool loading = true;
  String filterDurum = '';

  final kategoriler = ['gurultu', 'temizlik', 'park', 'evcil_hayvan', 'diger'];
  final kategoriLabels = {'gurultu': 'Gürültü', 'temizlik': 'Temizlik', 'park': 'Park', 'evcil_hayvan': 'Evcil Hayvan', 'diger': 'Diğer'};
  final durumlar = ['acik', 'inceleniyor', 'cozuldu', 'kapandi'];
  final durumLabels = {'acik': 'Açık', 'inceleniyor': 'İnceleniyor', 'cozuldu': 'Çözüldü', 'kapandi': 'Kapandı'};

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final s = await ApiService.getSikayetler(durum: filterDurum.isEmpty ? null : filterDurum);
      final d = await ApiService.getDaireler();
      setState(() { sikayetler = s; daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  String _daireLabel(int id) => daireler.where((x) => x.id == id).firstOrNull?.label ?? 'Daire $id';

  void _showForm({Sikayet? item}) {
    if (daireler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce daire ekleyin')));
      return;
    }
    final edendaire = ValueNotifier<int>(item?.sikayetEdenDaireId ?? daireler.first.id);
    final edilendaire = ValueNotifier<int?>(item?.sikayetEdilenDaireId);
    final baslikCtrl = TextEditingController(text: item?.baslik ?? '');
    final aciklamaCtrl = TextEditingController(text: item?.aciklama ?? '');
    final kategori = ValueNotifier(item?.kategori ?? 'diger');
    final durum = ValueNotifier(item?.durum ?? 'acik');

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Şikayet' : 'Şikayeti Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ValueListenableBuilder(valueListenable: edendaire, builder: (_, v, __) =>
              DropdownButtonFormField<int>(
                value: v, decoration: dec('Şikayet Eden Daire'),
                items: daireler.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => edendaire.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: edilendaire, builder: (_, v, __) =>
              DropdownButtonFormField<int?>(
                value: v, decoration: dec('Şikayet Edilen Daire (Opsiyonel)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Genel Şikayet')),
                  ...daireler.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => edilendaire.value = v,
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
              Expanded(child: ValueListenableBuilder(valueListenable: durum, builder: (_, v, __) =>
                DropdownButtonFormField<String>(
                  value: v, decoration: dec('Durum'),
                  items: durumlar.map((d) => DropdownMenuItem(value: d, child: Text(durumLabels[d] ?? d))).toList(),
                  onChanged: (v) => durum.value = v!,
                ),
              )),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'sikayet_eden_daire_id': edendaire.value,
                'sikayet_edilen_daire_id': edilendaire.value,
                'baslik': baslikCtrl.text,
                'aciklama': aciklamaCtrl.text,
                'kategori': kategori.value,
                'durum': durum.value,
              };
              if (item != null) await ApiService.updateSikayet(item.id, data);
              else await ApiService.createSikayet(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _quickUpdate(Sikayet s, String newDurum) async {
    await ApiService.updateSikayet(s.id, {'durum': newDurum});
    _load();
  }

  void _confirmDelete(Sikayet s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Şikayeti Sil'),
      content: Text('"${s.baslik}" silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteSikayet(s.id);
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
    final acik = sikayetler.where((s) => s.durum == 'acik' || s.durum == 'inceleniyor').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Şikayet'),
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
                _filterChip('Açık', 'acik'),
                const SizedBox(width: 8),
                _filterChip('İnceleniyor', 'inceleniyor'),
                const SizedBox(width: 8),
                _filterChip('Çözüldü', 'cozuldu'),
                const SizedBox(width: 8),
                _filterChip('Kapandı', 'kapandi'),
              ]),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _chip('${sikayetler.length} Şikayet', Colors.blue),
              const SizedBox(width: 8),
              if (acik > 0) _chip('$acik Açık', Colors.red),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sikayetler.isEmpty
                    ? const Center(child: Text('Şikayet bulunamadı', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sikayetler.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = sikayetler[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(kategoriLabels[s.kategori] ?? s.kategori,
                                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge.forDurum(s.durum),
                                    const Spacer(),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                                      itemBuilder: (_) => [
                                        if (s.durum == 'acik') const PopupMenuItem(value: 'inceleniyor', child: Text('İnceleniyor İşaretle')),
                                        if (s.durum != 'cozuldu') const PopupMenuItem(value: 'cozuldu', child: Text('Çözüldü İşaretle')),
                                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                      ],
                                      onSelected: (v) {
                                        if (v == 'edit') _showForm(item: s);
                                        else if (v == 'delete') _confirmDelete(s);
                                        else _quickUpdate(s, v as String);
                                      },
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(s.baslik, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(_daireLabel(s.sikayetEdenDaireId),
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                    if (s.sikayetEdilenDaireId != null) ...[
                                      Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade400),
                                      Text(_daireLabel(s.sikayetEdilenDaireId!),
                                          style: TextStyle(fontSize: 12, color: Colors.red.shade500)),
                                    ],
                                  ]),
                                  if (s.aciklama.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(s.aciklama,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(s.createdAt.length > 10 ? s.createdAt.substring(0, 10) : s.createdAt,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
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
          color: selected ? Colors.red.shade600 : Colors.grey.shade100,
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
