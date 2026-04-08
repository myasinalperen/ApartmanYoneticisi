import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DuyurularScreen extends StatefulWidget {
  const DuyurularScreen({super.key});
  @override State<DuyurularScreen> createState() => _DuyurularScreenState();
}

class _DuyurularScreenState extends State<DuyurularScreen> {
  List<Duyuru> duyurular = [];
  bool loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.getDuyurular();
      setState(() { duyurular = d; loading = false; });
    } catch(e) { setState(() => loading = false); }
  }

  void _showForm({Duyuru? item}) {
    final baslikCtrl = TextEditingController(text: item?.baslik ?? '');
    final icerikCtrl = TextEditingController(text: item?.icerik ?? '');
    final oncelik = ValueNotifier(item?.oncelik ?? 'normal');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Yeni Duyuru' : 'Duyuru Düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: baslikCtrl,
              decoration: InputDecoration(
                labelText: 'Başlık', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: icerikCtrl,
              decoration: InputDecoration(
                labelText: 'İçerik', isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(valueListenable: oncelik, builder: (_, v, __) =>
              DropdownButtonFormField<String>(
                value: v,
                decoration: InputDecoration(
                  labelText: 'Öncelik', isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'onemli', child: Text('Önemli')),
                  DropdownMenuItem(value: 'acil', child: Text('Acil')),
                ],
                onChanged: (v) => oncelik.value = v!,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'baslik': baslikCtrl.text,
                'icerik': icerikCtrl.text,
                'oncelik': oncelik.value,
              };
              if (item != null) await ApiService.updateDuyuru(item.id, data);
              else await ApiService.createDuyuru(data);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text(item == null ? 'Yayınla' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Duyuru d) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Duyuruyu Sil'),
      content: Text('"${d.baslik}" silinecek.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService.deleteDuyuru(d.id);
            if (mounted) Navigator.pop(context);
            _load();
          },
          child: const Text('Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Color _oncelikColor(String o) => switch(o) {
    'acil' => Colors.red.shade700,
    'onemli' => Colors.orange.shade700,
    _ => Colors.blue.shade700,
  };

  Color _oncelikBg(String o) => switch(o) {
    'acil' => Colors.red.shade50,
    'onemli' => Colors.orange.shade50,
    _ => Colors.blue.shade50,
  };

  IconData _oncelikIcon(String o) => switch(o) {
    'acil' => Icons.warning_amber_rounded,
    'onemli' => Icons.info_rounded,
    _ => Icons.campaign_rounded,
  };

  String _oncelikLabel(String o) => switch(o) {
    'acil' => 'Acil',
    'onemli' => 'Önemli',
    _ => 'Duyuru',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.campaign),
        label: const Text('Yeni Duyuru'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : duyurular.isEmpty
              ? const Center(child: Text('Duyuru bulunamadı', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: duyurular.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = duyurular[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _oncelikColor(d.oncelik).withOpacity(0.3)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _oncelikColor(d.oncelik), width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _oncelikBg(d.oncelik),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(children: [
                                    Icon(_oncelikIcon(d.oncelik), size: 13, color: _oncelikColor(d.oncelik)),
                                    const SizedBox(width: 4),
                                    Text(_oncelikLabel(d.oncelik),
                                        style: TextStyle(fontSize: 12, color: _oncelikColor(d.oncelik), fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                                const Spacer(),
                                Text(d.createdAt.length > 10 ? d.createdAt.substring(0, 10) : d.createdAt,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
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
                              const SizedBox(height: 10),
                              Text(d.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (d.icerik.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(d.icerik, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
