import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class FaturalarScreen extends StatefulWidget {
  const FaturalarScreen({super.key});
  @override State<FaturalarScreen> createState() => _FaturalarScreenState();
}

class _FaturalarScreenState extends State<FaturalarScreen> {
  List<Fatura> faturalar = [];
  bool loading = true;
  int? filterAy;
  int? filterYil;

  final tipler = ['elektrik', 'su', 'dogalgaz', 'asansor', 'temizlik', 'internet', 'diger'];
  final tipIcons = {
    'elektrik': Icons.bolt, 'su': Icons.water_drop, 'dogalgaz': Icons.local_fire_department,
    'asansor': Icons.elevator, 'temizlik': Icons.cleaning_services, 'internet': Icons.wifi, 'diger': Icons.receipt,
  };
  final aylar = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  final trCurrency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override void initState() {
    super.initState();
    filterYil = DateTime.now().year;
    filterAy = DateTime.now().month;
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final f = await ApiService.getFaturalar(ay: filterAy, yil: filterYil);
      setState(() { faturalar = f; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  void _showForm({Fatura? item}) {
    final tipCtrl = ValueNotifier(item?.tip ?? 'elektrik');
    final ayCtrl = ValueNotifier(item?.ay ?? DateTime.now().month);
    final yilCtrl = TextEditingController(text: '${item?.yil ?? DateTime.now().year}');
    final tutarCtrl = TextEditingController(text: item != null ? '${item.tutar}' : '');
    final sonTarihCtrl = TextEditingController(text: item?.sonOdemeTarihi ?? '');
    final aciklamaCtrl = TextEditingController(text: item?.aciklama ?? '');
    final odendi = ValueNotifier(item?.odendi ?? false);

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Fatura' : 'Fatura Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ValueListenableBuilder(valueListenable: tipCtrl, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v,
                decoration: dec('Fatura Tipi'),
                items: tipler.map((t) => DropdownMenuItem(
                  value: t,
                  child: Row(children: [
                    Icon(tipIcons[t] ?? Icons.receipt, size: 18),
                    const SizedBox(width: 8),
                    Text(StatusBadge.forFaturaTip(t).text),
                  ]),
                )).toList(),
                onChanged: (v) => tipCtrl.value = v!,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ValueListenableBuilder(valueListenable: ayCtrl, builder: (_, v, __) =>
                DropdownButtonFormField<int>(
                  value: v,
                  decoration: dec('Ay'),
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(aylar[i]))),
                  onChanged: (v) => ayCtrl.value = v!,
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: yilCtrl, decoration: dec('Yıl'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: tutarCtrl, decoration: dec('Tutar (₺)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: sonTarihCtrl, decoration: dec('Son Ödeme Tarihi (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: aciklamaCtrl, decoration: dec('Açıklama'), maxLines: 2),
            const SizedBox(height: 8),
            ValueListenableBuilder(valueListenable: odendi, builder: (_, v, __) =>
              CheckboxListTile(
                title: const Text('Ödendi', style: TextStyle(fontSize: 14)),
                value: v, onChanged: (x) => odendi.value = x ?? false,
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
                'tip': tipCtrl.value,
                'ay': ayCtrl.value,
                'yil': int.tryParse(yilCtrl.text) ?? DateTime.now().year,
                'tutar': double.tryParse(tutarCtrl.text) ?? 0,
                'son_odeme_tarihi': sonTarihCtrl.text.isEmpty ? null : sonTarihCtrl.text,
                'odendi': odendi.value,
                'aciklama': aciklamaCtrl.text,
              };
              if (item != null) await ApiService.updateFatura(item.id, data);
              else await ApiService.createFatura(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Fatura f) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Faturayı Sil'),
      content: const Text('Bu fatura silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteFatura(f.id);
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
    final odenmemis = faturalar.where((f) => !f.odendi).length;
    final toplamTutar = faturalar.fold<double>(0, (s, f) => s + f.tutar);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Fatura'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              DropdownButton<int?>(
                value: filterAy,
                hint: const Text('Tüm Aylar'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tüm Aylar')),
                  ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(aylar[i]))),
                ],
                onChanged: (v) { setState(() => filterAy = v); _load(); },
              ),
              const SizedBox(width: 12),
              DropdownButton<int?>(
                value: filterYil,
                hint: const Text('Tüm Yıllar'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tüm Yıllar')),
                  ...List.generate(5, (i) {
                    final y = DateTime.now().year - 2 + i;
                    return DropdownMenuItem(value: y, child: Text('$y'));
                  }),
                ],
                onChanged: (v) { setState(() => filterYil = v); _load(); },
              ),
            ]),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _chip('${faturalar.length} Fatura', Colors.blue),
              const SizedBox(width: 8),
              _chip('$odenmemis Bekliyor', Colors.red),
              const SizedBox(width: 8),
              _chip(trCurrency.format(toplamTutar), Colors.purple),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : faturalar.isEmpty
                    ? const Center(child: Text('Fatura bulunamadı', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: faturalar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final f = faturalar[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: f.odendi ? Colors.green.shade200 : Colors.orange.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: f.odendi ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tipIcons[f.tip] ?? Icons.receipt,
                                    color: f.odendi ? Colors.green.shade600 : Colors.orange.shade600),
                              ),
                              title: Row(children: [
                                StatusBadge.forFaturaTip(f.tip),
                                const SizedBox(width: 8),
                                Text('${aylar[f.ay - 1]} ${f.yil}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              ]),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trCurrency.format(f.tutar),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if (f.sonOdemeTarihi != null)
                                    Text('Son ödeme: ${f.sonOdemeTarihi}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  if (f.aciklama.isNotEmpty)
                                    Text(f.aciklama,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                StatusBadge.forDurum(f.odendi ? 'tamamlandi' : 'beklemede'),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(item: f);
                                    if (v == 'delete') _confirmDelete(f);
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
