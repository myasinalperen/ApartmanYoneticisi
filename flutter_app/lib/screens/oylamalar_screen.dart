import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';

class OylamalarScreen extends StatefulWidget {
  const OylamalarScreen({super.key});
  @override State<OylamalarScreen> createState() => _OylamalarScreenState();
}

class _OylamalarScreenState extends State<OylamalarScreen> {
  List<Oylama> oylamalar = [];
  List<Daire> daireler = [];
  bool loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final o = await ApiService.getOylamalar();
      final d = await ApiService.getDaireler();
      setState(() { oylamalar = o; daireler = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  void _showCreateForm() {
    final baslikCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();
    final bitisCtrl = TextEditingController();
    final secenekler = <TextEditingController>[
      TextEditingController(text: 'Evet'),
      TextEditingController(text: 'Hayır'),
    ];

    InputDecoration dec(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: const Text('Yeni Oylama'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: baslikCtrl, decoration: dec('Başlık')),
            const SizedBox(height: 12),
            TextField(controller: aciklamaCtrl, decoration: dec('Açıklama'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: bitisCtrl, decoration: dec('Bitiş Tarihi (YYYY-MM-DDThh:mm)')),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Seçenekler', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setS(() => secenekler.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ekle'),
              ),
            ]),
            ...secenekler.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: TextField(controller: e.value, decoration: dec('Seçenek ${e.key + 1}'))),
                if (secenekler.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setS(() => secenekler.removeAt(e.key)),
                  ),
              ]),
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'baslik': baslikCtrl.text,
                'aciklama': aciklamaCtrl.text,
                'bitis': bitisCtrl.text.isEmpty ? null : bitisCtrl.text,
                'secenekler': secenekler.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
              };
              await ApiService.createOylama(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: const Text('Oluştur'),
          ),
        ],
      )),
    );
  }

  void _showOyVer(Oylama oylama) {
    if (daireler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce daire ekleyin')));
      return;
    }
    final daireId = ValueNotifier<int>(daireler.first.id);
    final secenekId = ValueNotifier<int?>(oylama.secenekler.isNotEmpty ? oylama.secenekler.first.id : null);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oy Kullan'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder(valueListenable: daireId, builder: (_, v, __) =>
            DropdownButtonFormField<int>(
              value: v,
              decoration: InputDecoration(
                labelText: 'Daire', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: daireler.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => daireId.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(valueListenable: secenekId, builder: (_, v, __) =>
            DropdownButtonFormField<int?>(
              value: v,
              decoration: InputDecoration(
                labelText: 'Seçenek', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: oylama.secenekler.map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.metin),
              )).toList(),
              onChanged: (v) => secenekId.value = v,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (secenekId.value == null) return;
              try {
                await ApiService.oyVer(oylama.id, daireId.value, secenekId.value!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Oyunuz kaydedildi'), backgroundColor: Colors.green));
                }
                _load();
              } catch(e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: Bu daire zaten oy kullandı'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Oyu Gönder'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Oylama o) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Oylamayı Sil'),
      content: Text('"${o.baslik}" silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteOylama(o.id);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Oylama'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : oylamalar.isEmpty
              ? const Center(child: Text('Oylama bulunamadı', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: oylamalar.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = oylamalar[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              StatusBadge.forDurum(o.durum),
                              const Spacer(),
                              Text('${o.toplamOy} oy',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              PopupMenuButton(
                                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                                itemBuilder: (_) => [
                                  if (o.durum == 'aktif')
                                    const PopupMenuItem(value: 'tamamlandi', child: Text('Oylamayı Bitir')),
                                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                ],
                                onSelected: (v) async {
                                  if (v == 'tamamlandi') {
                                    await ApiService.updateOylama(o.id, {'durum': 'tamamlandi'});
                                    _load();
                                  } else if (v == 'delete') _confirmDelete(o);
                                },
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Text(o.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (o.aciklama.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(o.aciklama, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                            ],
                            if (o.bitis != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.schedule, size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text('Bitiş: ${o.bitis!.substring(0, 10)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ]),
                            ],
                            const SizedBox(height: 16),
                            // Oy sonuçları
                            ...o.secenekler.map((s) {
                              final oran = o.toplamOy > 0 ? s.oySayisi / o.toplamOy : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(s.metin, style: const TextStyle(fontSize: 14))),
                                      Text('${s.oySayisi} (%${(oran * 100).round()})',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ]),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: oran,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (o.durum == 'aktif') ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showOyVer(o),
                                  icon: const Icon(Icons.how_to_vote, size: 16),
                                  label: const Text('Oy Kullan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
