#include "rc_input.h"
#include "hal_wrapper.h"
#include <string.h>

void rc_input_init(RCInput *rc)
{
    memset(rc, 0, sizeof(RCInput));
    for (int i = 0; i < IBUS_MAX_CHANNELS; i++)
        rc->ch[i] = IBUS_CH_MID;
    rc->ch[RC_CH_THROTTLE] = IBUS_CH_MIN;  /* throttle sıfırdan başlasın */
    rc->valid = false;
}

bool rc_input_parse(RCInput *rc, const uint8_t *f)
{
    /* Header kontrolü */
    if (f[0] != IBUS_HEADER0 || f[1] != IBUS_HEADER1)
        return false;

    /* Checksum: 0xFFFF − (byte[0..29] toplamı) */
    uint16_t sum = 0;
    for (int i = 0; i < 30; i++) sum += f[i];
    uint16_t cs_recv = (uint16_t)(f[30] | (f[31] << 8));
    if ((uint16_t)(0xFFFF - sum) != cs_recv)
        return false;

    /* 14 kanal, her biri 2 byte LE */
    for (int i = 0; i < IBUS_MAX_CHANNELS; i++) {
        uint16_t v = (uint16_t)(f[2 + i * 2] | (f[3 + i * 2] << 8));
        /* Geçerli aralık: 900–2100 µs */
        if (v < 900 || v > 2100) return false;
        rc->ch[i] = v;
    }

    rc->valid         = true;
    rc->last_frame_ms = hw_get_tick_ms();
    return true;
}

float rc_get_norm(const RCInput *rc, uint8_t ch)
{
    if (ch >= IBUS_MAX_CHANNELS) return 0.0f;
    float v = ((float)rc->ch[ch] - IBUS_CH_MID) / 500.0f;  /* -1.0 … +1.0 */
    if (v >  1.0f) v =  1.0f;
    if (v < -1.0f) v = -1.0f;
    return v;
}

float rc_get_throttle(const RCInput *rc)
{
    float v = ((float)rc->ch[RC_CH_THROTTLE] - IBUS_CH_MIN)
            / (float)(IBUS_CH_MAX - IBUS_CH_MIN);
    if (v > 1.0f) v = 1.0f;
    if (v < 0.0f) v = 0.0f;
    return v;
}

bool rc_is_lost(const RCInput *rc)
{
    return !rc->valid || (hw_get_tick_ms() - rc->last_frame_ms) > 500u;
}
