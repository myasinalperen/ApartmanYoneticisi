import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });

  static StatusBadge forDurum(String durum) {
    return switch (durum) {
      'dolu' || 'aktif' || 'odendi' || 'tamamlandi' || 'cozuldu' => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF15803D),
        ),
      'beklemede' || 'planlandı' || 'acik' => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFFEF9C3),
          textColor: const Color(0xFF854D0E),
        ),
      'isleniyor' || 'inceleniyor' => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1D4ED8),
        ),
      'iptal' || 'kapandi' || 'bos' => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFF3F4F6),
          textColor: const Color(0xFF4B5563),
        ),
      'acil' => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFFEE2E2),
          textColor: const Color(0xFFB91C1C),
        ),
      _ => StatusBadge(
          text: _durumLabel(durum),
          color: const Color(0xFFF3F4F6),
          textColor: const Color(0xFF4B5563),
        ),
    };
  }

  static StatusBadge forOncelik(String oncelik) {
    return switch (oncelik) {
      'acil' => StatusBadge(text: 'Acil', color: const Color(0xFFFEE2E2), textColor: const Color(0xFFB91C1C)),
      'yuksek' => StatusBadge(text: 'Yüksek', color: const Color(0xFFFFEDD5), textColor: const Color(0xFFC2410C)),
      'orta' => StatusBadge(text: 'Orta', color: const Color(0xFFFEF9C3), textColor: const Color(0xFF854D0E)),
      'dusuk' => StatusBadge(text: 'Düşük', color: const Color(0xFFDCFCE7), textColor: const Color(0xFF15803D)),
      _ => StatusBadge(text: oncelik, color: const Color(0xFFF3F4F6), textColor: const Color(0xFF4B5563)),
    };
  }

  static StatusBadge forFaturaTip(String tip) {
    final colors = {
      'elektrik': (const Color(0xFFFFFBEB), const Color(0xFFB45309)),
      'su': (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
      'dogalgaz': (const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
      'asansor': (const Color(0xFFF5F3FF), const Color(0xFF6D28D9)),
      'temizlik': (const Color(0xFFF0FDF4), const Color(0xFF15803D)),
      'internet': (const Color(0xFFF0F9FF), const Color(0xFF0369A1)),
    };
    final c = colors[tip] ?? (const Color(0xFFF3F4F6), const Color(0xFF4B5563));
    return StatusBadge(text: _tipLabel(tip), color: c.$1, textColor: c.$2);
  }

  static String _durumLabel(String d) => switch (d) {
        'dolu' => 'Dolu',
        'bos' => 'Boş',
        'aktif' => 'Aktif',
        'odendi' => 'Ödendi',
        'tamamlandi' || 'tamamlandı' => 'Tamamlandı',
        'cozuldu' => 'Çözüldü',
        'beklemede' => 'Beklemede',
        'planlandı' => 'Planlandı',
        'acik' => 'Açık',
        'isleniyor' => 'İşleniyor',
        'inceleniyor' => 'İnceleniyor',
        'iptal' => 'İptal',
        'kapandi' => 'Kapandı',
        'acil' => 'Acil',
        _ => d,
      };

  static String _tipLabel(String t) => switch (t) {
        'elektrik' => 'Elektrik',
        'su' => 'Su',
        'dogalgaz' => 'Doğalgaz',
        'asansor' => 'Asansör',
        'temizlik' => 'Temizlik',
        'internet' => 'İnternet',
        _ => t,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
