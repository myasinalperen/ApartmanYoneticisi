#!/bin/bash
# Apartman Yöneticisi - Başlatma Scripti

echo "🏢 Apartman Yöneticisi başlatılıyor..."

# Backend'i arka planda başlat
echo "📡 Backend (FastAPI) başlatılıyor... http://localhost:8000"
cd "$(dirname "$0")/backend"
uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Örnek veri yükle (isteğe bağlı)
sleep 2
curl -s -X POST http://localhost:8000/seed > /dev/null 2>&1
echo "✅ Örnek veriler yüklendi"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Backend API:     http://localhost:8000"
echo "  API Docs:        http://localhost:8000/docs"
echo ""
echo "  Flutter uygulamasını başlatmak için:"
echo "  cd flutter_app && flutter run -d chrome"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Durdurmak için Ctrl+C"

wait $BACKEND_PID
