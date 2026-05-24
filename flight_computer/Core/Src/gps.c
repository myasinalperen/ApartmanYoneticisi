#include "gps.h"
#include "hal_wrapper.h"
#include "config.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NMEA_BUF_SIZE   256
#define MAX_FIELDS      20

static char  nmea_buf[NMEA_BUF_SIZE];
static int   nmea_len = 0;

/* ── UBX konfigürasyon komutu gönder ────────────────────── */

static void ubx_send(const uint8_t *msg, uint16_t len)
{
    hw_uart_write(msg, len);
}

static void configure_ublox(void)
{
    /* $PUBX,40,GGA,0,1,0,0,0,0 → GGA 1 Hz etkin */
    const uint8_t gga_on[] =
        "$PUBX,40,GGA,0,1,0,0,0,0*5A\r\n";
    /* Gereksiz cümleleri kapat */
    const uint8_t gsv_off[] =
        "$PUBX,40,GSV,0,0,0,0,0,0*59\r\n";
    const uint8_t gll_off[] =
        "$PUBX,40,GLL,0,0,0,0,0,0*5C\r\n";
    const uint8_t vtg_on[] =
        "$PUBX,40,VTG,0,1,0,0,0,0*5F\r\n";

    ubx_send(gsv_off, sizeof(gsv_off) - 1);
    hw_delay_ms(50);
    ubx_send(gll_off, sizeof(gll_off) - 1);
    hw_delay_ms(50);
    ubx_send(gga_on,  sizeof(gga_on)  - 1);
    hw_delay_ms(50);
    ubx_send(vtg_on,  sizeof(vtg_on)  - 1);
    hw_delay_ms(50);
}

bool gps_init(void)
{
    configure_ublox();
    return true;
}

/* ── NMEA yardımcıları ───────────────────────────────────── */

static uint8_t nmea_checksum(const char *s)
{
    uint8_t cs = 0;
    while (*s && *s != '*') cs ^= (uint8_t)(*s++);
    return cs;
}

static bool nmea_valid(const char *sentence)
{
    if (sentence[0] != '$') return false;
    const char *star = strchr(sentence, '*');
    if (!star || strlen(star) < 3) return false;
    uint8_t expected = (uint8_t)strtol(star + 1, NULL, 16);
    return nmea_checksum(sentence + 1) == expected;
}

static int split_csv(char *line, char *fields[], int max_fields)
{
    int n = 0;
    fields[n++] = line;
    while (*line && n < max_fields) {
        if (*line == ',' || *line == '*') {
            *line = '\0';
            fields[n++] = line + 1;
        }
        line++;
    }
    return n;
}

/* ddmm.mmmmm → derece */
static double nmea_coord(const char *s)
{
    if (!s || !*s) return 0.0;
    double raw = atof(s);
    int    deg = (int)(raw / 100);
    return deg + (raw - deg * 100.0) / 60.0;
}

static bool parse_gga(char *buf, GPSData *gps)
{
    char *fields[MAX_FIELDS];
    if (split_csv(buf, fields, MAX_FIELDS) < 10) return false;

    gps->fix_type   = atoi(fields[6]);
    gps->fix_valid  = (gps->fix_type >= 1);
    gps->satellites = atoi(fields[7]);

    if (!gps->fix_valid) return false;

    gps->lat   = nmea_coord(fields[2]);
    if (fields[3][0] == 'S') gps->lat = -gps->lat;

    gps->lon   = nmea_coord(fields[4]);
    if (fields[5][0] == 'W') gps->lon = -gps->lon;

    gps->alt_m = strtof(fields[9], NULL);
    return true;
}

static bool parse_vtg(char *buf, GPSData *gps)
{
    char *fields[MAX_FIELDS];
    if (split_csv(buf, fields, MAX_FIELDS) < 8) return false;

    gps->course_deg = strtof(fields[1], NULL);
    gps->speed_ms   = strtof(fields[7], NULL) * 0.27778f; /* km/h → m/s */
    return true;
}

/* ── Ana güncelleme ──────────────────────────────────────── */

bool gps_update(GPSData *gps)
{
    uint8_t tmp[64];
    uint16_t n = hw_uart_read(tmp, sizeof(tmp));

    bool got_fix = false;

    for (uint16_t i = 0; i < n; i++) {
        char c = (char)tmp[i];
        if (c == '$') {
            nmea_len = 0;
        }
        if (nmea_len < NMEA_BUF_SIZE - 1) {
            nmea_buf[nmea_len++] = c;
        }
        if (c == '\n') {
            nmea_buf[nmea_len] = '\0';
            if (!nmea_valid(nmea_buf)) { nmea_len = 0; continue; }

            /* Cümle tipini belirle */
            char copy[NMEA_BUF_SIZE];
            strncpy(copy, nmea_buf + 1, sizeof(copy) - 1);

            if (strncmp(copy, "GPGGA", 5) == 0 ||
                strncmp(copy, "GNGGA", 5) == 0) {
                if (parse_gga(copy, gps)) got_fix = true;
            } else if (strncmp(copy, "GPVTG", 5) == 0 ||
                       strncmp(copy, "GNVTG", 5) == 0) {
                parse_vtg(copy, gps);
            }
            nmea_len = 0;
        }
    }
    return got_fix;
}
