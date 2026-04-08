from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime, date
from database import engine, get_db, Base
import models, schemas
from routers import daireler, sakinler, aidatlar, faturalar, talepler, sikayetler, oylamalar, duyurular, giderler, toplantilar

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Apartman Yöneticisi", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(daireler.router)
app.include_router(sakinler.router)
app.include_router(aidatlar.router)
app.include_router(faturalar.router)
app.include_router(talepler.router)
app.include_router(sikayetler.router)
app.include_router(oylamalar.router)
app.include_router(duyurular.router)
app.include_router(giderler.router)
app.include_router(toplantilar.router)


@app.get("/dashboard", response_model=schemas.DashboardStats)
def dashboard(db: Session = Depends(get_db)):
    now = datetime.utcnow()
    ay, yil = now.month, now.year

    toplam_daire = db.query(models.Daire).count()
    dolu_daire = db.query(models.Daire).filter(models.Daire.durum == "dolu").count()
    bos_daire = db.query(models.Daire).filter(models.Daire.durum == "bos").count()
    toplam_sakin = db.query(models.Sakin).filter(models.Sakin.aktif == True).count()

    bu_ay_aidatlar = db.query(models.Aidat).filter(models.Aidat.ay == ay, models.Aidat.yil == yil).all()
    bu_ay_aidat_toplam = sum(a.tutar for a in bu_ay_aidatlar)
    bu_ay_aidat_odenen = sum(a.tutar for a in bu_ay_aidatlar if a.odendi)
    bu_ay_aidat_bekleyen = sum(a.tutar + a.gecikme_faizi for a in bu_ay_aidatlar if not a.odendi)

    bekleyen_talep = db.query(models.Talep).filter(
        models.Talep.durum.in_(["beklemede", "isleniyor"])
    ).count()
    acik_sikayet = db.query(models.Sikayet).filter(
        models.Sikayet.durum.in_(["acik", "inceleniyor"])
    ).count()
    aktif_oylama = db.query(models.Oylama).filter(models.Oylama.durum == "aktif").count()

    bu_ay_gider_kayitlar = db.query(models.Gider).filter(
        models.Gider.tarih >= date(yil, ay, 1)
    ).all()
    bu_ay_gider = sum(g.tutar for g in bu_ay_gider_kayitlar)

    odenmemis_fatura = db.query(models.Fatura).filter(models.Fatura.odendi == False).count()

    return schemas.DashboardStats(
        toplam_daire=toplam_daire,
        dolu_daire=dolu_daire,
        bos_daire=bos_daire,
        toplam_sakin=toplam_sakin,
        bu_ay_aidat_toplam=bu_ay_aidat_toplam,
        bu_ay_aidat_odenen=bu_ay_aidat_odenen,
        bu_ay_aidat_bekleyen=bu_ay_aidat_bekleyen,
        bekleyen_talep=bekleyen_talep,
        acik_sikayet=acik_sikayet,
        aktif_oylama=aktif_oylama,
        bu_ay_gider=bu_ay_gider,
        odenmemis_fatura=odenmemis_fatura,
    )


