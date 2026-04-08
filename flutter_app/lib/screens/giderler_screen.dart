import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class GiderlerScreen extends StatefulWidget {
  const GiderlerScreen({super.key});
  @override State<GiderlerScreen> createState() => _GiderlerScreenState();
}

class _GiderlerScreenState extends State<GiderlerScreen> {
  List<Gider> giderler = [];
  bool loading = true;

  final kategoriler = ['bakim', 'temizlik', 'elektrik', 'su', 'dogalgaz', 'asansor', 'guvenlik', 'diger'];
  final kategoriLabels = {
    'bakim': 'Bakım', 'temizlik': 'Temizlik', 'elektrik': 'Elektrik',
    'su': 'Su', 'dogalgaz': 'Doğalgaz', 'asansor': 'Asansör', 'guvenlik': 'Güvenlik', 'diger': 'Diğer',
  };
  final kategoriIcons = {
    'bakim': Icons.build_circle, 'temizlik': Icons.cleaning_services, 'elektrik': Icons.bolt,
    'su': Icons.water_drop, 'dogalgaz': Icons.local_fire_department, 'asansor': Icons.elevator,
    'guvenlik': Icons.security, 'diger': Icons.category,
  };
  final trCurrency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final g = await ApiService.getGiderler();
      setState(() { giderler = g; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  void _showForm({Gider? item}) {
    final katCtrl = ValueNotifier(item?.kategori ?? 'diger');
    final aciklamaCtrl = TextEditingController(text: item?.aciklama ?? '');
    final tutarCtrl = TextEditingController(text: item != null ? '${item.tutar}' : '');
    final tarihCtrl = TextEditingController(
        text: item?.tarih ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final belgeCtrl = TextEditingController(text: item?.belgeNo ?? '');

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Gider' : 'Gider Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ValueListenableBuilder(valueListenable: katCtrl, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v,
                decoration: dec('Kategori'),
                items: kategoriler.map((k) => DropdownMenuItem(
                  value: k,
                  child: Row(children: [
                    Icon(kategoriIcons[k], size: 18),
                    const SizedBox(width: 8),
                    Text(kategoriLabels[k] ?? k),
                  ]),
                )).toList(),
                onChanged: (v) => katCtrl.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: aciklamaCtrl, decoration: dec('Açıklama'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: tutarCtrl, decoration: dec('Tutar (₺)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: tarihCtrl, decoration: dec('Tarih (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: belgeCtrl, decoration: dec('Belge/Fatura No')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'kategori': katCtrl.value,
                'aciklama': aciklamaCtrl.text,
                'tutar': double.tryParse(tutarCtrl.text) ?? 0,
                'tarih': tarihCtrl.text,
                'belge_no': belgeCtrl.text,
              };
              if (item != null) await ApiService.updateGider(item.id, data);
              else await ApiService.createGider(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Gider g) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Gideri Sil'),
      content: Text('"${g.aciklama}" silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteGider(g.id);
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
    final toplamTutar = giderler.fold<double>(0, (s, g) => s + g.tutar);

    // Group by category
    final Map<String, double> byKategori = {};
    for (final g in giderler) {
      byKategori[g.kategori] = (byKategori[g.kategori] ?? 0) + g.tutar;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Gider'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _chip('${giderler.length} kayıt', Colors.blue),
                          const SizedBox(width: 8),
                          _chip('Toplam: ${trCurrency.format(toplamTutar)}', Colors.red),
                        ]),
                        if (byKategori.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Kategoriye Göre Dağılım',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          ...byKategori.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              Icon(kategoriIcons[e.key] ?? Icons.category, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Text(kategoriLabels[e.key] ?? e.key,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(child: LinearProgressIndicator(
                                value: toplamTutar > 0 ? (e.value / toplamTutar) : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              )),
                              const SizedBox(width: 8),
                              Text(trCurrency.format(e.value),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: giderler.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(child: Text('Gider kaydı bulunamadı', style: TextStyle(color: Colors.grey))))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final g = giderler[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(kategoriIcons[g.kategori] ?? Icons.category,
                                          color: Colors.red.shade400),
                                    ),
                                    title: Text(g.aciklama,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(trCurrency.format(g.tutar),
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700)),
                                        Text('${g.tarih} · ${kategoriLabels[g.kategori] ?? g.kategori}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                        if (g.belgeNo.isNotEmpty)
                                          Text('Belge: ${g.belgeNo}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton(
                                      icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                      ],
                                      onSelected: (v) {
                                        if (v == 'edit') _showForm(item: g);
                                        if (v == 'delete') _confirmDelete(g);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: giderler.length,
                          ),
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
