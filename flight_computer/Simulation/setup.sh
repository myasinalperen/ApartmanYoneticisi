#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  IHA Uçuş Bilgisayarı – Kurulum Scripti
#  Çalıştır: bash setup.sh
# ─────────────────────────────────────────────────────────────
set -e
BOLD="\033[1m"; GRN="\033[92m"; RED="\033[91m"; RST="\033[0m"
DIR="$(cd "$(dirname "$0")" && pwd)"

ok()   { echo -e "  ${GRN}✔${RST}  $1"; }
err()  { echo -e "  ${RED}✘  $1${RST}"; exit 1; }
info() { echo -e "${BOLD}▶ $1${RST}"; }

echo -e "\n${BOLD}════════════════════════════════════════${RST}"
echo -e "${BOLD}  IHA Simülasyonu – Kurulum${RST}"
echo -e "${BOLD}════════════════════════════════════════${RST}\n"

# ── 1. İşletim sistemi tespiti ─────────────────────────────
info "Sistem kontrol ediliyor..."
if command -v apt &>/dev/null; then
    PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
elif command -v brew &>/dev/null; then
    PKG_MGR="brew"
else
    echo "  Ubuntu/Debian, Fedora veya macOS gereklidir."
    err "Desteklenmeyen işletim sistemi"
fi
ok "Paket yöneticisi: $PKG_MGR"

# ── 2. GCC / Make ──────────────────────────────────────────
info "Derleme araçları kontrol ediliyor..."
if ! command -v gcc &>/dev/null; then
    echo "  gcc bulunamadı, kuruluyor..."
    if   [ "$PKG_MGR" = "apt"  ]; then sudo apt install -y build-essential
    elif [ "$PKG_MGR" = "dnf"  ]; then sudo dnf install -y gcc make
    elif [ "$PKG_MGR" = "brew" ]; then xcode-select --install 2>/dev/null || true
    fi
fi
ok "gcc: $(gcc --version | head -1)"
ok "make: $(make --version | head -1)"

# ── 3. Python 3 ────────────────────────────────────────────
info "Python 3 kontrol ediliyor..."
if ! command -v python3 &>/dev/null; then
    if   [ "$PKG_MGR" = "apt"  ]; then sudo apt install -y python3
    elif [ "$PKG_MGR" = "dnf"  ]; then sudo dnf install -y python3
    elif [ "$PKG_MGR" = "brew" ]; then brew install python3
    fi
fi
ok "python3: $(python3 --version)"

# ── 4. JSBSim (opsiyonel) ──────────────────────────────────
info "JSBSim kontrol ediliyor (opsiyonel)..."
if python3 -c "import jsbsim" &>/dev/null 2>&1; then
    ok "JSBSim zaten kurulu"
else
    echo "  JSBSim kuruluyor (tam fizik simülasyonu için)..."
    if pip3 install jsbsim &>/dev/null 2>&1; then
        ok "JSBSim kuruldu"
    else
        echo "  ⚠  JSBSim kurulamadı – sadece mantık testi çalışacak"
    fi
fi

# ── 5. sim_fc derleme ──────────────────────────────────────
info "sim_fc derleniyor..."
cd "$DIR"
make clean &>/dev/null || true
if make 2>&1 | tail -3; then
    ok "sim_fc derlendi: $DIR/sim_fc"
else
    err "Derleme başarısız! Hata mesajlarını yukarıda incele."
fi

echo -e "\n${GRN}${BOLD}════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  Kurulum tamamlandı!${RST}"
echo -e "${GRN}${BOLD}════════════════════════════════════════${RST}"
echo -e "  Testleri başlatmak için:\n"
echo -e "    ${BOLD}bash testler.sh${RST}\n"
