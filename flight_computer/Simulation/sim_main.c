/*
 * PC Simülasyon Giriş Noktası
 * Derleme: make -C Simulation
 * Çalıştırma: ./sim_fc
 *
 * Mimari:
 *   JSBSim (UDP:5500) → mock_hal → imu/gps/flight_control → mock_hal → JSBSim (UDP:5501)
 *   sim_fc → UDP:5502 (JSON telemetri) → web/server.py → WebSocket → Tarayıcı
 */

#ifdef SIMULATION

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#include "config.h"
#include "imu.h"
#include "gps.h"
#include "flight_control.h"
#include "hal_wrapper.h"

#define TELEM_UDP_PORT 5502

extern void mock_hal_init(void);

static volatile bool g_running = true;
static int g_telem_sock = -1;
static struct sockaddr_in g_telem_addr;

static void sig_handler(int s) { (void)s; g_running = false; }

static void sleep_us(long us)
{
    struct timespec ts = { .tv_sec = 0, .tv_nsec = us * 1000L };
    nanosleep(&ts, NULL);
}

static void telem_init(void)
{
    g_telem_sock = socket(AF_INET, SOCK_DGRAM, 0);
    g_telem_addr.sin_family      = AF_INET;
    g_telem_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    g_telem_addr.sin_port        = htons(TELEM_UDP_PORT);
    printf("[SIM] Telemetri UDP portu : %d (web arayüzü)\n", TELEM_UDP_PORT);
}

static void telem_send(const IMU *imu, const GPSData *gps, const FlightController *fc)
{
    if (g_telem_sock < 0) return;
    char buf[512];
    int n = snprintf(buf, sizeof(buf),
        "{\"roll\":%.2f,\"pitch\":%.2f,\"yaw\":%.2f,"
        "\"rollRate\":%.2f,\"pitchRate\":%.2f,\"yawRate\":%.2f,"
        "\"throttle\":%.3f,\"armed\":%d,"
        "\"aileron\":%.3f,\"elevator\":%.3f,\"rudder\":%.3f,"
        "\"lat\":%.6f,\"lon\":%.6f,\"alt\":%.1f,\"gpsFix\":%d}",
        imu_roll_deg(imu), imu_pitch_deg(imu), imu_yaw_deg(imu),
        imu->gyro_x * 57.296f, imu->gyro_y * 57.296f, imu->gyro_z * 57.296f,
        fc->out_throttle, fc->armed ? 1 : 0,
        fc->out_aileron,
        fc->out_elevator,
        fc->out_rudder,
        gps->lat, gps->lon, gps->alt_m, gps->fix_valid ? 1 : 0);
    sendto(g_telem_sock, buf, n, 0,
           (struct sockaddr *)&g_telem_addr, sizeof(g_telem_addr));
}

