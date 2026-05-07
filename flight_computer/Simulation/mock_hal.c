/*
 * PC simülasyonu için sahte HAL implementasyonu.
 * Gerçek donanım yerine JSBSim UDP köprüsünden veri alır.
 */

#ifdef SIMULATION

#include "hal_wrapper.h"
#include "config.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <fcntl.h>

/* ── JSBSim UDP soketi ───────────────────────────────────── */
static int      g_recv_sock = -1;
static int      g_send_sock = -1;
static struct sockaddr_in g_jsbsim_addr;

/* JSBSim'den gelen sensör paketi */
typedef struct __attribute__((packed)) {
    double roll_rad;
    double pitch_rad;
    double yaw_rad;
    double roll_rate_rads;
    double pitch_rate_rads;
    double yaw_rate_rads;
    double ax_ms2;
    double ay_ms2;
    double az_ms2;
    double lat_deg;
    double lon_deg;
    double alt_m;
    double airspeed_ms;
} SimSensorPacket;

/* Uçuş bilgisayarından JSBSim'e giden kontrol paketi */
typedef struct __attribute__((packed)) {
    float aileron;    /* -1 … +1 */
    float elevator;   /* -1 … +1 */
    float rudder;     /* -1 … +1 */
    float throttle;   /* 0 … 1   */
} SimControlPacket;

static SimSensorPacket  g_sensors;
static SimControlPacket g_controls;

/* ── IMU mock tampon ─────────────────────────────────────── */
#define MPU6050_REG_WHO_AM_I    0x75
#define MPU6050_REG_ACCEL_H     0x3B
#define MPU6050_I2C_ADDR_BYTE   0x68

static void update_sensors_from_jsbsim(void)
{
    SimSensorPacket pkt;
    ssize_t n = recv(g_recv_sock, &pkt, sizeof(pkt), MSG_DONTWAIT);
    if (n == (ssize_t)sizeof(pkt)) {
        g_sensors = pkt;
    }
}

