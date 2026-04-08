from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date


# Daire
class DaireBase(BaseModel):
    blok: str = "A"
    kat: int
    daire_no: str
    tip: str = "2+1"
    metrekare: float = 100.0
    durum: str = "dolu"

class DaireCreate(DaireBase):
    pass

class DaireUpdate(BaseModel):
    blok: Optional[str] = None
    kat: Optional[int] = None
    daire_no: Optional[str] = None
    tip: Optional[str] = None
    metrekare: Optional[float] = None
    durum: Optional[str] = None

class DaireOut(DaireBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Sakin
class SakinBase(BaseModel):
    ad: str
    soyad: str
    telefon: Optional[str] = ""
    email: Optional[str] = ""
    daire_id: int
    tip: str = "kiracı"
    giris_tarihi: Optional[date] = None
    aktif: bool = True

class SakinCreate(SakinBase):
    pass

class SakinUpdate(BaseModel):
    ad: Optional[str] = None
    soyad: Optional[str] = None
    telefon: Optional[str] = None
    email: Optional[str] = None
    daire_id: Optional[int] = None
    tip: Optional[str] = None
    giris_tarihi: Optional[date] = None
    aktif: Optional[bool] = None

class SakinOut(SakinBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Aidat
class AidatBase(BaseModel):
    daire_id: int
    ay: int
    yil: int
    tutar: float
    odendi: bool = False
    odeme_tarihi: Optional[date] = None
    gecikme_faizi: float = 0.0

class AidatCreate(AidatBase):
    pass

class AidatUpdate(BaseModel):
    tutar: Optional[float] = None
    odendi: Optional[bool] = None
    odeme_tarihi: Optional[date] = None
    gecikme_faizi: Optional[float] = None

class AidatOut(AidatBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Fatura
class FaturaBase(BaseModel):
    tip: str
    ay: int
    yil: int
    tutar: float
    son_odeme_tarihi: Optional[date] = None
    odendi: bool = False
    aciklama: str = ""

class FaturaCreate(FaturaBase):
    pass

class FaturaUpdate(BaseModel):
    tip: Optional[str] = None
    ay: Optional[int] = None
    yil: Optional[int] = None
    tutar: Optional[float] = None
    son_odeme_tarihi: Optional[date] = None
    odendi: Optional[bool] = None
    aciklama: Optional[str] = None

class FaturaOut(FaturaBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Talep
class TalepBase(BaseModel):
    daire_id: int
    baslik: str
    aciklama: str = ""
    kategori: str = "teknik"
    oncelik: str = "orta"
    durum: str = "beklemede"

class TalepCreate(TalepBase):
    pass

class TalepUpdate(BaseModel):
    baslik: Optional[str] = None
    aciklama: Optional[str] = None
    kategori: Optional[str] = None
    oncelik: Optional[str] = None
    durum: Optional[str] = None
    tamamlanma_tarihi: Optional[datetime] = None

class TalepOut(TalepBase):
    id: int
    created_at: datetime
    tamamlanma_tarihi: Optional[datetime] = None
    class Config:
        from_attributes = True


# Sikayet
class SikayetBase(BaseModel):
    sikayet_eden_daire_id: int
    sikayet_edilen_daire_id: Optional[int] = None
    baslik: str
    aciklama: str = ""
    kategori: str = "diger"
    durum: str = "acik"

class SikayetCreate(SikayetBase):
    pass

class SikayetUpdate(BaseModel):
    baslik: Optional[str] = None
    aciklama: Optional[str] = None
    kategori: Optional[str] = None
    durum: Optional[str] = None

class SikayetOut(SikayetBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Oylama
class OySecenekCreate(BaseModel):
    metin: str

class OylamaBaze(BaseModel):
    baslik: str
    aciklama: str = ""
    bitis: Optional[datetime] = None
    durum: str = "aktif"

class OylamaCreate(OylamaBaze):
    secenekler: List[str] = []

class OylamaUpdate(BaseModel):
    baslik: Optional[str] = None
    aciklama: Optional[str] = None
    bitis: Optional[datetime] = None
    durum: Optional[str] = None

class OySecenekOut(BaseModel):
    id: int
    metin: str
    oy_sayisi: int = 0
    class Config:
        from_attributes = True

class OylamaOut(OylamaBaze):
    id: int
    baslangic: datetime
    created_at: datetime
    secenekler: List[OySecenekOut] = []
    toplam_oy: int = 0
    class Config:
        from_attributes = True

class OyCreate(BaseModel):
    oylama_id: int
    daire_id: int
    secenek_id: int


# Duyuru
class DuyuruBase(BaseModel):
    baslik: str
    icerik: str = ""
    oncelik: str = "normal"

class DuyuruCreate(DuyuruBase):
    pass

class DuyuruUpdate(BaseModel):
    baslik: Optional[str] = None
    icerik: Optional[str] = None
    oncelik: Optional[str] = None

class DuyuruOut(DuyuruBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Gider
class GiderBase(BaseModel):
    kategori: str = "diger"
    aciklama: str
    tutar: float
    tarih: date
    belge_no: str = ""

class GiderCreate(GiderBase):
    pass

class GiderUpdate(BaseModel):
    kategori: Optional[str] = None
    aciklama: Optional[str] = None
    tutar: Optional[float] = None
    tarih: Optional[date] = None
    belge_no: Optional[str] = None

class GiderOut(GiderBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Toplanti
class ToplantiBase(BaseModel):
    baslik: str
    tarih: datetime
    yer: str = "Apartman Girişi"
    ajanda: str = ""
    notlar: str = ""
    durum: str = "planlandı"

class ToplantiCreate(ToplantiBase):
    pass

class ToplantiUpdate(BaseModel):
    baslik: Optional[str] = None
    tarih: Optional[datetime] = None
    yer: Optional[str] = None
    ajanda: Optional[str] = None
    notlar: Optional[str] = None
    durum: Optional[str] = None

class ToplantiOut(ToplantiBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True


# Dashboard
class DashboardStats(BaseModel):
    toplam_daire: int
    dolu_daire: int
    bos_daire: int
    toplam_sakin: int
    bu_ay_aidat_toplam: float
    bu_ay_aidat_odenen: float
    bu_ay_aidat_bekleyen: float
    bekleyen_talep: int
    acik_sikayet: int
    aktif_oylama: int
    bu_ay_gider: float
    odenmemis_fatura: int
