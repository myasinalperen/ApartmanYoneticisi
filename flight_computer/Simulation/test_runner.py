#!/usr/bin/env python3
"""
Otomatik Uçuş Bilgisayarı Test Sürücüsü
========================================
Bu script sim_fc'yi başlatır, sensör + RC verisi gönderir,
telemetriyi okur ve her testi GEÇTI / KALDI olarak raporlar.

Çalıştırmak için:
    python3 test_runner.py

veya testler.sh aracılığıyla.
"""

import subprocess, socket, struct, json, time, sys, os, signal, math

# ── Port tanımları (config.h ile aynı) ─────────────────────
SENSOR_PORT = 5500   # → sim_fc'ye sensör gönder
TELEM_PORT  = 5502   # ← sim_fc'den JSON telemetri al
RC_PORT     = 5503   # → sim_fc'ye RC kanalları gönder

HOST = "127.0.0.1"

# ── Sensör paketi: 13 × double little-endian (104 byte) ────
# Sıra: roll,pitch,yaw, roll_rate,pitch_rate,yaw_rate,
#        ax,ay,az, lat,lon,alt,airspeed
SENSOR_FMT = "<13d"

def sensor_pkt(roll=0.0, pitch=0.0, yaw=0.0,
               roll_rate=0.0, pitch_rate=0.0, yaw_rate=0.0,
               ax=0.0, ay=0.0, az=-9.80665,
               lat=41.0, lon=29.0, alt=100.0, airspeed=20.0):
    return struct.pack(SENSOR_FMT,
        math.radians(roll), math.radians(pitch), math.radians(yaw),
        math.radians(roll_rate), math.radians(pitch_rate), math.radians(yaw_rate),
        ax, ay, az, lat, lon, alt, airspeed)

# ── RC paketi: 14 × uint16 little-endian (28 byte) ─────────
# Kanal sırası: aileron, elevator, throttle, rudder, mod, arm, ...
def rc_pkt(aileron=1500, elevator=1500, throttle=1000,
           rudder=1500, mode=2000, arm=2000,
           fill=1500):
    ch = [aileron, elevator, throttle, rudder, mode, arm] + [fill]*8
    return struct.pack("<14H", *ch)

RC_DISARM    = rc_pkt(arm=1000, mode=1000)
RC_ARM_MAN   = rc_pkt(arm=2000, mode=1000)   # MANUAL mod
RC_ARM_STAB  = rc_pkt(arm=2000, mode=2000)   # STABILIZE mod

# ── Renkli çıktı ───────────────────────────────────────────
GRN = "\033[92m"; RED = "\033[91m"; YLW = "\033[93m"
BLD = "\033[1m";  RST = "\033[0m";  CYN = "\033[96m"

def banner(txt):
    print(f"\n{BLD}{CYN}{'─'*54}{RST}")
    print(f"{BLD}{CYN}  {txt}{RST}")
    print(f"{BLD}{CYN}{'─'*54}{RST}")

def ok(name, detail=""):
    print(f"  {GRN}✔  GEÇTI{RST}  {name}" + (f"  ({detail})" if detail else ""))

def fail(name, detail=""):
    print(f"  {RED}✘  KALDI{RST}  {name}" + (f"  ← {detail}" if detail else ""))

def warn(txt):
    print(f"  {YLW}⚠  {txt}{RST}")

