import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class DairelerScreen extends StatefulWidget {
  const DairelerScreen({super.key});
  @override State<DairelerScreen> createState() => _DairelerScreenState();
}

class _DairelerScreenState extends State<DairelerScreen> {
  List<Daire> daireler = [];
  bool loading = true;
  String search = '';
  String filterDurum = '';

  final _blok = ['A', 'B', 'C', 'D'];
  final _tipler = ['1+1', '2+1', '3+1', '4+1', 'Dubleks', 'Stüdyo'];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.getDaireler();
      setState(() { daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  List<Daire> get _filtered => daireler.where((d) {
    final q = search.toLowerCase();
    return ('${d.blok}${d.daireNo} ${d.tip}'.toLowerCase().contains(q)) &&
        (filterDurum.isEmpty || d.durum == filterDurum);
  }).toList();

  void _showForm({Daire? item}) {
    final blokCtrl = ValueNotifier(item?.blok ?? 'A');
    final katCtrl = TextEditingController(text: '${item?.kat ?? 1}');
    final noCtrl = TextEditingController(text: item?.daireNo ?? '');
    final tipCtrl = ValueNotifier(item?.tip ?? '2+1');
    final m2Ctrl = TextEditingController(text: '${item?.metrekare ?? 90}');
    final durumCtrl = ValueNotifier(item?.durum ?? 'dolu');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Daire' : 'Daireyi Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Blok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ValueListenableBuilder(valueListenable: blokCtrl, builder: (_, v, __) =>
                  DropdownButtonFormField<String>(
                    value: v,
                    items: _blok.map((b) => DropdownMenuItem(value: b, child: Text('Blok $b'))).toList(),
                    onChanged: (v) => blokCtrl.value = v!,
                    decoration: _inputDec(),
                  ),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Kat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(controller: katCtrl, keyboardType: TextInputType.number, decoration: _inputDec()),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Daire No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(controller: noCtrl, decoration: _inputDec()),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ValueListenableBuilder(valueListenable: tipCtrl, builder: (_, v, __) =>
                  DropdownButtonFormField<String>(
                    value: v,
                    items: _tipler.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => tipCtrl.value = v!,
                    decoration: _inputDec(),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Metrekare (m²)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(controller: m2Ctrl, keyboardType: TextInputType.number, decoration: _inputDec()),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Durum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ValueListenableBuilder(valueListenable: durumCtrl, builder: (_, v, __) =>
                  DropdownButtonFormField<String>(
                    value: v,
                    items: const [
                      DropdownMenuItem(value: 'dolu', child: Text('Dolu')),
                      DropdownMenuItem(value: 'bos', child: Text('Boş')),
                    ],
                    onChanged: (v) => durumCtrl.value = v!,
                    decoration: _inputDec(),
                  ),
                ),
              ])),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'blok': blokCtrl.value,
                'kat': int.tryParse(katCtrl.text) ?? 1,
                'daire_no': noCtrl.text,
                'tip': tipCtrl.value,
                'metrekare': double.tryParse(m2Ctrl.text) ?? 90,
                'durum': durumCtrl.value,
              };
              if (item != null) await ApiService.updateDaire(item.id, data);
              else await ApiService.createDaire(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Daire d) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Daireyi Sil'),
      content: Text('${d.label} silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteDaire(d.id);
            if (mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  InputDecoration _inputDec() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final dolu = daireler.where((d) => d.durum == 'dolu').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Daire'),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                _chip('${daireler.length} Toplam', Colors.blue),
                const SizedBox(width: 8),
                _chip('$dolu Dolu', Colors.green),
                const SizedBox(width: 8),
                _chip('${daireler.length - dolu} Boş', Colors.grey),
              ],
            ),
          ),
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Daire ara...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: filterDurum.isEmpty ? null : filterDurum,
                hint: const Text('Durum'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tümü')),
                  DropdownMenuItem(value: 'dolu', child: Text('Dolu')),
                  DropdownMenuItem(value: 'bos', child: Text('Boş')),
                ],
                onChanged: (v) => setState(() => filterDurum = v ?? ''),
              ),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Daire bulunamadı', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = filtered[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: d.durum == 'dolu' ? Colors.blue.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.door_front_door_rounded,
                                    color: d.durum == 'dolu' ? Colors.blue.shade600 : Colors.grey.shade400),
                              ),
                              title: Text('Blok ${d.blok} · ${d.kat}. Kat · No: ${d.daireNo}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${d.tip} · ${d.metrekare.toStringAsFixed(0)} m²',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                StatusBadge.forDurum(d.durum),
                                const SizedBox(width: 4),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(item: d);
                                    if (v == 'delete') _confirmDelete(d);
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
    decoration: BoxDecoration(
      color: color.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.w500)),
  );
}
