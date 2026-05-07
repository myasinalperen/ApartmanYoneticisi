#ifndef GPS_H
#define GPS_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    double  lat;            /* derece, K=+ G=- */
    double  lon;            /* derece, D=+ B=- */
    float   alt_m;          /* deniz seviyesinden yükseklik (m) */
    float   speed_ms;       /* yüzey hızı (m/s) */
    float   course_deg;     /* iz açısı (°, kuzey=0) */
    uint8_t satellites;
    bool    fix_valid;
    uint8_t fix_type;       /* 0=yok, 2=2D, 3=3D */
} GPSData;

bool gps_init(void);

/* GPS UART arabelleğinden okur, NMEA ayrıştırır.
 * Yeni geçerli konum geldiğinde true döner. */
bool gps_update(GPSData *gps);

#endif /* GPS_H */
