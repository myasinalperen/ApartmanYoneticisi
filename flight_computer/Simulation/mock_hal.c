/*
 * PC simülasyonu için sahte HAL implementasyonu.
 *
 * UDP portları:
 *   5500 ← sensör (JSBSim veya test_runner.py)
 *   5501 → kontrol (JSBSim'e)
 *   5502 → JSON telemetri (web / test_runner.py okur)
 *   5503 ← RC kanalları (test_runner.py: 14×uint16 LE, 1000-2000)
 */

#ifdef SIMULATION

#include "hal_wrapper.h"
#include "config.h"
#include "rc_input.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <fcntl.h>

#define RC_UDP_PORT  5503

/* ── Soketler ────────────────────────────────────────────── */
static int g_recv_sock = -1;   /* 5500: sensör gelen */
static int g_send_sock = -1;   /* 5501: kontrol giden */
static int g_rc_sock   = -1;   /* 5503: RC kanalları gelen */
static struct sockaddr_in g_jsbsim_addr;

/* ── Sensör ve kontrol paketleri ─────────────────────────── */
typedef struct __attribute__((packed)) {
    double roll_rad, pitch_rad, yaw_rad;
    double roll_rate_rads, pitch_rate_rads, yaw_rate_rads;
    double ax_ms2, ay_ms2, az_ms2;
    double lat_deg, lon_deg, alt_m, airspeed_ms;
} SimSensorPacket;

typedef struct __attribute__((packed)) {
    float aileron, elevator, rudder, throttle;
} SimControlPacket;

static SimSensorPacket  g_sensors;
static SimControlPacket g_controls;

/* Son gelen RC kanalları (14 kanal, µs) */
static uint16_t g_rc_channels[IBUS_MAX_CHANNELS];
static uint32_t g_rc_last_ms = 0;
static bool     g_rc_received = false;

/* ── Sensörü JSBSim / test_runner'dan güncelle ───────────── */
static void update_sensors_from_udp(void)
{
    SimSensorPacket pkt;
    ssize_t n = recv(g_recv_sock, &pkt, sizeof(pkt), MSG_DONTWAIT);
    if (n == (ssize_t)sizeof(pkt))
        g_sensors = pkt;
}

/* ── RC'yi UDP'den güncelle (test_runner.py gönderir) ───── */
void mock_hal_update_rc(uint16_t *ch_out, uint8_t count, bool *updated)
{
    /* Format: count × uint16_t little-endian (1000–2000 µs) */
    uint8_t buf[IBUS_MAX_CHANNELS * 2];
    ssize_t n = recv(g_rc_sock, buf, sizeof(buf), MSG_DONTWAIT);
    if (n == (ssize_t)(IBUS_MAX_CHANNELS * 2)) {
        for (int i = 0; i < IBUS_MAX_CHANNELS && i < count; i++)
            g_rc_channels[i] = (uint16_t)(buf[i*2] | (buf[i*2+1] << 8));
        g_rc_last_ms  = hw_get_tick_ms();
        g_rc_received = true;
    }
    if (ch_out) {
        memcpy(ch_out, g_rc_channels, count * sizeof(uint16_t));
    }
    if (updated) *updated = g_rc_received &&
                            (hw_get_tick_ms() - g_rc_last_ms) < 500u;
}

/* ── Zaman ───────────────────────────────────────────────── */
uint32_t hw_get_tick_ms(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint32_t)(tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void hw_delay_ms(uint32_t ms) { usleep(ms * 1000); }

/* ── I2C mock: MPU6050 ───────────────────────────────────── */
bool hw_i2c_write(uint8_t dev_addr, uint8_t reg, const uint8_t *data, uint16_t len)
{
    (void)dev_addr; (void)reg; (void)data; (void)len;
    return true;
}

bool hw_i2c_read(uint8_t dev_addr, uint8_t reg, uint8_t *data, uint16_t len)
{
    (void)dev_addr;

    if (reg == 0x75) { data[0] = 0x68; return true; }  /* WHO_AM_I */

    if (reg == 0x3B && len == 14) {
        update_sensors_from_udp();

        float ax = (float)(g_sensors.ax_ms2  / 9.80665 * 8192.0);
        float ay = (float)(g_sensors.ay_ms2  / 9.80665 * 8192.0);
        float az = (float)(g_sensors.az_ms2  / 9.80665 * 8192.0);
        float gx = (float)(g_sensors.roll_rate_rads  / 0.00106522);
        float gy = (float)(g_sensors.pitch_rate_rads / 0.00106522);
        float gz = (float)(g_sensors.yaw_rate_rads   / 0.00106522);

        int16_t rax=(int16_t)ax, ray=(int16_t)ay, raz=(int16_t)az;
        int16_t rgx=(int16_t)gx, rgy=(int16_t)gy, rgz=(int16_t)gz;

        data[0]=(rax>>8)&0xFF; data[1]=rax&0xFF;
        data[2]=(ray>>8)&0xFF; data[3]=ray&0xFF;
        data[4]=(raz>>8)&0xFF; data[5]=raz&0xFF;
        data[6]=0;             data[7]=0;
        data[8]=(rgx>>8)&0xFF; data[9]=rgx&0xFF;
        data[10]=(rgy>>8)&0xFF;data[11]=rgy&0xFF;
        data[12]=(rgz>>8)&0xFF;data[13]=rgz&0xFF;
        return true;
    }
    memset(data, 0, len);
    return true;
}

/* ── UART mock: GPS NMEA ─────────────────────────────────── */
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
    double lat = g_sensors.lat_deg, lon = g_sensors.lon_deg;
    char lath = lat >= 0 ? 'N' : 'S', lonh = lon >= 0 ? 'E' : 'W';
    if (lat < 0) lat = -lat;
    if (lon < 0) lon = -lon;
    int latd = (int)lat, lond = (int)lon;
    double latm = (lat-latd)*60.0, lonm = (lon-lond)*60.0;
    char body[200];
    snprintf(body, sizeof(body),
             "GNGGA,120000.00,%02d%08.5f,%c,%03d%08.5f,%c,3,12,,%.1f,M,,M,,",
             latd, latm, lath, lond, lonm, lonh, (double)g_sensors.alt_m);
    g_gps_buf_len = snprintf(g_gps_buf, sizeof(g_gps_buf),
                             "$%s*%02X\r\n", body, nmea_cs(body));
    g_gps_buf_pos = 0;
}

