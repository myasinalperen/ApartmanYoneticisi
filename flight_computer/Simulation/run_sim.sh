#!/bin/bash
# Fixed-Wing IHA – Simülasyon Başlatma Scripti
# Kullanım: ./run_sim.sh [--no-jsbsim]
#
# JSBSim yoksa --no-jsbsim ile sadece uçuş bilgisayarı çalışır
# (sensör verisi olmadan sıfır etrafında döner, mantık testi için yeterli).

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIM_BIN="$SCRIPT_DIR/sim_fc"

# ── Derleme ──────────────────────────────────────────────
echo "[*] Derleniyor..."
make -C "$SCRIPT_DIR" --silent
echo "[+] Derleme tamam: $SIM_BIN"

if [[ "$1" == "--no-jsbsim" ]]; then
    echo "[!] JSBSim atlandı – sadece uçuş bilgisayarı çalışacak"
    exec "$SIM_BIN"
fi

# ── JSBSim kurulu mu? ────────────────────────────────────
if ! command -v JSBSim &>/dev/null && ! python3 -c "import jsbsim" &>/dev/null 2>&1; then
    echo ""
    echo "[!] JSBSim bulunamadı. Kurulum seçenekleri:"
    echo "    pip install jsbsim"
    echo "    sudo apt install jsbsim"
    echo ""
    echo "    Şimdilik --no-jsbsim modunda başlatılıyor..."
    echo ""
    exec "$SIM_BIN"
fi

# ── JSBSim + uçuş bilgisayarını paralel başlat ──────────
echo "[*] JSBSim başlatılıyor..."
if command -v JSBSim &>/dev/null; then
    JSBSim --script="$SCRIPT_DIR/jsbsim_scripts/c172_sim.xml" \
           --logdirectivefile=/dev/null &
else
    python3 -c "
import jsbsim, time
fdm = jsbsim.FGFDMExec('.')
fdm.load_script('$SCRIPT_DIR/jsbsim_scripts/c172_sim.xml')
fdm.run_ic()
while fdm.run():
    pass
" &
fi
JSBSIM_PID=$!
echo "[+] JSBSim PID: $JSBSIM_PID"

sleep 1   # JSBSim'in soketi açmasını bekle

echo "[*] Uçuş bilgisayarı başlatılıyor..."
"$SIM_BIN" &
FC_PID=$!

# ── Ctrl+C ile her ikisini de kapat ─────────────────────
trap "echo ''; echo 'Kapatılıyor...'; kill $JSBSIM_PID $FC_PID 2>/dev/null; exit 0" INT TERM

wait $FC_PID
kill $JSBSIM_PID 2>/dev/null
