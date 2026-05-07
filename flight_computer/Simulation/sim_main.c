/*
 * PC Simülasyon Giriş Noktası
 *
 * UDP portları:
 *   5500 ← Sensör (JSBSim veya test_runner.py)
 *   5501 → Kontrol (JSBSim'e)
 *   5502 → JSON Telemetri (test_runner.py okur)
 *   5503 ← RC kanalları (test_runner.py gönderir: 14×uint16 LE)
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
#include "rc_input.h"
#include "flight_control.h"
#include "hal_wrapper.h"

#define TELEM_UDP_PORT 5502

extern void mock_hal_init(void);
extern void mock_hal_update_rc(uint16_t *ch_out, uint8_t count, bool *updated);

static volatile bool g_running = true;
static int g_telem_sock = -1;
static struct sockaddr_in g_telem_addr;

static void sig_handler(int s) { (void)s; g_running = false; }

static void sleep_us(long us)
{
    struct timespec ts = {0, us * 1000L};
    nanosleep(&ts, NULL);
}

static void telem_init(void)
{
    g_telem_sock = socket(AF_INET, SOCK_DGRAM, 0);
    g_telem_addr.sin_family      = AF_INET;
    g_telem_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    g_telem_addr.sin_port        = htons(TELEM_UDP_PORT);
}

static void telem_send(const IMU *imu, const GPSData *gps,
                       const FlightController *fc, const RCInput *rc)
{
    if (g_telem_sock < 0) return;
    char buf[512];
    int n = snprintf(buf, sizeof(buf),
        "{\"roll\":%.2f,\"pitch\":%.2f,\"yaw\":%.2f,"
        "\"rollRate\":%.2f,\"pitchRate\":%.2f,\"yawRate\":%.2f,"
        "\"throttle\":%.3f,\"armed\":%d,\"mode\":\"%s\","
        "\"aileron\":%.3f,\"elevator\":%.3f,\"rudder\":%.3f,"
        "\"lat\":%.6f,\"lon\":%.6f,\"alt\":%.1f,\"gpsFix\":%d,"
        "\"rcLost\":%d}",
        imu_roll_deg(imu), imu_pitch_deg(imu), imu_yaw_deg(imu),
        imu->gyro_x*57.296f, imu->gyro_y*57.296f, imu->gyro_z*57.296f,
        fc->out_throttle, fc->armed ? 1 : 0,
        fc_mode_str(fc->mode),
        fc->out_aileron, fc->out_elevator, fc->out_rudder,
        gps->lat, gps->lon, gps->alt_m, gps->fix_valid ? 1 : 0,
        rc_is_lost(rc) ? 1 : 0);
    sendto(g_telem_sock, buf, n, 0,
           (struct sockaddr *)&g_telem_addr, sizeof(g_telem_addr));
}

/* iBUS çerçevesi oluştur ve parse et */
static void build_and_parse_ibus(RCInput *rc, const uint16_t *ch)
{
    uint8_t frame[IBUS_FRAME_LEN] = {0};
    frame[0] = IBUS_HEADER0;
    frame[1] = IBUS_HEADER1;
    for (int i = 0; i < IBUS_MAX_CHANNELS; i++) {
        frame[2 + i*2] = ch[i] & 0xFF;
        frame[3 + i*2] = (ch[i] >> 8) & 0xFF;
    }
    uint16_t cs = 0;
    for (int i = 0; i < 30; i++) cs += frame[i];
    cs = 0xFFFF - cs;
    frame[30] = cs & 0xFF;
    frame[31] = (cs >> 8) & 0xFF;
    rc_input_parse(rc, frame);
}

int main(void)
{
    signal(SIGINT,  sig_handler);
    signal(SIGTERM, sig_handler);

    printf("╔══════════════════════════════════════════════╗\n");
    printf("║  Fixed-Wing IHA – PC Simülasyonu             ║\n");
    printf("╚══════════════════════════════════════════════╝\n");

    mock_hal_init();
    telem_init();

    IMU              imu;
    GPSData          gps = {0};
    RCInput          rc;
    FlightController fc;

    if (!imu_init(&imu)) { fprintf(stderr, "[HATA] IMU başlatılamadı\n"); return 1; }
    gps_init();
    rc_input_init(&rc);
    fc_init(&fc);

    printf("Durdurmak için Ctrl+C\n\n");

    const uint32_t imu_ms   = 1000u / IMU_SAMPLE_RATE_HZ;
    const uint32_t ctrl_ms  = 1000u / CTRL_LOOP_RATE_HZ;
    const uint32_t gps_ms   = 1000u / GPS_UPDATE_RATE_HZ;
    const uint32_t telem_ms = 50u;
    const uint32_t log_ms   = 500u;
    const uint32_t rc_ms    = 10u;   /* RC'yi 100 Hz'de kontrol et */

    uint32_t t_imu=0, t_ctrl=0, t_gps=0, t_telem=0, t_log=0, t_rc=0;

    while (g_running) {
        uint32_t now = hw_get_tick_ms();

        /* RC güncelle – UDP'den oku, iBUS frame oluştur */
        if ((now - t_rc) >= rc_ms) {
            uint16_t ch[IBUS_MAX_CHANNELS];
            bool updated = false;
            mock_hal_update_rc(ch, IBUS_MAX_CHANNELS, &updated);
            if (updated) build_and_parse_ibus(&rc, ch);
            t_rc = now;
        }

        if ((now - t_imu) >= imu_ms) {
            imu_update(&imu);
            t_imu = now;
        }

        if ((now - t_ctrl) >= ctrl_ms) {
            fc_update(&fc, &imu, &rc, CTRL_DT);
            t_ctrl = now;
        }

        if ((now - t_gps) >= gps_ms) {
            gps_update(&gps);
            t_gps = now;
        }

        if ((now - t_telem) >= telem_ms) {
            telem_send(&imu, &gps, &fc, &rc);
            t_telem = now;
        }

        if ((now - t_log) >= log_ms) {
            printf("[%s] R:%+6.1f° P:%+6.1f° Y:%+6.1f° THR:%.2f AIL:%+.2f ELV:%+.2f RC:%s\n",
                   fc_mode_str(fc.mode),
                   imu_roll_deg(&imu), imu_pitch_deg(&imu), imu_yaw_deg(&imu),
                   fc.out_throttle, fc.out_aileron, fc.out_elevator,
                   rc_is_lost(&rc) ? "YOK" : "VAR");
            t_log = now;
        }

        sleep_us(200);
    }

    printf("\n[SIM] Kapatılıyor...\n");
    fc_disarm(&fc);
    return 0;
}

#endif /* SIMULATION */