bool     hw_uart_write(const uint8_t *d, uint16_t l) { (void)d;(void)l; return true; }

uint16_t hw_uart_read(uint8_t *buf, uint16_t max_len)
{
    if (g_gps_buf_pos >= g_gps_buf_len) refresh_gps_sentence();
    uint16_t avail = (uint16_t)(g_gps_buf_len - g_gps_buf_pos);
    uint16_t n = avail < max_len ? avail : max_len;
    memcpy(buf, g_gps_buf + g_gps_buf_pos, n);
    g_gps_buf_pos += n;
    return n;
}

/* ── PWM mock ────────────────────────────────────────────── */
void hw_pwm_set_pulse_us(uint8_t channel, uint16_t pulse_us)
{
    float norm = (pulse_us - 1500.0f) / 500.0f;
    float thr  = (pulse_us - 1000.0f) / 1000.0f;
    switch (channel) {
        case 0: g_controls.aileron  =  norm; break;
        case 1: g_controls.aileron  = -norm; break;
        case 2: g_controls.elevator =  norm; break;
        case 3: g_controls.rudder   =  norm; break;
        case 4: g_controls.throttle =  thr;  break;
    }
    if (channel == 4 && g_send_sock >= 0)
        sendto(g_send_sock, &g_controls, sizeof(g_controls), 0,
               (struct sockaddr *)&g_jsbsim_addr, sizeof(g_jsbsim_addr));
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

/* ── mock_hal_init ───────────────────────────────────────── */
void mock_hal_init(void)
{
    /* Sensör alma soketi (5500) */
    g_recv_sock = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in a = {0};
    a.sin_family = AF_INET; a.sin_addr.s_addr = INADDR_ANY;
    a.sin_port = htons(SIM_RECV_PORT);
    bind(g_recv_sock, (struct sockaddr *)&a, sizeof(a));

    /* Kontrol gönderme soketi (5501) */
    g_send_sock = socket(AF_INET, SOCK_DGRAM, 0);
    g_jsbsim_addr.sin_family      = AF_INET;
    g_jsbsim_addr.sin_addr.s_addr = inet_addr(SIM_HOST);
    g_jsbsim_addr.sin_port        = htons(SIM_SEND_PORT);

    /* RC alma soketi (5503) – non-blocking */
    g_rc_sock = socket(AF_INET, SOCK_DGRAM, 0);
    a.sin_port = htons(RC_UDP_PORT);
    bind(g_rc_sock, (struct sockaddr *)&a, sizeof(a));
    fcntl(g_rc_sock, F_SETFL, fcntl(g_rc_sock, F_GETFL, 0) | O_NONBLOCK);

    /* RC varsayılanları: tüm kanallar orta, throttle min */
    for (int i = 0; i < IBUS_MAX_CHANNELS; i++) g_rc_channels[i] = 1500;
    g_rc_channels[RC_CH_THROTTLE] = 1000;

    /* Sensör sıfırla */
    memset(&g_sensors, 0, sizeof(g_sensors));
    g_sensors.az_ms2  = +9.80665;   /* MPU6050 Z↑: reads +g at rest */
    g_sensors.lat_deg = 41.0;
    g_sensors.lon_deg = 29.0;
    g_sensors.alt_m   = 100.0;
    refresh_gps_sentence();

    printf("[SIM] Portlar → Sensör:%d  Kontrol:%d  RC-in:%d  Telemetri:5502\n",
           SIM_RECV_PORT, SIM_SEND_PORT, RC_UDP_PORT);
}

#endif /* SIMULATION */
