import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? stats;
  bool loading = true;
  String? seedMsg;

  final trCurrency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  final aylar = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService.getDashboard();
      setState(() { stats = s; loading = false; });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _seed() async {
    try {
      final msg = await ApiService.seedDatabase();
      setState(() => seedMsg = msg);
      await _load();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => seedMsg = null);
      });
    } catch (e) {
      setState(() => seedMsg = 'Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ayAdi = aylar[now.month - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Yönetim Paneli',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('$ayAdi ${now.year} · Genel durum',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _seed,
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Örnek Veri'),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    if (seedMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(seedMsg!, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        StatCard(
                          title: 'Toplam Daire',
                          value: '${stats?.toplamDaire ?? 0}',
                          icon: Icons.apartment_rounded,
                          iconColor: Colors.blue.shade600,
                          iconBg: Colors.blue.shade50,
                          subtitle: '${stats?.doluDaire ?? 0} dolu · ${stats?.bosDaire ?? 0} boş',
                        ),
                        StatCard(
                          title: 'Aktif Sakin',
                          value: '${stats?.toplamSakin ?? 0}',
                          icon: Icons.people_rounded,
                          iconColor: Colors.purple.shade600,
                          iconBg: Colors.purple.shade50,
                          subtitle: 'Kayıtlı sakin',
                        ),
                        StatCard(
                          title: 'Bekleyen Talep',
                          value: '${stats?.bekleyenTalep ?? 0}',
                          icon: Icons.build_rounded,
                          iconColor: Colors.orange.shade600,
                          iconBg: Colors.orange.shade50,
                          hasAlert: (stats?.bekleyenTalep ?? 0) > 3,
                        ),
                        StatCard(
                          title: 'Açık Şikayet',
                          value: '${stats?.acikSikayet ?? 0}',
                          icon: Icons.report_problem_rounded,
                          iconColor: Colors.red.shade600,
                          iconBg: Colors.red.shade50,
                          hasAlert: (stats?.acikSikayet ?? 0) > 0,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Aidat kartı
                    Card(
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
                            Text('$ayAdi ${now.year} Aidat Durumu',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _aidatBox('Toplam', stats?.buAyAidatToplam ?? 0, Colors.blue),
                                const SizedBox(width: 8),
                                _aidatBox('Ödenen', stats?.buAyAidatOdenen ?? 0, Colors.green),
                                const SizedBox(width: 8),
                                _aidatBox('Bekleyen', stats?.buAyAidatBekleyen ?? 0, Colors.red),
                              ],
                            ),
                            if ((stats?.buAyAidatToplam ?? 0) > 0) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tahsilat oranı', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(
                                    '%${((stats!.buAyAidatOdenen / stats!.buAyAidatToplam) * 100).round()}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: stats!.buAyAidatToplam > 0
                                    ? (stats!.buAyAidatOdenen / stats!.buAyAidatToplam).clamp(0, 1)
                                    : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pasta grafiği - Aidat dağılımı
                    if ((stats?.buAyAidatToplam ?? 0) > 0)
                      Card(
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
                              const Text('Aidat Dağılımı',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PieChart(
                                        PieChartData(
                                          sections: [
                                            PieChartSectionData(
                                              value: stats!.buAyAidatOdenen,
                                              color: const Color(0xFF22C55E),
                                              title: '',
                                              radius: 50,
                                            ),
                                            PieChartSectionData(
                                              value: stats!.buAyAidatBekleyen,
                                              color: const Color(0xFFEF4444),
                                              title: '',
                                              radius: 50,
                                            ),
                                          ],
                                          centerSpaceRadius: 35,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _legend('Ödenen', const Color(0xFF22C55E)),
                                        const SizedBox(height: 8),
                                        _legend('Bekleyen', const Color(0xFFEF4444)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Hızlı durum
                    Card(
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
                            const Text('Hızlı Durum',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _statusRow(Icons.receipt_long_rounded, 'Ödenmemiş Fatura',
                                '${stats?.odenmemisFatura ?? 0} adet',
                                (stats?.odenmemisFatura ?? 0) > 0),
                            _statusRow(Icons.how_to_vote_rounded, 'Aktif Oylama',
                                '${stats?.aktifOylama ?? 0} adet', false),
                            _statusRow(Icons.trending_down_rounded, '$ayAdi Gideri',
                                trCurrency.format(stats?.buAyGider ?? 0), false),
                            _statusRow(Icons.apartment_rounded, 'Doluluk Oranı',
                                stats != null && stats!.toplamDaire > 0
                                    ? '%${((stats!.doluDaire / stats!.toplamDaire) * 100).round()}'
                                    : '%0',
                                false),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Durum kartları
                    _infoCard(
                      'Aidat Ödemeleri',
                      (stats?.buAyAidatBekleyen ?? 0) == 0,
                      'Tüm aidatlar ödendi',
                      '${trCurrency.format(stats?.buAyAidatBekleyen ?? 0)} tahsil edilmedi',
                    ),
                    const SizedBox(height: 8),
                    _infoCard(
                      'Fatura Durumu',
                      (stats?.odenmemisFatura ?? 0) == 0,
                      'Tüm faturalar ödendi',
                      '${stats?.odenmemisFatura} adet fatura bekliyor',
                    ),
                    const SizedBox(height: 8),
                    _infoCard(
                      'Bakım Talepleri',
                      (stats?.bekleyenTalep ?? 0) == 0,
                      'Bekleyen talep yok',
                      '${stats?.bekleyenTalep} aktif talep var',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _aidatBox(String label, double val, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0).format(val),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value, bool bad) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: bad ? Colors.red.shade600 : const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _infoCard(String title, bool ok, String okText, String badText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: ok ? Colors.green : Colors.red, width: 4),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 16,
                color: ok ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(ok ? okText : badText,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ok ? Colors.green.shade700 : Colors.red.shade700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
