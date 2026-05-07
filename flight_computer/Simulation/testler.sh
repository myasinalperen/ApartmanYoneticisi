#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  IHA Uçuş Bilgisayarı – Ana Test Scripti
#
#  Kullanım:
#    bash testler.sh            → Tüm yazılım testleri
#    bash testler.sh --donanim → Adım adım donanım rehberi
#    bash testler.sh --kurulum → Önce setup.sh çalıştır
# ─────────────────────────────────────────────────────────────

DIR="$(cd "$(dirname "$0")" && pwd)"
BOLD="\033[1m"; GRN="\033[92m"; RED="\033[91m"
YLW="\033[93m"; CYN="\033[96m"; RST="\033[0m"

print_header() {
    echo -e "\n${BOLD}${CYN}╔══════════════════════════════════════════════════╗${RST}"
    echo -e "${BOLD}${CYN}║  IHA Uçuş Bilgisayarı – Test Sistemi            ║${RST}"
    echo -e "${BOLD}${CYN}╚══════════════════════════════════════════════════╝${RST}\n"
}

# ── Kullanılacak portlar meşgul mu? ────────────────────────
check_ports() {
    local busy=0
    for port in 5500 5501 5502 5503; do
        if ss -uln 2>/dev/null | grep -q ":$port " || \
           netstat -uln 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${YLW}⚠  Port $port zaten kullanımda.${RST}"
            busy=1
        fi
    done
    if [ $busy -eq 1 ]; then
        echo -e "  ${YLW}Eski sim_fc süreci kapatılıyor...${RST}"
        pkill -f sim_fc 2>/dev/null || true
        sleep 1
    fi
}

# ════════════════════════════════════════════════════════════
#  YAZILIM TESTLERİ (Otomatik)
# ════════════════════════════════════════════════════════════
run_software_tests() {
    print_header
    echo -e "${BOLD}▶ Aşama 1/3: Kurulum ve derleme${RST}"

    cd "$DIR"

    # sim_fc yok ise derle
    if [ ! -f "./sim_fc" ]; then
        echo "  sim_fc bulunamadı, derleniyor..."
        if ! make &>/dev/null; then
            echo -e "${RED}  ✘ Derleme başarısız! 'bash setup.sh' ile önce kurulumu yap.${RST}"
            exit 1
        fi
    fi
    echo -e "  ${GRN}✔  sim_fc hazır${RST}"

    check_ports

    echo -e "\n${BOLD}▶ Aşama 2/3: Otomatik yazılım testleri${RST}"
    echo -e "  7 test senaryosu çalıştırılacak (~30 saniye)...\n"

    python3 "$DIR/test_runner.py"
    EXIT_CODE=$?

    echo -e "\n${BOLD}▶ Aşama 3/3: Sonuç${RST}"
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GRN}${BOLD}"
        echo "  ╔══════════════════════════════════════╗"
        echo "  ║  TÜM YAZILIM TESTLERİ BAŞARILI ✔    ║"
        echo "  ║                                      ║"
        echo "  ║  Sonraki adım: Donanım testi         ║"
        echo "  ║  → bash testler.sh --donanim         ║"
        echo "  ╚══════════════════════════════════════╝"
        echo -e "${RST}"
    else
        echo -e "${RED}${BOLD}"
        echo "  ╔══════════════════════════════════════╗"
        echo "  ║  BAZI TESTLER BAŞARISIZ  ✘           ║"
        echo "  ║                                      ║"
        echo "  ║  Donanım testine geçme!              ║"
        echo "  ║  Önce yazılım sorunlarını düzelt.    ║"
        echo "  ╚══════════════════════════════════════╝"
        echo -e "${RST}"
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════
#  DONANIM REHBERİ (Adım adım, kullanıcı onaylı)
# ════════════════════════════════════════════════════════════
adim() {
    local no="$1" baslik="$2"
    echo -e "\n${BOLD}${CYN}━━━ ADIM $no ━━━ $baslik${RST}"
}

bekle() {
    echo -e "\n  ${YLW}↵  Hazır olduğunda ENTER'a bas...${RST}"
    read -r
}