/* ── Zaman ───────────────────────────────────────────────── */
uint32_t hw_get_tick_ms(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint32_t)(tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void hw_delay_ms(uint32_t ms) { usleep(ms * 1000); }

/* ── I2C mock – MPU6050 ham baytlarını sim veriden üretir ── */
bool hw_i2c_write(uint8_t dev_addr, uint8_t reg, const uint8_t *data, uint16_t len)
{
    (void)dev_addr; (void)reg; (void)data; (void)len;
    return true;   /* konfigürasyon yazmaları sessizce kabul */
}

bool hw_i2c_read(uint8_t dev_addr, uint8_t reg, uint8_t *data, uint16_t len)
{
    (void)dev_addr;

    if (reg == 0x75) {          /* WHO_AM_I */
        data[0] = 0x68;
        return true;
    }

    if (reg == 0x3B && len == 14) {
        update_sensors_from_jsbsim();

        /* JSBSim açılarından ham ivmeölçer değerleri oluştur (yerçekimi projeksiyonu) */
        float ax = (float)(g_sensors.ax_ms2  / 9.80665 * 8192.0);
        float ay = (float)(g_sensors.ay_ms2  / 9.80665 * 8192.0);
        float az = (float)(g_sensors.az_ms2  / 9.80665 * 8192.0);
        float gx = (float)(g_sensors.roll_rate_rads  / 0.00106522);
        float gy = (float)(g_sensors.pitch_rate_rads / 0.00106522);
        float gz = (float)(g_sensors.yaw_rate_rads   / 0.00106522);

        int16_t raw_ax = (int16_t)ax;
        int16_t raw_ay = (int16_t)ay;
        int16_t raw_az = (int16_t)az;
        int16_t raw_t  = 0;
        int16_t raw_gx = (int16_t)gx;
        int16_t raw_gy = (int16_t)gy;
        int16_t raw_gz = (int16_t)gz;

        data[0]  = (raw_ax >> 8) & 0xFF; data[1]  = raw_ax & 0xFF;
        data[2]  = (raw_ay >> 8) & 0xFF; data[3]  = raw_ay & 0xFF;
        data[4]  = (raw_az >> 8) & 0xFF; data[5]  = raw_az & 0xFF;
        data[6]  = (raw_t  >> 8) & 0xFF; data[7]  = raw_t  & 0xFF;
        data[8]  = (raw_gx >> 8) & 0xFF; data[9]  = raw_gx & 0xFF;
        data[10] = (raw_gy >> 8) & 0xFF; data[11] = raw_gy & 0xFF;
        data[12] = (raw_gz >> 8) & 0xFF; data[13] = raw_gz & 0xFF;
        return true;
    }

    memset(data, 0, len);
    return true;
}

/* ── UART mock – GPS NMEA cümlesi üretir ─────────────────── */
static char g_gps_buf[256];
static int  g_gps_buf_len = 0;
static int  g_gps_buf_pos = 0;

static uint8_t nmea_cs(const char *s)
{
    uint8_t cs = 0;
    while (*s) cs ^= (uint8_t)(*s++);
    return cs;
}

static void refresh_gps_sentence(void)
{
    /* $GNGGA,HHMMSS.ss,DDMM.mmm,N/S,DDDMM.mmm,E/W,fix,sats,,alt,M,,M,,*cs */
    double lat = g_sensors.lat_deg;
    double lon = g_sensors.lon_deg;
    char lat_h = lat >= 0 ? 'N' : 'S';
    char lon_h = lon >= 0 ? 'E' : 'W';
    if (lat < 0) lat = -lat;
    if (lon < 0) lon = -lon;

    int lat_d = (int)lat;
    double lat_m = (lat - lat_d) * 60.0;
    int lon_d = (int)lon;
    double lon_m = (lon - lon_d) * 60.0;

    char body[200];
    snprintf(body, sizeof(body),
             "GNGGA,120000.00,%02d%08.5f,%c,%03d%08.5f,%c,3,12,,.%.1f,M,,M,,",
             lat_d, lat_m, lat_h,
             lon_d, lon_m, lon_h,
             (double)g_sensors.alt_m);

    g_gps_buf_len = snprintf(g_gps_buf, sizeof(g_gps_buf),
                             "$%s*%02X\r\n", body, nmea_cs(body));
    g_gps_buf_pos = 0;
}

bool hw_uart_write(const uint8_t *data, uint16_t len)
{
    (void)data; (void)len;
    return true;
}

uint16_t hw_uart_read(uint8_t *buf, uint16_t max_len)
{
    if (g_gps_buf_pos >= g_gps_buf_len) {
        refresh_gps_sentence();
    }
    uint16_t avail = (uint16_t)(g_gps_buf_len - g_gps_buf_pos);
    uint16_t n = avail < max_len ? avail : max_len;
    memcpy(buf, g_gps_buf + g_gps_buf_pos, n);
    g_gps_buf_pos += n;
    return n;
}

/* ── PWM mock – kontrol paketini JSBSim'e gönderir ──────── */
void hw_pwm_set_pulse_us(uint8_t channel, uint16_t pulse_us)
{
    float norm = (pulse_us - 1500.0f) / 500.0f;  /* -1…+1 */
    float thr  = (pulse_us - 1000.0f) / 1000.0f; /* 0…1   */

    switch (channel) {
        case 0: g_controls.aileron  =  norm; break;
        case 1: g_controls.aileron  = -norm; break;  /* ters aileron */
        case 2: g_controls.elevator =  norm; break;
        case 3: g_controls.rudder   =  norm; break;
        case 4: g_controls.throttle =  thr;  break;
    }

    /* Her throttle yazımında paketi gönder (400 Hz) */
    if (channel == 4 && g_send_sock >= 0) {
        sendto(g_send_sock, &g_controls, sizeof(g_controls), 0,
               (struct sockaddr *)&g_jsbsim_addr, sizeof(g_jsbsim_addr));
    }
}

/* ── Log ─────────────────────────────────────────────────── */
void hw_log(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    fflush(stdout);
}

/* ── Simülasyon başlatma (sim_main.c'den çağrılır) ──────── */
void mock_hal_init(void)
{
    /* Alıcı soket */
    g_recv_sock = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in bind_addr = {0};
    bind_addr.sin_family      = AF_INET;
    bind_addr.sin_addr.s_addr = INADDR_ANY;
    bind_addr.sin_port        = htons(SIM_RECV_PORT);
    bind(g_recv_sock, (struct sockaddr *)&bind_addr, sizeof(bind_addr));

    /* Gönderici soket */
    g_send_sock = socket(AF_INET, SOCK_DGRAM, 0);
    g_jsbsim_addr.sin_family      = AF_INET;
    g_jsbsim_addr.sin_addr.s_addr = inet_addr(SIM_HOST);
    g_jsbsim_addr.sin_port        = htons(SIM_SEND_PORT);

    /* İlk sensör paketini sıfırla (yerçekimi -g Z ekseni) */
    memset(&g_sensors, 0, sizeof(g_sensors));
    g_sensors.az_ms2 = -9.80665;
    g_sensors.lat_deg = 41.0;
    g_sensors.lon_deg = 29.0;
    g_sensors.alt_m   = 100.0;

    refresh_gps_sentence();
    printf("[SIM] Mock HAL başlatıldı. UDP %s:%d ← sensör, → kontrol :%d\n",
           SIM_HOST, SIM_RECV_PORT, SIM_SEND_PORT);
}

#endif /* SIMULATION */
