/*
 * PC Simülasyon Giriş Noktası
 * Derleme: make -C Simulation
 * Çalıştırma: ./sim_fc
 *
 * Mimari:
 *   JSBSim (UDP:5500) → mock_hal → imu/gps/flight_control → mock_hal → JSBSim (UDP:5501)
 *
 * JSBSim tarafında jsbsim_scripts/fg_control.xml protokol dosyası gerekli.
 */

#ifdef SIMULATION

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

#include "config.h"
#include "imu.h"
#include "gps.h"
#include "flight_control.h"
#include "hal_wrapper.h"

/* mock_hal.c'den */
extern void mock_hal_init(void);

static volatile bool g_running = true;

static void sig_handler(int s) { (void)s; g_running = false; }

/* Mikrosaniye hassasiyetli uyku */
static void sleep_us(long us)
{
    struct timespec ts = { .tv_sec = 0, .tv_nsec = us * 1000L };
    nanosleep(&ts, NULL);
}

int main(void)
{
    signal(SIGINT,  sig_handler);
    signal(SIGTERM, sig_handler);

    printf("=== Fixed-Wing IHA Uçuş Bilgisayarı – PC Simülasyonu ===\n");
    printf("JSBSim sensör portu  : %d (dinleniyor)\n", SIM_RECV_PORT);
    printf("JSBSim kontrol portu : %d (gönderiliyor)\n", SIM_SEND_PORT);
    printf("Durdurmak için Ctrl+C\n\n");

    /* 1. Mock HAL'ı başlat (UDP soketleri aç) */
    mock_hal_init();

    /* 2. Modülleri başlat */
    IMU              imu;
    GPSData          gps = {0};
    FlightController fc;

    if (!imu_init(&imu)) {
        fprintf(stderr, "[HATA] IMU başlatılamadı\n");
        return 1;
    }
    gps_init();
    fc_init(&fc);

    /* 3. ESC arming – simülasyonda kısa tut */
    printf("[SIM] ESC arming...\n");
    fc_arm(&fc);
    fc.throttle          = 0.10f;   /* rölanti */
    fc.target_roll_deg   = 0.0f;
    fc.target_pitch_deg  = 2.0f;    /* hafif pozitif pitch – kalkış */
    fc.target_yaw_rate_dps = 0.0f;

    printf("[SIM] Kontrol döngüsü başladı (%.0f Hz)\n", (float)CTRL_LOOP_RATE_HZ);

    /* 4. Ana döngü */
    uint32_t last_imu_tick  = hw_get_tick_ms();
    uint32_t last_ctrl_tick = hw_get_tick_ms();
    uint32_t last_gps_tick  = hw_get_tick_ms();
    uint32_t last_log_tick  = hw_get_tick_ms();

    const uint32_t imu_period_ms  = 1000u / IMU_SAMPLE_RATE_HZ;   /* 1 ms  */
    const uint32_t ctrl_period_ms = 1000u / CTRL_LOOP_RATE_HZ;    /* 2-3 ms*/
    const uint32_t gps_period_ms  = 1000u / GPS_UPDATE_RATE_HZ;   /* 100 ms*/
    const uint32_t log_period_ms  = 200u;                          /* 5 Hz  */

    while (g_running) {
        uint32_t now = hw_get_tick_ms();

        /* IMU – 1000 Hz */
        if ((now - last_imu_tick) >= imu_period_ms) {
            imu_update(&imu);
            last_imu_tick = now;
        }

        /* Kontrol döngüsü – 400 Hz */
        if ((now - last_ctrl_tick) >= ctrl_period_ms) {
            fc_update(&fc, &imu, CTRL_DT);
            last_ctrl_tick = now;
        }

        /* GPS – 10 Hz */
        if ((now - last_gps_tick) >= gps_period_ms) {
            gps_update(&gps);
            last_gps_tick = now;
        }

        /* Telemetri – 5 Hz (konsol) */
        if ((now - last_log_tick) >= log_period_ms) {
            printf("[TEL] R:%+6.1f° P:%+6.1f° Y:%+6.1f° | THR:%.2f | "
                   "GPS:%s lat:%.4f lon:%.4f alt:%.0fm\n",
                   imu_roll_deg(&imu),
                   imu_pitch_deg(&imu),
                   imu_yaw_deg(&imu),
                   fc.throttle,
                   gps.fix_valid ? "FIX" : "---",
                   gps.lat, gps.lon, gps.alt_m);
            last_log_tick = now;
        }

        sleep_us(200);   /* CPU'yu rahatlatmak için 0.2 ms bekle */
    }

    printf("\n[SIM] Kapatılıyor...\n");
    fc_disarm(&fc);
    return 0;
}

#endif /* SIMULATION */
