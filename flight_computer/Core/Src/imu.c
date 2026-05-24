#include "imu.h"
#include "hal_wrapper.h"
#include "config.h"
#include <string.h>

/* MPU6050 register haritası */
#define REG_PWR_MGMT_1      0x6B
#define REG_SMPLRT_DIV      0x19
#define REG_CONFIG          0x1A
#define REG_GYRO_CONFIG     0x1B
#define REG_ACCEL_CONFIG    0x1C
#define REG_ACCEL_XOUT_H    0x3B
#define REG_WHO_AM_I        0x75

#define ACCEL_SCALE         (9.80665f / 8192.0f)   /* ±4g → LSB/g = 8192 */
#define GYRO_SCALE          (0.00106522f)           /* ±250°/s → rad/s    */

static bool mpu6050_write_reg(uint8_t reg, uint8_t val)
{
    return hw_i2c_write(MPU6050_I2C_ADDR, reg, &val, 1);
}

bool imu_init(IMU *imu)
{
    memset(imu, 0, sizeof(IMU));
    madgwick_init(&imu->filter, MADGWICK_BETA);

    /* Cihaz kimliği doğrula */
    uint8_t who_am_i = 0;
    if (!hw_i2c_read(MPU6050_I2C_ADDR, REG_WHO_AM_I, &who_am_i, 1)) return false;
    if (who_am_i != 0x68) return false;

    /* Uyku modundan çık, dahili 8 MHz osilatör */
    if (!mpu6050_write_reg(REG_PWR_MGMT_1, 0x00)) return false;
    hw_delay_ms(100);

    /* Örnekleme hızı: 1 kHz / (1 + 0) = 1 kHz */
    if (!mpu6050_write_reg(REG_SMPLRT_DIV, 0x00)) return false;

    /* DLPF: 94 Hz bant genişliği (gyro), jitter azaltır */
    if (!mpu6050_write_reg(REG_CONFIG, 0x02)) return false;

    /* Jiroskop ±250 °/s */
    if (!mpu6050_write_reg(REG_GYRO_CONFIG, 0x00)) return false;

    /* İvmeölçer ±4 g */
    if (!mpu6050_write_reg(REG_ACCEL_CONFIG, 0x08)) return false;

    return true;
}

bool imu_update(IMU *imu)
{
    uint8_t buf[14];

    /* 14 byte burst okuma: ACCEL_X_H … TEMP_L … GYRO_Z_L */
    if (!hw_i2c_read(MPU6050_I2C_ADDR, REG_ACCEL_XOUT_H, buf, 14)) return false;

    int16_t ax_raw = (int16_t)((buf[0]  << 8) | buf[1]);
    int16_t ay_raw = (int16_t)((buf[2]  << 8) | buf[3]);
    int16_t az_raw = (int16_t)((buf[4]  << 8) | buf[5]);
    int16_t t_raw  = (int16_t)((buf[6]  << 8) | buf[7]);
    int16_t gx_raw = (int16_t)((buf[8]  << 8) | buf[9]);
    int16_t gy_raw = (int16_t)((buf[10] << 8) | buf[11]);
    int16_t gz_raw = (int16_t)((buf[12] << 8) | buf[13]);

    imu->accel_x = ax_raw * ACCEL_SCALE;
    imu->accel_y = ay_raw * ACCEL_SCALE;
    imu->accel_z = az_raw * ACCEL_SCALE;
    imu->gyro_x  = gx_raw * GYRO_SCALE;
    imu->gyro_y  = gy_raw * GYRO_SCALE;
    imu->gyro_z  = gz_raw * GYRO_SCALE;
    imu->temp_c  = t_raw / 340.0f + 36.53f;

    madgwick_update(&imu->filter,
                    imu->accel_x, imu->accel_y, imu->accel_z,
                    imu->gyro_x,  imu->gyro_y,  imu->gyro_z,
                    IMU_DT);

    madgwick_get_euler(&imu->filter,
                       &imu->roll_rad, &imu->pitch_rad, &imu->yaw_rad);
    return true;
}