int main(void)
{
    signal(SIGINT,  sig_handler);
    signal(SIGTERM, sig_handler);

    printf("=== Fixed-Wing IHA Uçuş Bilgisayarı – PC Simülasyonu ===\n");
    printf("JSBSim sensör portu  : %d (dinleniyor)\n", SIM_RECV_PORT);
    printf("JSBSim kontrol portu : %d (gönderiliyor)\n", SIM_SEND_PORT);

    mock_hal_init();
    telem_init();

    IMU              imu;
    GPSData          gps = {0};
    RCInput          rc;
    FlightController fc;

    if (!imu_init(&imu)) {
        fprintf(stderr, "[HATA] IMU başlatılamadı\n");
        return 1;
    }
    gps_init();
    rc_input_init(&rc);
    fc_init(&fc);

    /* Simülasyonda sahte iBUS çerçevesi: STABILIZE, arm ON, %40 gaz */
    uint8_t fake_ibus[IBUS_FRAME_LEN] = {0};
    fake_ibus[0] = IBUS_HEADER0;   /* 0x20 */
    fake_ibus[1] = IBUS_HEADER1;   /* 0x40 */
    /* CH1-CH4 (aileron/elevator/throttle/rudder) = 1500 µs (orta) */
    for (int i = 0; i < 4; i++) {
        fake_ibus[2 + i*2] = 0xDC; fake_ibus[3 + i*2] = 0x05; /* 1500 */
    }
    /* CH3 (throttle) = 1200 µs (%20 gaz) */
    fake_ibus[2 + 2*2] = 0xB0; fake_ibus[3 + 2*2] = 0x04;
    /* CH5 (mod) = 2000 µs → STABILIZE */
    fake_ibus[2 + 4*2] = 0xD0; fake_ibus[3 + 4*2] = 0x07;
    /* CH6 (arm) = 2000 µs → ARM */
    fake_ibus[2 + 5*2] = 0xD0; fake_ibus[3 + 5*2] = 0x07;
    /* Kalan kanallar 1500 µs */
    for (int i = 6; i < IBUS_MAX_CHANNELS; i++) {
        fake_ibus[2 + i*2] = 0xDC; fake_ibus[3 + i*2] = 0x05;
    }
    /* Checksum hesapla */
    uint16_t cs = 0;
    for (int i = 0; i < 30; i++) cs += fake_ibus[i];
    cs = 0xFFFF - cs;
    fake_ibus[30] = cs & 0xFF; fake_ibus[31] = (cs >> 8) & 0xFF;
    rc_input_parse(&rc, fake_ibus);

    printf("[SIM] Kontrol döngüsü başladı (%.0f Hz)\n", (float)CTRL_LOOP_RATE_HZ);
    printf("Durdurmak için Ctrl+C\n\n");

    uint32_t last_imu_tick   = hw_get_tick_ms();
    uint32_t last_ctrl_tick  = hw_get_tick_ms();
    uint32_t last_gps_tick   = hw_get_tick_ms();
    uint32_t last_log_tick   = hw_get_tick_ms();
    uint32_t last_telem_tick = hw_get_tick_ms();

    const uint32_t imu_period_ms   = 1000u / IMU_SAMPLE_RATE_HZ;
    const uint32_t ctrl_period_ms  = 1000u / CTRL_LOOP_RATE_HZ;
    const uint32_t gps_period_ms   = 1000u / GPS_UPDATE_RATE_HZ;
    const uint32_t log_period_ms   = 200u;
    const uint32_t telem_period_ms = 50u;   /* 20 Hz web telemetrisi */

    while (g_running) {
        uint32_t now = hw_get_tick_ms();

        if ((now - last_imu_tick) >= imu_period_ms) {
            imu_update(&imu);
            last_imu_tick = now;
        }

        if ((now - last_ctrl_tick) >= ctrl_period_ms) {
            fc_update(&fc, &imu, &rc, CTRL_DT);
            last_ctrl_tick = now;
        }

        if ((now - last_gps_tick) >= gps_period_ms) {
            gps_update(&gps);
            last_gps_tick = now;
        }

        /* 20 Hz – web arayüzüne JSON telemetri */
        if ((now - last_telem_tick) >= telem_period_ms) {
            telem_send(&imu, &gps, &fc);
            last_telem_tick = now;
        }

        /* 5 Hz – konsol çıktısı */
        if ((now - last_log_tick) >= log_period_ms) {
            printf("[TEL] R:%+6.1f° P:%+6.1f° Y:%+6.1f° | THR:%.2f | "
                   "GPS:%s lat:%.4f lon:%.4f alt:%.0fm\n",
                   imu_roll_deg(&imu), imu_pitch_deg(&imu), imu_yaw_deg(&imu),
                   fc.out_throttle,
                   gps.fix_valid ? "FIX" : "---",
                   gps.lat, gps.lon, gps.alt_m);
            last_log_tick = now;
        }

        sleep_us(200);
    }

    printf("\n[SIM] Kapatılıyor...\n");
    fc_disarm(&fc);
    return 0;
}

#endif /* SIMULATION */