sor() {
    # sor "Soru?" → 'e' veya 'h' döner
    local cevap=""
    echo -e "  ${BOLD}$1 [e/h]:${RST} \c"
    read -r cevap
    [ "$cevap" = "e" ] || [ "$cevap" = "E" ]
}

run_hardware_guide() {
    print_header
    echo -e "${BOLD}${YLW}  ⚠  DONANIM TESTİ REHBERİ${RST}"
    echo -e "  Bu test gerçek STM32 kartı gerektirir."
    echo -e "  PERVANE TAKMADAN devam et!\n"
    bekle

    # ── ADIM 1: Yazılım testleri geçildi mi? ───────────────
    adim 1 "Yazılım testleri onayı"
    echo "  Bu rehbere başlamadan önce yazılım testlerinin"
    echo "  tamamı GEÇTI olmalıdır."
    if sor "  bash testler.sh ile tüm testler GEÇTI mi?"; then
        echo -e "  ${GRN}✔  Devam ediliyor${RST}"
    else
        echo -e "  ${RED}✘  Önce 'bash testler.sh' ile yazılım testlerini geç!${RST}"
        exit 1
    fi

    # ── ADIM 2: STM32 kurulum ortamı ───────────────────────
    adim 2 "STM32CubeIDE Kurulumu"
    echo "  STM32F407'ye kodu yüklemek için gerekli:"
    echo ""
    echo "  1. https://www.st.com/en/development-tools/stm32cubeide.html"
    echo "     adresine gir ve STM32CubeIDE'yi indir (ücretsiz)"
    echo ""
    echo "  2. Kur ve aç"
    echo ""
    echo "  3. Yeni proje oluştur:"
    echo "     File → New → STM32 Project"
    echo "     Arama kutusuna 'STM32F407VG' yaz → seç → Finish"
    echo ""
    echo "  4. flight_computer/Core/ klasörünü projeye ekle"
    echo "     (Drivers klasörü de dahil)"
    bekle

    # ── ADIM 3: Bağlantı ───────────────────────────────────
    adim 3 "Donanım Bağlantıları"
    echo "  Bağlantı şemasını aç:"
    echo "    cat '$DIR/../docs/wiring.txt'"
    echo ""
    echo "  Şu anda SADECE şunları bağla (motoru bağlama!):"
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  STM32F407       Modül                      │"
    echo "  │  ─────────────   ─────────────────────────  │"
    echo "  │  PB8             MPU6050 SCL                │"
    echo "  │  PB9             MPU6050 SDA                │"
    echo "  │  3.3V            MPU6050 VCC                │"
    echo "  │  GND             MPU6050 GND                │"
    echo "  │  PA3             GPS TX                     │"
    echo "  │  3.3V/5V         GPS VCC                    │"
    echo "  │  GND             GPS GND                    │"
    echo "  │  PA10            RC Alıcı iBUS pini         │"
    echo "  │  5V (USB/BEC)    RC Alıcı VCC              │"
    echo "  │  GND             RC Alıcı GND              │"
    echo "  │  PE9             Servo 1 Sinyal             │"
    echo "  │  PE11            Servo 2 Sinyal             │"
    echo "  │  PE13            Servo 3 Sinyal             │"
    echo "  │  PE14            Servo 4 Sinyal             │"
    echo "  │  5V (BEC)        Servo VCC (×4)            │"
    echo "  │  GND             Servo GND (×4)            │"
    echo "  └─────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${RED}${BOLD}  ⚠  ESC ve motoru HENÜZ bağlama!${RST}"
    bekle

    # ── ADIM 4: Seri port testi ─────────────────────────────
    adim 4 "Seri Port Bağlantısı"
    echo "  STM32'yi USB ile bilgisayara bağla."
    echo "  ST-Link veya USB-UART (PA2/PA3 → USB adaptör) kullan."
    echo ""
    echo "  Portu bul:"
    if ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -5; then
        echo ""
    else
        echo "  (Port görünmüyorsa ST-Link sürücüsü eksik olabilir)"
    fi
    echo ""
    echo "  Seri port izlemek için (115200 baud):"
    echo "    minicom -b 115200 -D /dev/ttyUSB0"
    echo "    veya: screen /dev/ttyUSB0 115200"
    bekle

    # ── ADIM 5: Kod yükleme ─────────────────────────────────
    adim 5 "Kodu STM32'ye Yükle"
    echo "  STM32CubeIDE'de:"
    echo "  1. Projeyi aç"
    echo "  2. Build (Ctrl+B) → hata yoksa devam"
    echo "  3. Run → Run As → STM32 Cortex-M C/C++ Application"
    echo "  4. Seri portta şunu görmelisin:"
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  (telemetri mesajları geliyorsa TAMAM)  │"
    echo "  └─────────────────────────────────────────┘"
    bekle

    # ── ADIM 6: IMU testi ───────────────────────────────────
    adim 6 "IMU Doğrulama (Madgwick Filtresi)"
    echo "  Seri portu aç, kartı elle yatır:"
    echo ""
    echo "  Test A: Kart düz masada"
    echo "    Beklenti: R:~0° P:~0°"
    if sor "    R ve P değerleri ±5° içinde mi?"; then
        echo -e "    ${GRN}✔  GEÇTI${RST}"
    else
        echo -e "    ${RED}✘  KALDI – MPU6050 bağlantısını kontrol et (SDA/SCL)${RST}"
        bekle
    fi

    echo ""
    echo "  Test B: Kartı sağa 45° yatır"
    echo "    Beklenti: R: +40°..+50°"
    if sor "    Roll değeri +40° ile +50° arasında mı?"; then
        echo -e "    ${GRN}✔  GEÇTI${RST}"
    else
        echo -e "    ${YLW}  Ters çıkıyorsa: imu.c'de eksen yönünü değiştir${RST}"
    fi
    bekle

    # ── ADIM 7: RC testi ────────────────────────────────────
    adim 7 "RC Alıcı Testi"
    echo "  RC kumandayı aç. Alıcı LED'i yanıp sönmeli."
    echo ""
    echo "  Seri portta RC: VAR / YOK görünümünü izle."
    if sor "  RC: VAR yazısı çıkıyor mu?"; then
        echo -e "  ${GRN}✔  RC bağlantısı tamam${RST}"
    else
        echo -e "  ${RED}✘  RC: YOK – PA10 bağlantısını ve iBUS portunu kontrol et${RST}"
    fi
    bekle

    # ── ADIM 8: ARM testi ───────────────────────────────────
    adim 8 "ARM / DISARM Testi"
    echo "  Kumandada CH6 anahtarını YUKARI al (ARM)."
    echo "  Seri portta 'FC: ARMED' mesajı gelmeli."
    if sor "  ARMED mesajı geldi mi?"; then
        echo -e "  ${GRN}✔  ARM çalışıyor${RST}"
    else
        echo -e "  ${RED}✘  ARM olmadı – RC kanallarını ve config.h'daki RC_CH_ARM'ı kontrol et${RST}"
    fi
    bekle

    # ── ADIM 9: MANUAL mod servo testi ─────────────────────
    adim 9 "MANUAL Mod – Servo Tepki Testi"
    echo "  ${BOLD}ÖNCE: CH5'i aşağı (MANUAL MOD)${RST}"
    echo "  Servo'ları hareket ettir, gözlemle:"
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  Yapılan hareket → Beklenen servo tepkisi   │"
    echo "  │  ─────────────────────────────────────────  │"
    echo "  │  Sağ stick sağa  → Aileron Sağ ↑ Sol ↓     │"
    echo "  │  Sağ stick sola  → Aileron Sol ↑ Sağ ↓     │"
    echo "  │  Sağ stick ileri → Elevator aşağı           │"
    echo "  │  Sağ stick geri  → Elevator yukarı          │"
    echo "  │  Sol stick sağa  → Rudder sağa              │"
    echo "  └─────────────────────────────────────────────┘"
    if sor "  Tüm servo yönleri doğru mu?"; then
        echo -e "  ${GRN}✔  MANUAL mod tamam${RST}"
    else
        echo -e "  ${YLW}  Ters servo: servo.c'de ilgili kanalın işaretini değiştir (-value)${RST}"
    fi
    bekle

    # ── ADIM 10: STABILIZE mod testi ───────────────────────
    adim 10 "STABILIZE Mod – PID Düzeltme Testi"
    echo "  ${BOLD}ÖNEMLİ: Bu test tüm testlerin en kritik olanıdır!${RST}"
    echo "  Yanlış sonuç = uçakta ters düzeltme = kaza!"
    echo ""
    echo "  CH5'i YUKARI al (STABILIZE MOD)"
    echo "  Kumanda sticklerini ortada bırak."
    echo ""
    echo "  ┌────────────────────────────────────────────────┐"
    echo "  │  Kartı elle yatır → servo KARŞI yönde hareket │"
    echo "  │  ────────────────────────────────────────────  │"
    echo "  │  Kartı sağa yatır → Sol aileron AŞAĞI        │"
    echo "  │                     Sağ aileron YUKARI        │"
    echo "  │  Kartı öne eğ    → Elevator YUKARI           │"
    echo "  │  Kartı geri eğ   → Elevator AŞAĞI            │"
    echo "  └────────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${YLW}Eğer servo AYNI yönde hareket ederse = PID TERS!${RST}"
    echo "  → flight_control.c'de ilgili PID çıkışının işaretini değiştir"
    if sor "  Servo'lar doğru yönde düzeltiyor mu?"; then
        echo -e "  ${GRN}✔  STABILIZE mod tamam${RST}"
    else
        echo -e "  ${RED}✘  KALDI – Uçurmadan önce düzelt!${RST}"
    fi
    bekle

    # ── ADIM 11: Motor testi (pervane yok) ─────────────────
    adim 11 "Motor / ESC Testi (PERVANE TAKMADAN)"
    echo -e "  ${RED}${BOLD}  ⚠  Motor kablosunu bağla ama PERVANE TAKMA!${RST}"
    echo ""
    echo "  ESC → PA6 (TIM3_CH1)"
    echo "  ESC güç kablosu → LiPo (ya da güç kaynağı)"
    echo ""
    echo "  ARM et → Sol sticki yavaşça yukarı çek"
    echo "  Motor dönmeye başlamalı, stick aşağıya → durmalı"
    if sor "  Motor tepkisi doğru mu (dönüyor/duruyor)?"; then
        echo -e "  ${GRN}✔  Motor tamam${RST}"
    else
        echo -e "  ${YLW}  ESC arming sesini bekle (bip bip), sonra tekrar dene${RST}"
    fi
    bekle

    # ── Sonuç ───────────────────────────────────────────────
    echo -e "\n${GRN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║  DONANIM TESTLERİ TAMAMLANDI!               ║"
    echo "  ║                                              ║"
    echo "  ║  Tüm adımlar GEÇTI ise:                     ║"
    echo "  ║  1. Pervaneyi tak                            ║"
    echo "  ║  2. Açık alanda MANUAL modda ilk uçuş       ║"
    echo "  ║  3. Stabil uçuyorsa STABILIZE moda geç      ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RST}"
}

# ════════════════════════════════════════════════════════════
#  ANA MENÜ
# ════════════════════════════════════════════════════════════
case "${1:-}" in
    --kurulum)
        bash "$DIR/setup.sh"
        ;;
    --donanim)
        run_hardware_guide
        ;;
    --temizle)
        pkill -f sim_fc 2>/dev/null || true
        cd "$DIR" && make clean
        echo "Temizlendi."
        ;;
    ""|--yazilim)
        run_software_tests
        ;;
    *)
        echo "Kullanım:"
        echo "  bash testler.sh             → Yazılım testleri (otomatik)"
        echo "  bash testler.sh --kurulum   → Bağımlılıkları kur + derle"
        echo "  bash testler.sh --donanim  → Donanım test rehberi (adım adım)"
        echo "  bash testler.sh --temizle  → Derlenmiş dosyaları sil"
        ;;
esac
