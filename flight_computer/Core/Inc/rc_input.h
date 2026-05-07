#ifndef RC_INPUT_H
#define RC_INPUT_H

#include <stdint.h>
#include <stdbool.h>
#include "config.h"

/*
 * SBUS Protokolü:
 *   UART: 100000 baud, 8 bit, Even parity, 2 stop bit, INVERTED sinyal
 *   Çerçeve: 25 byte, 14 ms aralıkla (Futaba) veya 7 ms (high-speed)
 *   16 kanal × 11 bit + 2 dijital kanal + flag byte
 *
 * Donanım notu:
 *   STM32F4'te UART sinyal inversiyonu yoktur.
 *   RC alıcı SBUS çıkışı → NPN inverter (2N2222) → STM32 PA10 (USART1_RX)
 *   Bağlantı şeması: docs/wiring.txt
 */

typedef struct {
    int16_t  raw[RC_CHANNELS];   /* SBUS ham: 172–1811 */
    bool     frame_lost;
    bool     failsafe;
    uint32_t last_frame_ms;      /* son geçerli çerçeve zamanı */
} RCInput;

void  rc_input_init  (RCInput *rc);

/* UART DMA tamponu dolunca çağrılır (ISR veya görev içinden) */
bool  rc_input_parse (RCInput *rc, const uint8_t *frame25);

/* Kanal değeri: -1.0 … 0.0 … +1.0   (throttle için 0.0 … 1.0 kullan) */
float rc_get_norm    (const RCInput *rc, uint8_t ch);

/* Throttle özel: 0.0 … 1.0 */
float rc_get_throttle(const RCInput *rc);

/* RC bağlantısı kesildi mi? (500 ms'den fazla çerçeve yok) */
bool  rc_is_lost     (const RCInput *rc);

#endif /* RC_INPUT_H */
