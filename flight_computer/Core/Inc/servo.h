#ifndef SERVO_H
#define SERVO_H

#include <stdbool.h>
#include <stdint.h>

/*
 * Kanal atamaları:
 *   0 → Aileron Sol
 *   1 → Aileron Sağ (ters)
 *   2 → Elevator
 *   3 → Rudder
 *   4 → Throttle (ESC)
 */

void servo_init(void);

/* value: -1.0 (tam sol/aşağı) … 0.0 (nötr) … +1.0 (tam sağ/yukarı) */
void servo_set(uint8_t channel, float value);

/* Throttle: 0.0 (dur) … 1.0 (tam gaz) */
void servo_set_throttle(float value);

/* ESC arming sinyali (1000 µs, ~2 saniye beklemeyi çağıran bekler) */
void servo_arm_esc(void);

#endif /* SERVO_H */
