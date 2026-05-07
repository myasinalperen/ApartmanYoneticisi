#ifndef IMU_H
#define IMU_H

#include <stdbool.h>
#include "madgwick.h"

typedef struct {
    /* Ham okumalar (SI birimleri) */
    float accel_x, accel_y, accel_z;   /* m/s² */
    float gyro_x,  gyro_y,  gyro_z;    /* rad/s */
    float temp_c;

    /* Füzyon çıktısı */
    float roll_rad, pitch_rad, yaw_rad;

    MadgwickFilter filter;
} IMU;

bool imu_init(IMU *imu);
bool imu_update(IMU *imu);   /* 1 kHz görevinden çağrılır */

/* Derece cinsinden yardımcılar */
static inline float imu_roll_deg (const IMU *imu) { return imu->roll_rad  * 57.2957795f; }
static inline float imu_pitch_deg(const IMU *imu) { return imu->pitch_rad * 57.2957795f; }
static inline float imu_yaw_deg  (const IMU *imu) { return imu->yaw_rad   * 57.2957795f; }

#endif /* IMU_H */
