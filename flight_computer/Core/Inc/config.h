#ifndef CONFIG_H
#define CONFIG_H

/* ── Derleme hedefi ─────────────────────────────────────── */
/* PC simülasyonu için: gcc -DSIMULATION ...                 */
/* STM32 için bu flag tanımlı olmaz                          */

/* ── IMU ─────────────────────────────────────────────────── */
#define IMU_SAMPLE_RATE_HZ      1000u
#define IMU_DT                  (1.0f / IMU_SAMPLE_RATE_HZ)
#define MPU6050_I2C_ADDR        (0x68 << 1)   /* AD0=GND */
#define MPU6050_GYRO_FS         250            /* ±250 °/s */
#define MPU6050_ACCEL_FS        4              /* ±4 g     */

/* ── GPS ─────────────────────────────────────────────────── */
#define GPS_BAUDRATE            115200u
#define GPS_UPDATE_RATE_HZ      10u

/* ── Servo PWM (50 Hz, 1000–2000 µs) ────────────────────── */
#define SERVO_PWM_FREQ_HZ       400u
#define SERVO_PULSE_MIN_US      1000u
#define SERVO_PULSE_MID_US      1500u
#define SERVO_PULSE_MAX_US      2000u

/* ── ESC (Brushless) ─────────────────────────────────────── */
#define ESC_PWM_FREQ_HZ         400u
#define ESC_PULSE_MIN_US        1000u
#define ESC_PULSE_MAX_US        2000u
#define ESC_ARMING_PULSE_US     1000u

/* ── Kontrol döngüsü ─────────────────────────────────────── */
#define CTRL_LOOP_RATE_HZ       400u
#define CTRL_DT                 (1.0f / CTRL_LOOP_RATE_HZ)

/* ── PID – Roll (aileron) ────────────────────────────────── */
#define ROLL_RATE_KP            0.15f
#define ROLL_RATE_KI            0.05f
#define ROLL_RATE_KD            0.004f
#define ROLL_RATE_IMAX          0.3f

#define ROLL_ANGLE_KP           5.0f
#define ROLL_ANGLE_MAX_DEG      45.0f

/* ── PID – Pitch (elevator) ──────────────────────────────── */
#define PITCH_RATE_KP           0.18f
#define PITCH_RATE_KI           0.06f
#define PITCH_RATE_KD            0.005f
#define PITCH_RATE_IMAX         0.3f

#define PITCH_ANGLE_KP          5.0f
#define PITCH_ANGLE_MAX_DEG     30.0f

/* ── PID – Yaw (rudder) ──────────────────────────────────── */
#define YAW_RATE_KP             0.20f
#define YAW_RATE_KI             0.04f
#define YAW_RATE_KD             0.003f
#define YAW_RATE_IMAX           0.4f

/* ── Madgwick filtresi ───────────────────────────────────── */
#define MADGWICK_BETA           0.1f

/* ── FreeRTOS görev öncelikleri ──────────────────────────── */
#define TASK_PRIO_IMU           5
#define TASK_PRIO_CONTROL       4
#define TASK_PRIO_GPS           3
#define TASK_PRIO_TELEMETRY     1

/* ── Simülasyon UDP portları ─────────────────────────────── */
#define SIM_RECV_PORT           5500    /* JSBSim → biz */
#define SIM_SEND_PORT           5501    /* biz → JSBSim */
#define SIM_HOST                "127.0.0.1"

#endif /* CONFIG_H */