@app.post("/seed")
def seed_database(db: Session = Depends(get_db)):
    if db.query(models.Daire).count() > 0:
        return {"message": "Veritabanı zaten dolu"}

    # Daireler
    daireler_data = [
        {"blok": "A", "kat": 1, "daire_no": "1", "tip": "2+1", "metrekare": 85.0, "durum": "dolu"},
        {"blok": "A", "kat": 1, "daire_no": "2", "tip": "3+1", "metrekare": 110.0, "durum": "dolu"},
        {"blok": "A", "kat": 2, "daire_no": "3", "tip": "2+1", "metrekare": 85.0, "durum": "dolu"},
        {"blok": "A", "kat": 2, "daire_no": "4", "tip": "1+1", "metrekare": 60.0, "durum": "bos"},
        {"blok": "A", "kat": 3, "daire_no": "5", "tip": "3+1", "metrekare": 110.0, "durum": "dolu"},
        {"blok": "A", "kat": 3, "daire_no": "6", "tip": "2+1", "metrekare": 85.0, "durum": "dolu"},
        {"blok": "B", "kat": 1, "daire_no": "7", "tip": "2+1", "metrekare": 90.0, "durum": "dolu"},
        {"blok": "B", "kat": 1, "daire_no": "8", "tip": "3+1", "metrekare": 115.0, "durum": "dolu"},
        {"blok": "B", "kat": 2, "daire_no": "9", "tip": "2+1", "metrekare": 90.0, "durum": "bos"},
        {"blok": "B", "kat": 2, "daire_no": "10", "tip": "4+1", "metrekare": 145.0, "durum": "dolu"},
    ]
    daire_objs = []
    for d in daireler_data:
        obj = models.Daire(**d)
        db.add(obj)
        daire_objs.append(obj)
    db.flush()

    # Sakinler
    sakinler_data = [
        {"ad": "Ahmet", "soyad": "Yılmaz", "telefon": "0532 111 2233", "email": "ahmet@email.com", "daire_id": daire_objs[0].id, "tip": "ev_sahibi", "giris_tarihi": date(2020, 3, 1)},
        {"ad": "Fatma", "soyad": "Kaya", "telefon": "0533 222 3344", "email": "fatma@email.com", "daire_id": daire_objs[1].id, "tip": "kiracı", "giris_tarihi": date(2022, 6, 15)},
        {"ad": "Mehmet", "soyad": "Demir", "telefon": "0535 333 4455", "email": "mehmet@email.com", "daire_id": daire_objs[2].id, "tip": "ev_sahibi", "giris_tarihi": date(2019, 1, 10)},
        {"ad": "Ayşe", "soyad": "Çelik", "telefon": "0536 444 5566", "email": "ayse@email.com", "daire_id": daire_objs[4].id, "tip": "kiracı", "giris_tarihi": date(2023, 2, 1)},
        {"ad": "Ali", "soyad": "Şahin", "telefon": "0537 555 6677", "email": "ali@email.com", "daire_id": daire_objs[5].id, "tip": "ev_sahibi", "giris_tarihi": date(2021, 8, 20)},
        {"ad": "Zeynep", "soyad": "Arslan", "telefon": "0538 666 7788", "email": "zeynep@email.com", "daire_id": daire_objs[6].id, "tip": "kiracı", "giris_tarihi": date(2023, 9, 5)},
        {"ad": "Mustafa", "soyad": "Koç", "telefon": "0539 777 8899", "email": "mustafa@email.com", "daire_id": daire_objs[7].id, "tip": "ev_sahibi", "giris_tarihi": date(2018, 5, 12)},
        {"ad": "Elif", "soyad": "Kurt", "telefon": "0530 888 9900", "email": "elif@email.com", "daire_id": daire_objs[9].id, "tip": "kiracı", "giris_tarihi": date(2024, 1, 15)},
    ]
    for s in sakinler_data:
        db.add(models.Sakin(**s))
    db.flush()

    # Aidatlar (Mart ve Nisan 2026)
    for daire in daire_objs:
        if daire.durum == "dolu":
            tutar = 750.0 if daire.tip in ["1+1", "2+1"] else 1000.0
            # Mart - ödendi
            db.add(models.Aidat(daire_id=daire.id, ay=3, yil=2026, tutar=tutar, odendi=True, odeme_tarihi=date(2026, 3, 5)))
            # Nisan - bazıları ödendi
            import random
            odendi = random.choice([True, False])
            db.add(models.Aidat(
                daire_id=daire.id, ay=4, yil=2026, tutar=tutar,
                odendi=odendi,
                odeme_tarihi=date(2026, 4, 3) if odendi else None
            ))

    # Faturalar
    faturalar_data = [
        {"tip": "elektrik", "ay": 4, "yil": 2026, "tutar": 3250.0, "son_odeme_tarihi": date(2026, 4, 20), "odendi": False, "aciklama": "Ortak alan elektrik faturası"},
        {"tip": "su", "ay": 4, "yil": 2026, "tutar": 1850.0, "son_odeme_tarihi": date(2026, 4, 25), "odendi": False, "aciklama": "ASKI su faturası"},
        {"tip": "dogalgaz", "ay": 3, "yil": 2026, "tutar": 4200.0, "son_odeme_tarihi": date(2026, 3, 30), "odendi": True, "aciklama": "Merkezi ısıtma"},
        {"tip": "asansor", "ay": 4, "yil": 2026, "tutar": 800.0, "son_odeme_tarihi": date(2026, 4, 15), "odendi": False, "aciklama": "Aylık bakım ücreti"},
        {"tip": "temizlik", "ay": 4, "yil": 2026, "tutar": 2500.0, "son_odeme_tarihi": date(2026, 4, 10), "odendi": True, "aciklama": "Temizlik şirketi"},
        {"tip": "internet", "ay": 3, "yil": 2026, "tutar": 450.0, "son_odeme_tarihi": date(2026, 3, 20), "odendi": True, "aciklama": "Ortak wifi"},
    ]
    for f in faturalar_data:
        db.add(models.Fatura(**f))

    # Talepler
    talepler_data = [
        {"daire_id": daire_objs[0].id, "baslik": "Mutfak lavabo sızıntısı", "aciklama": "Lavabonun altında su birikintisi oluşuyor, acil müdahale gerekiyor.", "kategori": "teknik", "oncelik": "yuksek", "durum": "isleniyor"},
        {"daire_id": daire_objs[2].id, "baslik": "Kapı kilidi değişimi", "aciklama": "Daire kapısının kilidi bozulmuş, yenilenmesi gerekiyor.", "kategori": "guvenlik", "oncelik": "orta", "durum": "beklemede"},
        {"daire_id": daire_objs[4].id, "baslik": "Boyama talep", "aciklama": "Salon duvarlarında nem sonrası boya dökülmesi var.", "kategori": "tadilat", "oncelik": "dusuk", "durum": "beklemede"},
        {"daire_id": daire_objs[6].id, "baslik": "Balkon tamiratı", "aciklama": "Balkon korkulukları paslanmış ve tehlikeli görünüyor.", "kategori": "teknik", "oncelik": "acil", "durum": "isleniyor"},
        {"daire_id": daire_objs[1].id, "baslik": "Kombi arızası", "aciklama": "Kombi çalışmıyor, sıcak su yok.", "kategori": "teknik", "oncelik": "acil", "durum": "tamamlandi", "tamamlanma_tarihi": datetime(2026, 3, 28)},
    ]
    for t in talepler_data:
        obj = models.Talep(
            daire_id=t["daire_id"], baslik=t["baslik"], aciklama=t["aciklama"],
            kategori=t["kategori"], oncelik=t["oncelik"], durum=t["durum"]
        )
        if "tamamlanma_tarihi" in t:
            obj.tamamlanma_tarihi = t["tamamlanma_tarihi"]
        db.add(obj)

    # Sikayetler
    sikayetler_data = [
        {"sikayet_eden_daire_id": daire_objs[0].id, "sikayet_edilen_daire_id": daire_objs[1].id, "baslik": "Gece geç saatte gürültü", "aciklama": "Her gece saat 23:00'dan sonra müzik ve bağırma sesi geliyor.", "kategori": "gurultu", "durum": "inceleniyor"},
        {"sikayet_eden_daire_id": daire_objs[3].id, "sikayet_edilen_daire_id": None, "baslik": "Merdiven temizliği yapılmıyor", "aciklama": "Ortak kullanım alanları yeterince temizlenmiyor.", "kategori": "temizlik", "durum": "acik"},
        {"sikayet_eden_daire_id": daire_objs[5].id, "sikayet_edilen_daire_id": daire_objs[6].id, "baslik": "Yasak yere park", "aciklama": "Komşunun misafirleri engelli park yerine araç bırakıyor.", "kategori": "park", "durum": "cozuldu"},
    ]
    for s in sikayetler_data:
        db.add(models.Sikayet(**s))

    # Oylamalar
    oylama1 = models.Oylama(
        baslik="Güvenlik kamerası kurulumu",
        aciklama="Bina girişine ve otoparka güvenlik kamerası kurulması konusunda oy kullanın.",
        durum="aktif",
        bitis=datetime(2026, 4, 30)
    )
    db.add(oylama1)
    db.flush()
    s1 = models.OySecenek(oylama_id=oylama1.id, metin="Evet, kurulsun")
    s2 = models.OySecenek(oylama_id=oylama1.id, metin="Hayır, gerek yok")
    s3 = models.OySecenek(oylama_id=oylama1.id, metin="Sadece giriş için")
    db.add_all([s1, s2, s3])
    db.flush()
    db.add(models.Oy(oylama_id=oylama1.id, daire_id=daire_objs[0].id, secenek_id=s1.id))
    db.add(models.Oy(oylama_id=oylama1.id, daire_id=daire_objs[1].id, secenek_id=s1.id))
    db.add(models.Oy(oylama_id=oylama1.id, daire_id=daire_objs[2].id, secenek_id=s3.id))

    oylama2 = models.Oylama(
        baslik="Kapıcı dairesi kararı",
        aciklama="Boş olan kapıcı dairesinin kiralık olarak değerlendirilmesi oylanıyor.",
        durum="tamamlandi",
        bitis=datetime(2026, 3, 15)
    )
    db.add(oylama2)
    db.flush()
    s4 = models.OySecenek(oylama_id=oylama2.id, metin="Kiraya verilsin")
    s5 = models.OySecenek(oylama_id=oylama2.id, metin="Depo olarak kullanılsın")
    db.add_all([s4, s5])
    db.flush()
    for i in range(6):
        db.add(models.Oy(oylama_id=oylama2.id, daire_id=daire_objs[i].id, secenek_id=s4.id))
    for i in range(6, 8):
        db.add(models.Oy(oylama_id=oylama2.id, daire_id=daire_objs[i].id, secenek_id=s5.id))

    # Duyurular
    duyurular_data = [
        {"baslik": "Nisan ayı aidat hatırlatması", "icerik": "Nisan 2026 aidat ödemelerinin son günü 10 Nisan'dır. Geç ödemelerde aylık %2 gecikme faizi uygulanacaktır.", "oncelik": "onemli"},
        {"baslik": "Su kesintisi bildirimi", "icerik": "8 Nisan 2026 Çarşamba günü saat 09:00-17:00 arasında tüm binada su kesintisi yaşanacaktır. Lütfen gerekli tedbirlerinizi alın.", "oncelik": "acil"},
        {"baslik": "Bina genel temizliği", "icerik": "15 Nisan 2026 tarihinde bina genel temizliği yapılacaktır. Merdiven sahanlıklarına eşya bırakılmaması rica olunur.", "oncelik": "normal"},
        {"baslik": "Yönetim toplantısı hatırlatması", "icerik": "Bu ay ki yönetim toplantımız 20 Nisan 2026 Pazartesi saat 19:00'da yapılacaktır. Tüm sakinlerin katılımını bekliyoruz.", "oncelik": "normal"},
    ]
    for d in duyurular_data:
        db.add(models.Duyuru(**d))

    # Giderler
    giderler_data = [
        {"kategori": "temizlik", "aciklama": "Nisan temizlik şirketi ödemesi", "tutar": 2500.0, "tarih": date(2026, 4, 1), "belge_no": "F-2026-041"},
        {"kategori": "bakim", "aciklama": "Asansör yıllık bakım sözleşmesi", "tutar": 9600.0, "tarih": date(2026, 1, 15), "belge_no": "F-2026-015"},
        {"kategori": "elektrik", "aciklama": "Mart ayı elektrik faturası ödemesi", "tutar": 3100.0, "tarih": date(2026, 3, 25), "belge_no": "E-26031"},
        {"kategori": "su", "aciklama": "Mart ayı su faturası", "tutar": 1750.0, "tarih": date(2026, 3, 28), "belge_no": "S-26031"},
        {"kategori": "guvenlik", "aciklama": "Güvenlik görevlisi Mart ücreti", "tutar": 18500.0, "tarih": date(2026, 3, 31), "belge_no": "HR-031"},
        {"kategori": "diger", "aciklama": "Bahçe sulama sistemi tamiri", "tutar": 850.0, "tarih": date(2026, 4, 5), "belge_no": "T-2026-042"},
    ]
    for g in giderler_data:
        db.add(models.Gider(**g))

    # Toplantılar
    toplantilar_data = [
        {"baslik": "Nisan Olağan Yönetim Toplantısı", "tarih": datetime(2026, 4, 20, 19, 0), "yer": "Apartman Toplantı Salonu", "ajanda": "1. Açılış ve yoklama\n2. Nisan ayı bütçe değerlendirmesi\n3. Güvenlik kamerası kararı\n4. Dilek ve öneriler", "notlar": "", "durum": "planlandı"},
        {"baslik": "Mart Olağan Yönetim Toplantısı", "tarih": datetime(2026, 3, 18, 19, 0), "yer": "Apartman Toplantı Salonu", "ajanda": "1. Açılış\n2. Şubat ayı hesap özeti\n3. Kapıcı dairesi oylaması sonucu\n4. Yaz bakım planı", "notlar": "Toplantıya 7 daire katıldı. Kapıcı dairesi kiraya verilmesi kararlaştırıldı.", "durum": "tamamlandı"},
    ]
    for t in toplantilar_data:
        db.add(models.Toplanti(**t))

    db.commit()
    return {"message": "Örnek veriler başarıyla eklendi"}


@app.get("/")
def root():
    return {"message": "Apartman Yöneticisi API'ye hoş geldiniz", "version": "1.0.0"}
