export interface Daire {
  id: number;
  blok: string;
  kat: number;
  daire_no: string;
  tip: string;
  metrekare: number;
  durum: string;
  created_at: string;
}

export interface Sakin {
  id: number;
  ad: string;
  soyad: string;
  telefon: string;
  email: string;
  daire_id: number;
  tip: string;
  giris_tarihi: string | null;
  aktif: boolean;
  created_at: string;
}

export interface Aidat {
  id: number;
  daire_id: number;
  ay: number;
  yil: number;
  tutar: number;
  odendi: boolean;
  odeme_tarihi: string | null;
  gecikme_faizi: number;
  created_at: string;
}

export interface Fatura {
  id: number;
  tip: string;
  ay: number;
  yil: number;
  tutar: number;
  son_odeme_tarihi: string | null;
  odendi: boolean;
  aciklama: string;
  created_at: string;
}

export interface Talep {
  id: number;
  daire_id: number;
  baslik: string;
  aciklama: string;
  kategori: string;
  oncelik: string;
  durum: string;
  created_at: string;
  tamamlanma_tarihi: string | null;
}

export interface Sikayet {
  id: number;
  sikayet_eden_daire_id: number;
  sikayet_edilen_daire_id: number | null;
  baslik: string;
  aciklama: string;
  kategori: string;
  durum: string;
  created_at: string;
}

export interface OySecenek {
  id: number;
  metin: string;
  oy_sayisi: number;
}

export interface Oylama {
  id: number;
  baslik: string;
  aciklama: string;
  baslangic: string;
  bitis: string | null;
  durum: string;
  created_at: string;
  secenekler: OySecenek[];
  toplam_oy: number;
}

export interface Duyuru {
  id: number;
  baslik: string;
  icerik: string;
  oncelik: string;
  created_at: string;
}

export interface Gider {
  id: number;
  kategori: string;
  aciklama: string;
  tutar: number;
  tarih: string;
  belge_no: string;
  created_at: string;
}

export interface Toplanti {
  id: number;
  baslik: string;
  tarih: string;
  yer: string;
  ajanda: string;
  notlar: string;
  durum: string;
  created_at: string;
}

export interface DashboardStats {
  toplam_daire: number;
  dolu_daire: number;
  bos_daire: number;
  toplam_sakin: number;
  bu_ay_aidat_toplam: number;
  bu_ay_aidat_odenen: number;
  bu_ay_aidat_bekleyen: number;
  bekleyen_talep: number;
  acik_sikayet: number;
  aktif_oylama: number;
  bu_ay_gider: number;
  odenmemis_fatura: number;
}
