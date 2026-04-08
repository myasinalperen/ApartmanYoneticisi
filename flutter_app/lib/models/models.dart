class Daire {
  final int id;
  final String blok;
  final int kat;
  final String daireNo;
  final String tip;
  final double metrekare;
  final String durum;

  Daire({
    required this.id,
    required this.blok,
    required this.kat,
    required this.daireNo,
    required this.tip,
    required this.metrekare,
    required this.durum,
  });

  factory Daire.fromJson(Map<String, dynamic> j) => Daire(
        id: j['id'],
        blok: j['blok'] ?? 'A',
        kat: j['kat'],
        daireNo: j['daire_no'],
        tip: j['tip'] ?? '2+1',
        metrekare: (j['metrekare'] ?? 100).toDouble(),
        durum: j['durum'] ?? 'dolu',
      );

  Map<String, dynamic> toJson() => {
        'blok': blok,
        'kat': kat,
        'daire_no': daireNo,
        'tip': tip,
        'metrekare': metrekare,
        'durum': durum,
      };

  String get label => 'Blok $blok · ${kat}. Kat · No: $daireNo';
}

class Sakin {
  final int id;
  final String ad;
  final String soyad;
  final String telefon;
  final String email;
  final int daireId;
  final String tip;
  final String? girisTarihi;
  final bool aktif;

  Sakin({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.telefon,
    required this.email,
    required this.daireId,
    required this.tip,
    this.girisTarihi,
    required this.aktif,
  });

  factory Sakin.fromJson(Map<String, dynamic> j) => Sakin(
        id: j['id'],
        ad: j['ad'],
        soyad: j['soyad'],
        telefon: j['telefon'] ?? '',
        email: j['email'] ?? '',
        daireId: j['daire_id'],
        tip: j['tip'] ?? 'kiracı',
        girisTarihi: j['giris_tarihi'],
        aktif: j['aktif'] ?? true,
      );

  String get adSoyad => '$ad $soyad';
}

class Aidat {
  final int id;
  final int daireId;
  final int ay;
  final int yil;
  final double tutar;
  final bool odendi;
  final String? odemeTarihi;
  final double gecikmeFaizi;

  Aidat({
    required this.id,
    required this.daireId,
    required this.ay,
    required this.yil,
    required this.tutar,
    required this.odendi,
    this.odemeTarihi,
    required this.gecikmeFaizi,
  });

  factory Aidat.fromJson(Map<String, dynamic> j) => Aidat(
        id: j['id'],
        daireId: j['daire_id'],
        ay: j['ay'],
        yil: j['yil'],
        tutar: (j['tutar'] ?? 0).toDouble(),
        odendi: j['odendi'] ?? false,
        odemeTarihi: j['odeme_tarihi'],
        gecikmeFaizi: (j['gecikme_faizi'] ?? 0).toDouble(),
      );
}

class Fatura {
  final int id;
  final String tip;
  final int ay;
  final int yil;
  final double tutar;
  final String? sonOdemeTarihi;
  final bool odendi;
  final String aciklama;

  Fatura({
    required this.id,
    required this.tip,
    required this.ay,
    required this.yil,
    required this.tutar,
    this.sonOdemeTarihi,
    required this.odendi,
    required this.aciklama,
  });

  factory Fatura.fromJson(Map<String, dynamic> j) => Fatura(
        id: j['id'],
        tip: j['tip'],
        ay: j['ay'],
        yil: j['yil'],
        tutar: (j['tutar'] ?? 0).toDouble(),
        sonOdemeTarihi: j['son_odeme_tarihi'],
        odendi: j['odendi'] ?? false,
        aciklama: j['aciklama'] ?? '',
      );
}

class Talep {
  final int id;
  final int daireId;
  final String baslik;
  final String aciklama;
  final String kategori;
  final String oncelik;
  final String durum;
  final String createdAt;
  final String? tamamlanmaTarihi;

  Talep({
    required this.id,
    required this.daireId,
    required this.baslik,
    required this.aciklama,
    required this.kategori,
    required this.oncelik,
    required this.durum,
    required this.createdAt,
    this.tamamlanmaTarihi,
  });

  factory Talep.fromJson(Map<String, dynamic> j) => Talep(
        id: j['id'],
        daireId: j['daire_id'],
        baslik: j['baslik'],
        aciklama: j['aciklama'] ?? '',
        kategori: j['kategori'] ?? 'teknik',
        oncelik: j['oncelik'] ?? 'orta',
        durum: j['durum'] ?? 'beklemede',
        createdAt: j['created_at'] ?? '',
        tamamlanmaTarihi: j['tamamlanma_tarihi'],
      );
}

class Sikayet {
  final int id;
  final int sikayetEdenDaireId;
  final int? sikayetEdilenDaireId;
  final String baslik;
  final String aciklama;
  final String kategori;
  final String durum;
  final String createdAt;

  Sikayet({
    required this.id,
    required this.sikayetEdenDaireId,
    this.sikayetEdilenDaireId,
    required this.baslik,
    required this.aciklama,
    required this.kategori,
    required this.durum,
    required this.createdAt,
  });

