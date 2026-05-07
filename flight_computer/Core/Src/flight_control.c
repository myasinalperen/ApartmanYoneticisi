#include "flight_control.h"
#include "servo.h"
#include "config.h"
#include "hal_wrapper.h"
#include <math.h>
#include <string.h>

void fc_init(FlightController *fc)
{
    memset(fc, 0, sizeof(FlightController));
    fc->mode   = MODE_DISARMED;
    fc->armed  = false;

    /* Roll kaskad */
    pid_init(&fc->roll_angle_pid, ROLL_ANGLE_KP, 0.0f, 0.0f, ROLL_ANGLE_MAX_DEG);
    pid_init(&fc->roll_rate_pid,  ROLL_RATE_KP, ROLL_RATE_KI, ROLL_RATE_KD, ROLL_RATE_IMAX);

    /* Pitch kaskad */
    pid_init(&fc->pitch_angle_pid, PITCH_ANGLE_KP, 0.0f, 0.0f, PITCH_ANGLE_MAX_DEG);
    pid_init(&fc->pitch_rate_pid,  PITCH_RATE_KP, PITCH_RATE_KI, PITCH_RATE_KD, PITCH_RATE_IMAX);

    /* Yaw rate */
    pid_init(&fc->yaw_rate_pid, YAW_RATE_KP, YAW_RATE_KI, YAW_RATE_KD, YAW_RATE_IMAX);

    servo_init();
}

void fc_arm(FlightController *fc)
{
    if (fc->armed) return;
    servo_arm_esc();
    hw_delay_ms(2000);
    fc->armed = true;
    fc->mode  = MODE_STABILIZE;
    hw_log("FC: ARMED\n");
}

void fc_disarm(FlightController *fc)
{
    fc->armed    = false;
    fc->mode     = MODE_DISARMED;
    fc->throttle = 0.0f;
    servo_set_throttle(0.0f);
    pid_reset(&fc->roll_rate_pid);
    pid_reset(&fc->pitch_rate_pid);
    pid_reset(&fc->yaw_rate_pid);
    hw_log("FC: DISARMED\n");
}

void fc_update(FlightController *fc, const IMU *imu, float dt)
{
    if (!fc->armed || fc->mode == MODE_DISARMED) return;

    float roll_deg  = imu_roll_deg (imu);
    float pitch_deg = imu_pitch_deg(imu);

    /* Jiroskop hızları (derece/s) */
    float roll_rate_dps  = imu->gyro_x * 57.2957795f;
    float pitch_rate_dps = imu->gyro_y * 57.2957795f;
    float yaw_rate_dps   = imu->gyro_z * 57.2957795f;

    /* ── Roll kaskad ──────────────────────────────────────── */
    float roll_angle_err   = fc->target_roll_deg - roll_deg;
    float roll_rate_target = pid_update(&fc->roll_angle_pid, roll_angle_err, dt);
    float roll_rate_err    = roll_rate_target - roll_rate_dps;
    float aileron_cmd      = pid_update(&fc->roll_rate_pid, roll_rate_err, dt);

    /* ── Pitch kaskad ─────────────────────────────────────── */
    float pitch_angle_err   = fc->target_pitch_deg - pitch_deg;
    float pitch_rate_target = pid_update(&fc->pitch_angle_pid, pitch_angle_err, dt);
    float pitch_rate_err    = pitch_rate_target - pitch_rate_dps;
    float elevator_cmd      = pid_update(&fc->pitch_rate_pid, pitch_rate_err, dt);

    /* ── Yaw rate ─────────────────────────────────────────── */
    float yaw_err    = fc->target_yaw_rate_dps - yaw_rate_dps;
    float rudder_cmd = pid_update(&fc->yaw_rate_pid, yaw_err, dt);

    /* Servo yazma */
    servo_set(0, aileron_cmd);           /* Aileron Sol */
    servo_set(1, aileron_cmd);           /* Aileron Sağ (servo.c ters çevirir) */
    servo_set(2, elevator_cmd);          /* Elevator */
    servo_set(3, rudder_cmd);            /* Rudder */
    servo_set_throttle(fc->throttle);
}

void fc_mix_and_output(const FlightController *fc)
{
    /* fc_update içinde doğrudan yazıldığı için bu fonksiyon
     * ileride diferansiyel thrust gibi özel mikserler için ayrıldı. */
    (void)fc;
}
