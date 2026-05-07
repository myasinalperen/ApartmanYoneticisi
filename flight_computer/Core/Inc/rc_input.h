#ifndef RC_INPUT_H
#define RC_INPUT_H

#include <stdint.h>
#include <stdbool.h>
#include "config.h"

/*
 * FlySky iBUS Protokolü:
 *   UART: 115200 baud, 8N1, NORMAL lojik (inverter GEREKMİYOR!)
 *   Çerçeve: 32 byte, her ~7 ms
 *   Format:
 *     [0]    0x20  (uzunluk)
 *     [1]    0x40  (komut: kanal verisi)
 *     [2-3]  CH1   (uint16 LE, 1000–2000 µs)
 *     [4-5]  CH2
 *     ...
 *     [28-29] CH14
 *     [30-31] checksum (0xFFFF - sum of bytes 0..29)
 *
 *   Desteklenen alıcılar: FlySky FS-iA6B, FS-iA10, FS-X6B vb.
 *   Bağlantı: Alıcı IBUS pini → STM32 PA10 (USART1_RX)  DOĞRUDAN
 */

#define IBUS_FRAME_LEN      32
#define IBUS_CMD_SENSORS    0x80   /* sensör verisi – kullanılmaz */
#define IBUS_CMD_CHANNELS   0x40   /* kanal verisi */
#define IBUS_HEADER0        0x20
#define IBUS_HEADER1        IBUS_CMD_CHANNELS
#define IBUS_CH_MIN         1000
#define IBUS_CH_MID         1500
#define IBUS_CH_MAX         2000
#define IBUS_MAX_CHANNELS   14

typedef struct {
    uint16_t ch[IBUS_MAX_CHANNELS];  /* µs, 1000–2000 */
    bool     valid;
    uint32_t last_frame_ms;
} RCInput;

void  rc_input_init  (RCInput *rc);

/* 32 byte iBUS çerçevesini işle, checksum doğrula */
bool  rc_input_parse (RCInput *rc, const uint8_t *frame32);

/* Kanal değeri: -1.0 (1000µs) … 0.0 (1500µs) … +1.0 (2000µs) */
float rc_get_norm    (const RCInput *rc, uint8_t ch);

/* Throttle: 0.0 (1000µs) … 1.0 (2000µs) */
float rc_get_throttle(const RCInput *rc);

/* 500 ms'den fazla çerçeve gelmediyse true */
bool  rc_is_lost     (const RCInput *rc);

#endif /* RC_INPUT_H */