# ── Test yardımcıları ───────────────────────────────────────
class TestSession:
    def __init__(self):
        # UDP soketler
        self.send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.rc_sock   = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.telem_sock= socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.telem_sock.bind(("", TELEM_PORT))
        self.telem_sock.settimeout(1.5)
        self.passed = 0
        self.failed = 0
        self.proc   = None

    def start_sim(self):
        self.proc = subprocess.Popen(
            ["./sim_fc"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        time.sleep(2.0)  # Başlama + arming için bekle

        # Sokette birikmiş eski veriyi temizle
        self.telem_sock.settimeout(0.05)
        for _ in range(20):
            try: self.telem_sock.recvfrom(1024)
            except: break
        self.telem_sock.settimeout(1.5)

    def stop_sim(self):
        if self.proc:
            self.proc.send_signal(signal.SIGINT)
            try: self.proc.wait(timeout=3)
            except: self.proc.kill()

    def send_sensor(self, **kwargs):
        self.send_sock.sendto(sensor_pkt(**kwargs), (HOST, SENSOR_PORT))

    def send_rc(self, pkt):
        self.rc_sock.sendto(pkt, (HOST, RC_PORT))

    def pump(self, rc_pkt_data, sensor_kwargs, duration=1.5, hz=20):
        """Belirli süre boyunca RC + sensör gönder, son telemetriyi döndür."""
        steps = int(duration * hz)
        interval = 1.0 / hz
        last_telem = None
        for _ in range(steps):
            self.send_rc(rc_pkt_data)
            self.send_sensor(**sensor_kwargs)
            try:
                raw, _ = self.telem_sock.recvfrom(1024)
                last_telem = json.loads(raw.decode())
            except (socket.timeout, json.JSONDecodeError):
                pass
            time.sleep(interval)
        return last_telem

    def check(self, condition, name, ok_detail="", fail_detail=""):
        if condition:
            ok(name, ok_detail)
            self.passed += 1
        else:
            fail(name, fail_detail)
            self.failed += 1
        return condition

    def telem(self):
        # En son paketi al (timeout içinde birden fazla gelebilir)
        last = {}
        self.telem_sock.settimeout(0.3)
        while True:
            try:
                raw, _ = self.telem_sock.recvfrom(1024)
                last = json.loads(raw.decode())
            except (socket.timeout, json.JSONDecodeError):
                break
        self.telem_sock.settimeout(1.5)
        return last

# ══════════════════════════════════════════════════════════════
# TEST SENARYOLARI
# ══════════════════════════════════════════════════════════════

def test_1_baslama(s: TestSession):
    banner("TEST 1 – Sistem Başlıyor")
    print("  sim_fc başlatılıyor...")
    s.start_sim()

    # ARM komutu ver (STABILIZE)
    for _ in range(20):
        s.send_rc(RC_ARM_STAB)
        s.send_sensor()
        time.sleep(0.1)

    t = s.telem()
    s.check(bool(t), "Telemetri alınıyor", fail_detail="sim_fc'den veri gelmedi")
    s.check(t.get("armed", False),
            "ARM komutu çalışıyor",
            ok_detail="Sistem silahlandı",
            fail_detail="ARM olmadı – CH6=2000 gönderildi ama armed=false geldi")
    s.check(t.get("mode", "") == "STABILIZE",
            "STABILIZE mod aktif",
            ok_detail=f"mod={t.get('mode','-')}",
            fail_detail="STABILIZE beklendi")

def test_2_duz_ucus(s: TestSession):
    banner("TEST 2 – Düz Uçuş (Sıfır Sapma)")
    print("  Roll=0°, Pitch=0° ile 2 saniye uçuluyor...")
    t = s.pump(RC_ARM_STAB, dict(roll=0, pitch=0), duration=2.0)
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    ail  = abs(t.get("aileron",  1.0))
    elev = abs(t.get("elevator", 1.0))
    s.check(ail  < 0.15, "Aileron nötrde",
            f"ail={ail:.3f}", f"ail={ail:.3f} (0.15'ten küçük olmalı)")
    s.check(elev < 0.15, "Elevator nötrde",
            f"elev={elev:.3f}", f"elev={elev:.3f} (0.15'ten küçük olmalı)")

def test_3_roll_bozulmasi(s: TestSession):
    banner("TEST 3 – Roll Bozulması Düzeltme (+30°)")
    print("  Uçak 30° sağa yatıyor. Aileron sola dönmeli...")
    t = s.pump(RC_ARM_STAB, dict(roll=30.0), duration=2.0)
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    ail = t.get("aileron", 0.0)
    s.check(ail < -0.15, "Aileron sola düzeltiyor",
            f"ail={ail:.3f} ✓", f"ail={ail:.3f} – negatif (<-0.15) olmalı")
    r = t.get("roll", 999)
    s.check(abs(r) < 35, "Roll makul aralıkta",
            f"roll={r:.1f}°", f"roll={r:.1f}° – 35°'den büyük")

def test_4_pitch_bozulmasi(s: TestSession):
    banner("TEST 4 – Pitch Bozulması Düzeltme (+20°)")
    print("  Uçak 20° yukarı kalkıyor. Elevator aşağı basmalı...")
    t = s.pump(RC_ARM_STAB, dict(pitch=20.0), duration=2.0)
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    elev = t.get("elevator", 0.0)
    s.check(elev < -0.10, "Elevator aşağı düzeltiyor",
            f"elev={elev:.3f} ✓", f"elev={elev:.3f} – negatif (<-0.10) olmalı")

def test_5_manuel_mod(s: TestSession):
    banner("TEST 5 – MANUAL Mod (Direk RC Geçiş)")
    print("  MANUAL modda aileron çubuğu +%60 → servo +0.6 olmalı...")
    # CH1 aileron = 1800 (orta + 300 = %60)
    pkt = rc_pkt(aileron=1800, arm=2000, mode=1000)
    t = s.pump(pkt, dict(roll=0, pitch=0), duration=1.5)
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    mode = t.get("mode", "")
    s.check(mode == "MANUAL", "MANUAL mod aktif",
            ok_detail="mod=MANUAL", fail_detail=f"mod={mode}")
    ail = t.get("aileron", 0.0)
    s.check(ail > 0.5, "Aileron RC'yi takip ediyor",
            f"ail={ail:.3f} ✓", f"ail={ail:.3f} – 0.5'ten büyük olmalı")

def test_6_failsafe(s: TestSession):
    banner("TEST 6 – Failsafe (RC Kesilince)")
    print("  RC sinyali 700ms kesilecek. Failsafe devreye girmeli...")

    # Önce ARM + STABILIZE kur
    for _ in range(15):
        s.send_rc(RC_ARM_STAB)
        s.send_sensor()
        time.sleep(0.1)

    # RC'yi tamamen kes
    print("  RC kesildi – 700ms bekleniyor...")
    time.sleep(0.7)

    # Sadece sensör gönder, RC YOK
    for _ in range(10):
        s.send_sensor()
        time.sleep(0.05)

    t = s.telem()
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    rc_lost = t.get("rcLost", 0)
    s.check(rc_lost == 1, "RC kayıp algılandı",
            "rcLost=1 ✓", "rcLost=0 – failsafe tetiklenmedi")

    thr = t.get("throttle", 1.0)
    s.check(thr <= 0.40, "Throttle güvenli seviyeye çekildi",
            f"thr={thr:.2f} ✓", f"thr={thr:.2f} – 0.40'tan küçük olmalı")

def test_7_disarm(s: TestSession):
    banner("TEST 7 – DISARM")
    print("  CH6 aşağı çekiliyor. Sistem silahsızlandırılmalı...")
    pkt = rc_pkt(arm=1000, mode=2000)
    t = s.pump(pkt, dict(roll=0, pitch=0), duration=1.2)
    if not t:
        fail("Telemetri yok"); s.failed += 1; return

    s.check(not t.get("armed", True), "DISARM çalışıyor",
            "armed=false ✓", "Hâlâ armed=true")
    thr = t.get("throttle", 1.0)
    s.check(thr < 0.01, "Motor durduruldu",
            f"thr={thr:.3f} ✓", f"thr={thr:.3f} – 0'a yakın olmalı")

# ══════════════════════════════════════════════════════════════
# ANA ÇALIŞTIRICI
# ══════════════════════════════════════════════════════════════

def main():
    print(f"\n{BLD}{'═'*54}{RST}")
    print(f"{BLD}  IHA Uçuş Bilgisayarı – Otomatik Test Paketi{RST}")
    print(f"{BLD}{'═'*54}{RST}")

    # sim_fc var mı?
    if not os.path.exists("./sim_fc"):
        print(f"{RED}[HATA] ./sim_fc bulunamadı. Önce 'make' çalıştır.{RST}")
        sys.exit(1)

    s = TestSession()
    try:
        test_1_baslama(s)
        test_2_duz_ucus(s)
        test_3_roll_bozulmasi(s)
        test_4_pitch_bozulmasi(s)
        test_5_manuel_mod(s)
        test_6_failsafe(s)
        test_7_disarm(s)
    except KeyboardInterrupt:
        print("\n[!] Test kullanıcı tarafından iptal edildi.")
    finally:
        s.stop_sim()

    # ── Özet ───────────────────────────────────────────────
    toplam = s.passed + s.failed
    print(f"\n{BLD}{'═'*54}{RST}")
    print(f"{BLD}  SONUÇ: {s.passed}/{toplam} test geçti{RST}")
    if s.failed == 0:
        print(f"{GRN}{BLD}  ✔  TÜM TESTLER BAŞARILI – Donanım testine geçebilirsin!{RST}")
    else:
        print(f"{RED}{BLD}  ✘  {s.failed} test başarısız – PID ayarlarını veya bağlantıları kontrol et.{RST}")
    print(f"{BLD}{'═'*54}{RST}\n")

    sys.exit(0 if s.failed == 0 else 1)

if __name__ == "__main__":
    main()
