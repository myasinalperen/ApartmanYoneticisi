/*
 * STM32 HAL implementasyonu.
 * Yalnızca gerçek donanım hedefinde derlenir.
 */

#ifndef SIMULATION

#include "hal_wrapper.h"
#include "config.h"
#include <stdarg.h>
#include <stdio.h>

extern I2C_HandleTypeDef  hi2c1;
extern UART_HandleTypeDef huart2;
extern TIM_HandleTypeDef  htim1;
extern TIM_HandleTypeDef  htim3;

/* ── Zaman ───────────────────────────────────────────────── */
uint32_t hw_get_tick_ms(void) { return HAL_GetTick(); }
void     hw_delay_ms(uint32_t ms) { HAL_Delay(ms); }

/* ── I2C ─────────────────────────────────────────────────── */
bool hw_i2c_write(uint8_t dev_addr, uint8_t reg, const uint8_t *data, uint16_t len)
{
    uint8_t buf[len + 1];
    buf[0] = reg;
    for (uint16_t i = 0; i < len; i++) buf[i + 1] = data[i];
    return HAL_I2C_Master_Transmit(&hi2c1, dev_addr, buf, len + 1, 10) == HAL_OK;
}

bool hw_i2c_read(uint8_t dev_addr, uint8_t reg, uint8_t *data, uint16_t len)
{
    if (HAL_I2C_Master_Transmit(&hi2c1, dev_addr, &reg, 1, 10) != HAL_OK)
        return false;
    return HAL_I2C_Master_Receive(&hi2c1, dev_addr, data, len, 10) == HAL_OK;
}

/* ── UART ────────────────────────────────────────────────── */
bool hw_uart_write(const uint8_t *data, uint16_t len)
{
    return HAL_UART_Transmit(&huart2, (uint8_t *)data, len, 100) == HAL_OK;
}

/* DMA ile çalışmak için UART RX FIFO kullanılabilir;
 * basit haliyle polling ile okunur. */
uint16_t hw_uart_read(uint8_t *buf, uint16_t max_len)
{
    uint16_t n = 0;
    while (n < max_len) {
        if (HAL_UART_Receive(&huart2, &buf[n], 1, 1) != HAL_OK) break;
        n++;
    }
    return n;
}

/* ── PWM ─────────────────────────────────────────────────── */
/* Kanal → TIM eşlemesi:
 *   0-3 → TIM1 CH1-CH4 (servo)
 *   4   → TIM3 CH1 (ESC)
 */
void hw_pwm_set_pulse_us(uint8_t channel, uint16_t pulse_us)
{
    static const uint32_t ch_map[] = {
        TIM_CHANNEL_1, TIM_CHANNEL_2, TIM_CHANNEL_3, TIM_CHANNEL_4
    };

    if (channel < 4) {
        __HAL_TIM_SET_COMPARE(&htim1, ch_map[channel], pulse_us);
    } else if (channel == 4) {
        __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, pulse_us);
    }
}

/* ── Log (UART2 → USB-UART adaptör üzerinden PC'ye) ─────── */
void hw_log(const char *fmt, ...)
{
    char buf[128];
    va_list args;
    va_start(args, fmt);
    int n = vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    if (n > 0) HAL_UART_Transmit(&huart2, (uint8_t *)buf, (uint16_t)n, 50);
}

#endif /* !SIMULATION */
