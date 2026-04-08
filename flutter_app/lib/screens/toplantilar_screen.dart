import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class ToplantilarScreen extends StatefulWidget {
  const ToplantilarScreen({super.key});
  @override State<ToplantilarScreen> createState() => _ToplantilarScreenState();
}

class _ToplantilarScreenState extends State<ToplantilarScreen> {
  List<Toplanti> toplantilar = [];
  bool loading = true;

  final durumlar = ['planlandı', 'tamamlandı', 'iptal'];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final t = await ApiService.getToplantilar();
      setState(() { toplantilar = t; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  void _showForm({Toplanti? item}) {
    final baslikCtrl = TextEditingController(text: item?.baslik ?? '');
    final tarihCtrl = TextEditingController(
        text: item?.tarih != null ? item!.tarih.substring(0, 16).replaceAll('T', ' ') : '');
    final yerCtrl = TextEditingController(text: item?.yer ?? 'Apartman Girişi');
    final ajandaCtrl = TextEditingController(text: item?.ajanda ?? '');
    final notlarCtrl = TextEditingController(text: item?.notlar ?? '');
    final durum = ValueNotifier(item?.durum ?? 'planlandı');

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Toplantı' : 'Toplantı Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: baslikCtrl, decoration: dec('Toplantı Başlığı')),
            const SizedBox(height: 12),
            TextField(
              controller: tarihCtrl,
              decoration: dec('Tarih ve Saat (YYYY-MM-DD HH:MM)'),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            TextField(controller: yerCtrl, decoration: dec('Toplantı Yeri')),
            const SizedBox(height: 12),
            TextField(controller: ajandaCtrl, decoration: dec('Gündem'), maxLines: 4),
            const SizedBox(height: 12),
            TextField(controller: notlarCtrl, decoration: dec('Notlar'), maxLines: 3),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: durum, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v, decoration: dec('Durum'),
                items: durumlar.map((d) => DropdownMenuItem(
                  value: d,
                  child: Row(children: [
                    Icon(_durumIcon(d), size: 16, color: _durumColor(d)),
                    const SizedBox(width: 8),
                    Text(_durumLabel(d)),
                  ]),
                )).toList(),
                onChanged: (v) => durum.value = v!,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final tarihStr = tarihCtrl.text.trim().replaceAll(' ', 'T');
              final data = {
                'baslik': baslikCtrl.text,
                'tarih': tarihStr.isNotEmpty ? tarihStr : DateTime.now().toIso8601String(),
                'yer': yerCtrl.text,
                'ajanda': ajandaCtrl.text,
                'notlar': notlarCtrl.text,
                'durum': durum.value,
              };
              if (item != null) await ApiService.updateToplanti(item.id, data);
              else await ApiService.createToplanti(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Toplanti t) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Toplantıyı Sil'),
      content: Text('"${t.baslik}" silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteToplanti(t.id);
            if (mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  String _durumLabel(String d) => switch(d) {
    'planlandı' => 'Planlandı', 'tamamlandı' => 'Tamamlandı', _ => 'İptal',
  };

  Color _durumColor(String d) => switch(d) {
    'planlandı' => Colors.blue, 'tamamlandı' => Colors.green, _ => Colors.grey,
  };

  IconData _durumIcon(String d) => switch(d) {
    'planlandı' => Icons.event, 'tamamlandı' => Icons.check_circle, _ => Icons.cancel,
  };

  String _formatTarih(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMMM yyyy EEEE, HH:mm', 'tr_TR').format(dt);
    } catch(e) {
      return iso.length > 16 ? iso.substring(0, 16).replaceAll('T', ' ') : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planli = toplantilar.where((t) => t.durum == 'planlandı').length;
    final tamamlandi = toplantilar.where((t) => t.durum == 'tamamlandı').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Toplantı'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(children: [
                    _chip('${toplantilar.length} Toplam', Colors.blue),
                    const SizedBox(width: 8),
                    _chip('$planli Planlandı', Colors.orange),
                    const SizedBox(width: 8),
                    _chip('$tamamlandi Tamamlandı', Colors.green),
                  ]),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: toplantilar.isEmpty
                      ? const Center(child: Text('Toplantı bulunamadı', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: toplantilar.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = toplantilar[i];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: _durumColor(t.durum).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(_durumIcon(t.durum), color: _durumColor(t.durum), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Row(children: [
                                            StatusBadge.forDurum(t.durum),
                                          ]),
                                        ],
                                      )),
                                      PopupMenuButton(
                                        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                          const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                        ],
                                        onSelected: (v) {
                                          if (v == 'edit') _showForm(item: t);
                                          if (v == 'delete') _confirmDelete(t);
                                        },
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(_formatTarih(t.tarih),
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Text(t.yer, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ]),
                                    if (t.ajanda.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('GÜNDEM',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade500, letterSpacing: 0.8)),
                                            const SizedBox(height: 6),
                                            Text(t.ajanda,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (t.notlar.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('NOTLAR',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade600, letterSpacing: 0.8)),
                                            const SizedBox(height: 6),
                                            Text(t.notlar,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                                          ],
                                        ),
                                      ),
                                    ],
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

  Widget _chip(String label, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.w500)),
  );
}
