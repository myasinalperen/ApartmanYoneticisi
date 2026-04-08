# Apartman Yöneticisi

Türkiye'deki apartman yönetimini kolaylaştıran kapsamlı bir yönetim uygulaması.

## Özellikler

| Modül | Açıklama |
|-------|----------|
| **Panel** | Genel durum özeti, aidat tahsilat grafiği, bekleyen işler |
| **Daireler** | Daire listesi, blok/kat/no yönetimi, doluluk takibi |
| **Sakinler** | Ev sahibi ve kiracı kayıtları, iletişim bilgileri |
| **Aidatlar** | Aylık aidat takibi, toplu oluşturma, gecikme faizi |
| **Faturalar** | Elektrik, su, doğalgaz, asansör, temizlik faturaları |
| **Giderler** | Bina gider takibi, kategoriye göre dağılım |
| **Talepler** | Bakım/onarım talepleri, öncelik ve durum takibi |
| **Şikayetler** | Komşu şikayetleri, inceleme ve çözüm süreci |
| **Oylamalar** | Bina kararları için oylama sistemi |
| **Duyurular** | Acil ve genel duyurular |
| **Toplantılar** | Toplantı planlama, gündem ve notlar |

## Teknolojiler

- **Backend:** Python + FastAPI + SQLite
- **Frontend:** Flutter (Android, iOS, Web, Desktop)

## Kurulum ve Çalıştırma

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

API dökümanı: http://localhost:8000/docs

### Flutter Uygulaması

```bash
cd flutter_app
flutter pub get

# Web tarayıcı
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Örnek Veri Yükle

```bash
curl -X POST http://localhost:8000/seed
```

### Hızlı Başlat

```bash
./start.sh
```

## Proje Yapısı

```
ApartmanYoneticisi/
├── backend/                    # FastAPI backend
│   ├── main.py                 # Ana uygulama + Dashboard endpoint
│   ├── models.py               # SQLAlchemy modelleri
│   ├── schemas.py              # Pydantic şemaları
│   ├── database.py             # SQLite bağlantısı
│   └── routers/                # API rotaları
├── flutter_app/                # Flutter frontend
│   └── lib/
│       ├── main.dart           # Uygulama girişi + navigasyon
│       ├── models/             # Dart veri modelleri
│       ├── services/           # API servisi
│       ├── screens/            # Tüm ekranlar (11 adet)
│       └── widgets/            # Ortak bileşenler
└── start.sh                    # Hızlı başlatma scripti
```