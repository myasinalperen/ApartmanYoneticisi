#ifndef HAL_WRAPPER_H
#define HAL_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

/*
 * Donanım soyutlama katmanı.
 * STM32 hedefinde gerçek HAL fonksiyonlarını çağırır.
 * SIMULATION tanımlıysa mock_hal.c implementasyonları kullanılır.
 */

#ifdef SIMULATION
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <time.h>
  #include <unistd.h>
  typedef uint32_t HAL_StatusTypeDef;
  #define HAL_OK    0
  #define HAL_ERROR 1
#else
  #include "stm32f4xx_hal.h"
  extern I2C_HandleTypeDef  hi2c1;
  extern UART_HandleTypeDef huart2;
  extern TIM_HandleTypeDef  htim1;
  extern TIM_HandleTypeDef  htim3;
#endif

/* ── Zaman ───────────────────────────────────────────────── */
uint32_t hw_get_tick_ms(void);
void     hw_delay_ms(uint32_t ms);

/* ── I2C (MPU6050) ───────────────────────────────────────── */
bool hw_i2c_write(uint8_t dev_addr, uint8_t reg, const uint8_t *data, uint16_t len);
bool hw_i2c_read (uint8_t dev_addr, uint8_t reg, uint8_t *data,       uint16_t len);

/* ── UART (GPS) ──────────────────────────────────────────── */
bool     hw_uart_write(const uint8_t *data, uint16_t len);
uint16_t hw_uart_read (uint8_t *buf, uint16_t max_len);

/* ── PWM (Servo + ESC) ───────────────────────────────────── */
/* kanal: 0=aileron_sol, 1=aileron_sag, 2=elevator, 3=rudder, 4=throttle */
void hw_pwm_set_pulse_us(uint8_t channel, uint16_t pulse_us);

/* ── Debug/Log ───────────────────────────────────────────── */
void hw_log(const char *fmt, ...);

#endif /* HAL_WRAPPER_H */
