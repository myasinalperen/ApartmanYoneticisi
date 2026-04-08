import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class AidatlarScreen extends StatefulWidget {
  const AidatlarScreen({super.key});
  @override State<AidatlarScreen> createState() => _AidatlarScreenState();
}

class _AidatlarScreenState extends State<AidatlarScreen> {
  List<Aidat> aidatlar = [];
  List<Daire> daireler = [];
  bool loading = true;
  int selectedAy = DateTime.now().month;
  int selectedYil = DateTime.now().year;

  final aylar = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  final trCurrency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final a = await ApiService.getAidatlar(ay: selectedAy, yil: selectedYil);
      final d = await ApiService.getDaireler();
      setState(() { aidatlar = a; daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  String _daireLabel(int id) {
    final d = daireler.where((x) => x.id == id).firstOrNull;
    return d?.label ?? 'Daire $id';
  }

  Future<void> _topluOlustur() async {
    final tutarCtrl = TextEditingController(text: '750');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Toplu Aidat Oluştur'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${aylar[selectedAy - 1]} $selectedYil için tüm dolu dairelere aidat kaydı oluşturulacak.'),
          const SizedBox(height: 12),
          TextField(
            controller: tutarCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Aidat Tutarı (₺)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    if (result == true) {
      await ApiService.topluOlustur(selectedYil, selectedAy, double.tryParse(tutarCtrl.text) ?? 750);
      _load();
    }
  }

  void _markPaid(Aidat a) async {
    await ApiService.updateAidat(a.id, {
      'odendi': true,
      'odeme_tarihi': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
    _load();
  }

  void _confirmDelete(Aidat a) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Kaydı Sil'),
      content: const Text('Bu aidat kaydı silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteAidat(a.id);
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
    final toplam = aidatlar.fold<double>(0, (s, a) => s + a.tutar);
    final odenen = aidatlar.where((a) => a.odendi).fold<double>(0, (s, a) => s + a.tutar);
    final bekleyen = toplam - odenen;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _topluOlustur,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Toplu Oluştur'),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Dönem:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedAy,
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(aylar[i]))),
                  onChanged: (v) { setState(() => selectedAy = v!); _load(); },
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedYil,
                  items: List.generate(5, (i) {
                    final y = DateTime.now().year - 2 + i;
                    return DropdownMenuItem(value: y, child: Text('$y'));
                  }),
                  onChanged: (v) { setState(() => selectedYil = v!); _load(); },
                ),
              ],
            ),
          ),
          // Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _summaryBox('Toplam', toplam, Colors.blue),
                const SizedBox(width: 8),
                _summaryBox('Ödenen', odenen, Colors.green),
                const SizedBox(width: 8),
                _summaryBox('Bekleyen', bekleyen, Colors.red),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : aidatlar.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.credit_card_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Bu dönem için kayıt yok',
                              style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _topluOlustur,
                            icon: const Icon(Icons.add),
                            label: const Text('Toplu Oluştur'),
                          ),
                        ]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: aidatlar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final a = aidatlar[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: a.odendi ? Colors.green.shade200 : Colors.red.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: a.odendi ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  a.odendi ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  color: a.odendi ? Colors.green.shade600 : Colors.red.shade400,
                                ),
                              ),
                              title: Text(_daireLabel(a.daireId),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trCurrency.format(a.tutar + a.gecikmeFaizi),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if (a.odemeTarihi != null)
                                    Text('Ödeme: ${a.odemeTarihi}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  if (a.gecikmeFaizi > 0)
                                    Text('Gecikme faizi: ${trCurrency.format(a.gecikmeFaizi)}',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                StatusBadge.forDurum(a.odendi ? 'tamamlandi' : 'beklemede'),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                                  itemBuilder: (_) => [
                                    if (!a.odendi)
                                      const PopupMenuItem(value: 'pay', child: Text('Ödendi İşaretle')),
                                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'pay') _markPaid(a);
                                    if (v == 'delete') _confirmDelete(a);
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

  Widget _summaryBox(String label, double val, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(trCurrency.format(val),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.shade700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