  factory Sikayet.fromJson(Map<String, dynamic> j) => Sikayet(
        id: j['id'],
        sikayetEdenDaireId: j['sikayet_eden_daire_id'],
        sikayetEdilenDaireId: j['sikayet_edilen_daire_id'],
        baslik: j['baslik'],
        aciklama: j['aciklama'] ?? '',
        kategori: j['kategori'] ?? 'diger',
        durum: j['durum'] ?? 'acik',
        createdAt: j['created_at'] ?? '',
      );
}

class OySecenek {
  final int id;
  final String metin;
  final int oySayisi;

  OySecenek({required this.id, required this.metin, required this.oySayisi});

  factory OySecenek.fromJson(Map<String, dynamic> j) => OySecenek(
        id: j['id'],
        metin: j['metin'],
        oySayisi: j['oy_sayisi'] ?? 0,
      );
}

class Oylama {
  final int id;
  final String baslik;
  final String aciklama;
  final String baslangic;
  final String? bitis;
  final String durum;
  final String createdAt;
  final List<OySecenek> secenekler;
  final int toplamOy;

  Oylama({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.baslangic,
    this.bitis,
    required this.durum,
    required this.createdAt,
    required this.secenekler,
    required this.toplamOy,
  });

  factory Oylama.fromJson(Map<String, dynamic> j) => Oylama(
        id: j['id'],
        baslik: j['baslik'],
        aciklama: j['aciklama'] ?? '',
        baslangic: j['baslangic'] ?? '',
        bitis: j['bitis'],
        durum: j['durum'] ?? 'aktif',
        createdAt: j['created_at'] ?? '',
        secenekler: (j['secenekler'] as List? ?? [])
            .map((s) => OySecenek.fromJson(s))
            .toList(),
        toplamOy: j['toplam_oy'] ?? 0,
      );
}

class Duyuru {
  final int id;
  final String baslik;
  final String icerik;
  final String oncelik;
  final String createdAt;

  Duyuru({
    required this.id,
    required this.baslik,
    required this.icerik,
    required this.oncelik,
    required this.createdAt,
  });

  factory Duyuru.fromJson(Map<String, dynamic> j) => Duyuru(
        id: j['id'],
        baslik: j['baslik'],
        icerik: j['icerik'] ?? '',
        oncelik: j['oncelik'] ?? 'normal',
        createdAt: j['created_at'] ?? '',
      );
}

class Gider {
  final int id;
  final String kategori;
  final String aciklama;
  final double tutar;
  final String tarih;
  final String belgeNo;

  Gider({
    required this.id,
    required this.kategori,
    required this.aciklama,
    required this.tutar,
    required this.tarih,
    required this.belgeNo,
  });

  factory Gider.fromJson(Map<String, dynamic> j) => Gider(
        id: j['id'],
        kategori: j['kategori'] ?? 'diger',
        aciklama: j['aciklama'],
        tutar: (j['tutar'] ?? 0).toDouble(),
        tarih: j['tarih'] ?? '',
        belgeNo: j['belge_no'] ?? '',
      );
}

class Toplanti {
  final int id;
  final String baslik;
  final String tarih;
  final String yer;
  final String ajanda;
  final String notlar;
  final String durum;

  Toplanti({
    required this.id,
    required this.baslik,
    required this.tarih,
    required this.yer,
    required this.ajanda,
    required this.notlar,
    required this.durum,
  });

  factory Toplanti.fromJson(Map<String, dynamic> j) => Toplanti(
        id: j['id'],
        baslik: j['baslik'],
        tarih: j['tarih'] ?? '',
        yer: j['yer'] ?? '',
        ajanda: j['ajanda'] ?? '',
        notlar: j['notlar'] ?? '',
        durum: j['durum'] ?? 'planlandı',
      );
}

class DashboardStats {
  final int toplamDaire;
  final int doluDaire;
  final int bosDaire;
  final int toplamSakin;
  final double buAyAidatToplam;
  final double buAyAidatOdenen;
  final double buAyAidatBekleyen;
  final int bekleyenTalep;
  final int acikSikayet;
  final int aktifOylama;
  final double buAyGider;
  final int odenmemisFatura;

  DashboardStats({
    required this.toplamDaire,
    required this.doluDaire,
    required this.bosDaire,
    required this.toplamSakin,
    required this.buAyAidatToplam,
    required this.buAyAidatOdenen,
    required this.buAyAidatBekleyen,
    required this.bekleyenTalep,
    required this.acikSikayet,
    required this.aktifOylama,
    required this.buAyGider,
    required this.odenmemisFatura,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        toplamDaire: j['toplam_daire'] ?? 0,
        doluDaire: j['dolu_daire'] ?? 0,
        bosDaire: j['bos_daire'] ?? 0,
        toplamSakin: j['toplam_sakin'] ?? 0,
        buAyAidatToplam: (j['bu_ay_aidat_toplam'] ?? 0).toDouble(),
        buAyAidatOdenen: (j['bu_ay_aidat_odenen'] ?? 0).toDouble(),
        buAyAidatBekleyen: (j['bu_ay_aidat_bekleyen'] ?? 0).toDouble(),
        bekleyenTalep: j['bekleyen_talep'] ?? 0,
        acikSikayet: j['acik_sikayet'] ?? 0,
        aktifOylama: j['aktif_oylama'] ?? 0,
        buAyGider: (j['bu_ay_gider'] ?? 0).toDouble(),
        odenmemisFatura: j['odenmemis_fatura'] ?? 0,
      );
}
