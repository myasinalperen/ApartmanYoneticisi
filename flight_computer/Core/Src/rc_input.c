#include "rc_input.h"
#include "hal_wrapper.h"
#include <string.h>

void rc_input_init(RCInput *rc)
{
    memset(rc, 0, sizeof(RCInput));
    /* Ortayı göster – güvenli başlangıç */
    for (int i = 0; i < RC_CHANNELS; i++)
        rc->raw[i] = (SBUS_RAW_MIN + SBUS_RAW_MAX) / 2;
    rc->failsafe = true;   /* bağlantı kurulana kadar failsafe'de kal */
}

bool rc_input_parse(RCInput *rc, const uint8_t *f)
{
    if (f[0] != SBUS_START_BYTE || f[24] != SBUS_END_BYTE)
        return false;

    /* 16 kanal, her biri 11 bit, bitfield paketleme */
    rc->raw[0]  = ((f[1]       | f[2]  << 8)                    & 0x7FF);
    rc->raw[1]  = ((f[2]  >> 3 | f[3]  << 5)                    & 0x7FF);
    rc->raw[2]  = ((f[3]  >> 6 | f[4]  << 2 | f[5]  << 10)     & 0x7FF);
    rc->raw[3]  = ((f[5]  >> 1 | f[6]  << 7)                    & 0x7FF);
    rc->raw[4]  = ((f[6]  >> 4 | f[7]  << 4)                    & 0x7FF);
    rc->raw[5]  = ((f[7]  >> 7 | f[8]  << 1 | f[9]  << 9)      & 0x7FF);
    rc->raw[6]  = ((f[9]  >> 2 | f[10] << 6)                    & 0x7FF);
    rc->raw[7]  = ((f[10] >> 5 | f[11] << 3)                    & 0x7FF);

    rc->frame_lost    = (f[23] & SBUS_FRAMELOST_FLAG) != 0;
    rc->failsafe      = (f[23] & SBUS_FAILSAFE_FLAG)  != 0;
    rc->last_frame_ms = hw_get_tick_ms();
    return true;
}

float rc_get_norm(const RCInput *rc, uint8_t ch)
{
    if (ch >= RC_CHANNELS) return 0.0f;
    float v = (float)(rc->raw[ch] - SBUS_RAW_MIN)
            / (float)(SBUS_RAW_MAX - SBUS_RAW_MIN);   /* 0.0 … 1.0 */
    v = v * 2.0f - 1.0f;                              /* -1.0 … +1.0 */
    if (v >  1.0f) v =  1.0f;
    if (v < -1.0f) v = -1.0f;
    return v;
}

float rc_get_throttle(const RCInput *rc)
{
    float v = (float)(rc->raw[RC_CH_THROTTLE] - SBUS_RAW_MIN)
            / (float)(SBUS_RAW_MAX - SBUS_RAW_MIN);
    if (v > 1.0f) v = 1.0f;
    if (v < 0.0f) v = 0.0f;
    return v;
}

bool rc_is_lost(const RCInput *rc)
{
    return (hw_get_tick_ms() - rc->last_frame_ms) > 500u;
}
