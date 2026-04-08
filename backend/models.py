from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text, Date
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base


class Daire(Base):
    __tablename__ = "daireler"

    id = Column(Integer, primary_key=True, index=True)
    blok = Column(String, default="A")
    kat = Column(Integer, nullable=False)
    daire_no = Column(String, nullable=False)
    tip = Column(String, default="2+1")  # 1+1, 2+1, 3+1, 4+1
    metrekare = Column(Float, default=100.0)
    durum = Column(String, default="dolu")  # dolu, bos
    created_at = Column(DateTime, default=datetime.utcnow)

    sakinler = relationship("Sakin", back_populates="daire")
    aidatlar = relationship("Aidat", back_populates="daire")
    talepler = relationship("Talep", back_populates="daire")
    sikayetler = relationship("Sikayet", back_populates="sikayet_eden_daire", foreign_keys="Sikayet.sikayet_eden_daire_id")


class Sakin(Base):
    __tablename__ = "sakinler"

    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String, nullable=False)
    soyad = Column(String, nullable=False)
    telefon = Column(String)
    email = Column(String)
    daire_id = Column(Integer, ForeignKey("daireler.id"))
    tip = Column(String, default="kiracı")  # ev_sahibi, kiracı
    giris_tarihi = Column(Date)
    aktif = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    daire = relationship("Daire", back_populates="sakinler")


class Aidat(Base):
    __tablename__ = "aidatlar"

    id = Column(Integer, primary_key=True, index=True)
    daire_id = Column(Integer, ForeignKey("daireler.id"))
    ay = Column(Integer, nullable=False)   # 1-12
    yil = Column(Integer, nullable=False)
    tutar = Column(Float, nullable=False)
    odendi = Column(Boolean, default=False)
    odeme_tarihi = Column(Date, nullable=True)
    gecikme_faizi = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)

    daire = relationship("Daire", back_populates="aidatlar")


class Fatura(Base):
    __tablename__ = "faturalar"

    id = Column(Integer, primary_key=True, index=True)
    tip = Column(String, nullable=False)  # elektrik, su, dogalgaz, asansor, temizlik, internet, diger
    ay = Column(Integer, nullable=False)
    yil = Column(Integer, nullable=False)
    tutar = Column(Float, nullable=False)
    son_odeme_tarihi = Column(Date, nullable=True)
    odendi = Column(Boolean, default=False)
    aciklama = Column(Text, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class Talep(Base):
    __tablename__ = "talepler"

    id = Column(Integer, primary_key=True, index=True)
    daire_id = Column(Integer, ForeignKey("daireler.id"))
    baslik = Column(String, nullable=False)
    aciklama = Column(Text, default="")
    kategori = Column(String, default="teknik")  # tadilat, temizlik, teknik, guvenlik, diger
    oncelik = Column(String, default="orta")  # dusuk, orta, yuksek, acil
    durum = Column(String, default="beklemede")  # beklemede, isleniyor, tamamlandi, iptal
    created_at = Column(DateTime, default=datetime.utcnow)
    tamamlanma_tarihi = Column(DateTime, nullable=True)

    daire = relationship("Daire", back_populates="talepler")


class Sikayet(Base):
    __tablename__ = "sikayetler"

    id = Column(Integer, primary_key=True, index=True)
    sikayet_eden_daire_id = Column(Integer, ForeignKey("daireler.id"))
    sikayet_edilen_daire_id = Column(Integer, ForeignKey("daireler.id"), nullable=True)
    baslik = Column(String, nullable=False)
    aciklama = Column(Text, default="")
    kategori = Column(String, default="diger")  # gurultu, temizlik, park, evcil_hayvan, diger
    durum = Column(String, default="acik")  # acik, inceleniyor, cozuldu, kapandi
    created_at = Column(DateTime, default=datetime.utcnow)

    sikayet_eden_daire = relationship("Daire", back_populates="sikayetler", foreign_keys=[sikayet_eden_daire_id])


class Oylama(Base):
    __tablename__ = "oylamalar"

    id = Column(Integer, primary_key=True, index=True)
    baslik = Column(String, nullable=False)
    aciklama = Column(Text, default="")
    baslangic = Column(DateTime, default=datetime.utcnow)
    bitis = Column(DateTime, nullable=True)
    durum = Column(String, default="aktif")  # aktif, tamamlandi, iptal
    created_at = Column(DateTime, default=datetime.utcnow)

    secenekler = relationship("OySecenek", back_populates="oylama", cascade="all, delete-orphan")
    oylar = relationship("Oy", back_populates="oylama", cascade="all, delete-orphan")


class OySecenek(Base):
    __tablename__ = "oy_secenekler"

    id = Column(Integer, primary_key=True, index=True)
    oylama_id = Column(Integer, ForeignKey("oylamalar.id"))
    metin = Column(String, nullable=False)

    oylama = relationship("Oylama", back_populates="secenekler")
    oylar = relationship("Oy", back_populates="secenek")


class Oy(Base):
    __tablename__ = "oylar"

    id = Column(Integer, primary_key=True, index=True)
    oylama_id = Column(Integer, ForeignKey("oylamalar.id"))
    daire_id = Column(Integer, ForeignKey("daireler.id"))
    secenek_id = Column(Integer, ForeignKey("oy_secenekler.id"))
    tarih = Column(DateTime, default=datetime.utcnow)

    oylama = relationship("Oylama", back_populates="oylar")
    secenek = relationship("OySecenek", back_populates="oylar")


class Duyuru(Base):
    __tablename__ = "duyurular"

    id = Column(Integer, primary_key=True, index=True)
    baslik = Column(String, nullable=False)
    icerik = Column(Text, default="")
    oncelik = Column(String, default="normal")  # normal, onemli, acil
    created_at = Column(DateTime, default=datetime.utcnow)


class Gider(Base):
    __tablename__ = "giderler"

    id = Column(Integer, primary_key=True, index=True)
    kategori = Column(String, default="diger")  # bakim, temizlik, elektrik, su, dogalgaz, asansor, guvenlik, diger
    aciklama = Column(Text, nullable=False)
    tutar = Column(Float, nullable=False)
    tarih = Column(Date, nullable=False)
    belge_no = Column(String, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class Toplanti(Base):
    __tablename__ = "toplantilar"

    id = Column(Integer, primary_key=True, index=True)
    baslik = Column(String, nullable=False)
    tarih = Column(DateTime, nullable=False)
    yer = Column(String, default="Apartman Girişi")
    ajanda = Column(Text, default="")
    notlar = Column(Text, default="")
    durum = Column(String, default="planlandı")  # planlandı, tamamlandı, iptal
    created_at = Column(DateTime, default=datetime.utcnow)
