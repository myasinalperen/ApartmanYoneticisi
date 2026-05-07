#include "servo.h"
#include "hal_wrapper.h"
#include "config.h"
#include <stdint.h>

/* -1…+1 değerini µs'ye dönüştür */
static uint16_t value_to_us(float v)
{
    if (v >  1.0f) v =  1.0f;
    if (v < -1.0f) v = -1.0f;
    return (uint16_t)(SERVO_PULSE_MID_US + v * 500.0f);
}

void servo_init(void)
{
    /* Tüm kanalları nötr pozisyona getir */
    for (uint8_t ch = 0; ch < 4; ch++) {
        hw_pwm_set_pulse_us(ch, SERVO_PULSE_MID_US);
    }
    hw_pwm_set_pulse_us(4, ESC_PULSE_MIN_US);
}

void servo_set(uint8_t channel, float value)
{
    if (channel >= 4) return;

    /* Kanal 1 (aileron sağ) ters bağlı – mekanik düzeltme */
    if (channel == 1) value = -value;

    hw_pwm_set_pulse_us(channel, value_to_us(value));
}

void servo_set_throttle(float value)
{
    if (value < 0.0f) value = 0.0f;
    if (value > 1.0f) value = 1.0f;
    uint16_t us = ESC_PULSE_MIN_US + (uint16_t)(value * (ESC_PULSE_MAX_US - ESC_PULSE_MIN_US));
    hw_pwm_set_pulse_us(4, us);
}

void servo_arm_esc(void)
{
    hw_pwm_set_pulse_us(4, ESC_ARMING_PULSE_US);
}
