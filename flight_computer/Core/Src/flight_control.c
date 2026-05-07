#include "flight_control.h"
#include "servo.h"
#include "config.h"
#include "hal_wrapper.h"
#include <math.h>
#include <string.h>

void fc_init(FlightController *fc)
{
    memset(fc, 0, sizeof(FlightController));
    fc->mode  = MODE_DISARMED;
    fc->armed = false;

    pid_init(&fc->roll_angle_pid,  ROLL_ANGLE_KP,  0.0f,         0.0f,         STAB_MAX_ROLL_DEG);
    pid_init(&fc->roll_rate_pid,   ROLL_RATE_KP,   ROLL_RATE_KI, ROLL_RATE_KD, ROLL_RATE_IMAX);
    pid_init(&fc->pitch_angle_pid, PITCH_ANGLE_KP, 0.0f,         0.0f,         STAB_MAX_PITCH_DEG);
    pid_init(&fc->pitch_rate_pid,  PITCH_RATE_KP,  PITCH_RATE_KI,PITCH_RATE_KD,PITCH_RATE_IMAX);
    pid_init(&fc->yaw_rate_pid,    YAW_RATE_KP,    YAW_RATE_KI,  YAW_RATE_KD,  YAW_RATE_IMAX);

    servo_init();
}

void fc_arm(FlightController *fc)
{
    if (fc->armed) return;
    servo_arm_esc();
    hw_delay_ms(2000);
    fc->armed = true;
    fc->mode  = MODE_MANUAL;
    hw_log("FC: ARMED – mod MANUAL\n");
}

void fc_disarm(FlightController *fc)
{
    fc->armed        = false;
    fc->mode         = MODE_DISARMED;
    fc->out_throttle = 0.0f;
    servo_set_throttle(0.0f);
    pid_reset(&fc->roll_rate_pid);
    pid_reset(&fc->pitch_rate_pid);
    pid_reset(&fc->yaw_rate_pid);
    hw_log("FC: DISARMED\n");
}

const char *fc_mode_str(FlightMode mode)
{
    switch (mode) {
        case MODE_DISARMED:  return "DISARMED";
        case MODE_MANUAL:    return "MANUAL";
        case MODE_STABILIZE: return "STABILIZE";
        case MODE_AUTO:      return "AUTO";
        default:             return "UNKNOWN";
    }
}

/* ── Arm/Disarm mantığı ──────────────────────────────────── */
static void handle_arming(FlightController *fc, const RCInput *rc)
{
    bool arm_sw = rc_get_norm(rc, RC_CH_ARM) > 0.5f;

    if (arm_sw && !fc->armed)       fc_arm(fc);
    else if (!arm_sw && fc->armed)  fc_disarm(fc);
}

/* ── Mod seçimi ──────────────────────────────────────────── */
static FlightMode select_mode(const RCInput *rc)
{
    /* Kanal 5 (RC_CH_MODE):
     *   < -0.5 → MANUAL
     *   > +0.5 → STABILIZE  */
    float sw = rc_get_norm(rc, RC_CH_MODE);
    return (sw > 0.0f) ? MODE_STABILIZE : MODE_MANUAL;
}

/* ── Failsafe ─────────────────────────────────────────────
 * RC kesilince uçak düz uçuşa geçer, throttle'ı korur.   */
static void apply_failsafe(FlightController *fc)
{
    static FlightMode prev_mode = MODE_DISARMED;
    if (prev_mode != MODE_STABILIZE) {
        hw_log("FC: FAILSAFE – RC kayboldu\n");
        prev_mode = MODE_STABILIZE;
    }
    fc->mode = MODE_STABILIZE;

    /* Mevcut throttle'ı koru; yavaşça failsafe değerine çek */
    if (fc->out_throttle > FAILSAFE_THROTTLE)
        fc->out_throttle -= 0.001f;
    else
        fc->out_throttle = FAILSAFE_THROTTLE;

    /* Kanatları düzelt */
    float roll_deg   = 0.0f;          /* düz kanat */
    float pitch_deg  = FAILSAFE_PITCH_DEG;
    float yaw_rate   = 0.0f;

    (void)roll_deg; (void)pitch_deg; (void)yaw_rate;
    /* Gerçek PID hesabı aşağıdaki STABILIZE bloğunda yapılır,
     * bu değerler fc->out_* üzerine yazılmış olur. */
}

/* ── Ana güncelleme ──────────────────────────────────────── */
void fc_update(FlightController *fc, const IMU *imu, const RCInput *rc, float dt)
{
    /* Arm/disarm kontrolü her döngüde */
    handle_arming(fc, rc);

    if (!fc->armed) return;

    /* RC kaybı → failsafe */
    if (rc_is_lost(rc)) {
        apply_failsafe(fc);
        /* Failsafe'de de PID çalışsın – mod STABILIZE'a çekildi */
    } else {
        fc->mode = select_mode(rc);
    }

    float roll_deg       = imu_roll_deg(imu);
    float pitch_deg      = imu_pitch_deg(imu);
    float roll_rate_dps  = imu->gyro_x * 57.2957795f;
    float pitch_rate_dps = imu->gyro_y * 57.2957795f;
    float yaw_rate_dps   = imu->gyro_z * 57.2957795f;

    switch (fc->mode) {

    /* ── MANUAL: RC doğrudan servo'ya ────────────────────── */
    case MODE_MANUAL:
        fc->out_aileron  = rc_get_norm(rc, RC_CH_AILERON);
        fc->out_elevator = rc_get_norm(rc, RC_CH_ELEVATOR);
        fc->out_rudder   = rc_get_norm(rc, RC_CH_RUDDER);
        fc->out_throttle = rc_get_throttle(rc);

        pid_reset(&fc->roll_rate_pid);
        pid_reset(&fc->pitch_rate_pid);
        pid_reset(&fc->yaw_rate_pid);
        break;

    /* ── STABILIZE (FBW-A): RC açı komutu, PID tamamlar ─── */
    case MODE_STABILIZE: {
        float target_roll, target_pitch, target_yaw_rate;

        if (rc_is_lost(rc)) {
            target_roll      = 0.0f;
            target_pitch     = FAILSAFE_PITCH_DEG;
            target_yaw_rate  = 0.0f;
        } else {
            target_roll     = rc_get_norm(rc, RC_CH_AILERON)  * STAB_MAX_ROLL_DEG;
            target_pitch    = rc_get_norm(rc, RC_CH_ELEVATOR) * STAB_MAX_PITCH_DEG;
            target_yaw_rate = rc_get_norm(rc, RC_CH_RUDDER)   * STAB_MAX_YAW_RATE_DPS;
            fc->out_throttle = rc_get_throttle(rc);
        }

        /* Roll kaskad: açı → rate setpoint → aileron */
        float roll_rate_sp = pid_update(&fc->roll_angle_pid,
                                        target_roll - roll_deg, dt);
        fc->out_aileron    = pid_update(&fc->roll_rate_pid,
                                        roll_rate_sp - roll_rate_dps, dt);

        /* Pitch kaskad: açı → rate setpoint → elevator */
        float pitch_rate_sp = pid_update(&fc->pitch_angle_pid,
                                         target_pitch - pitch_deg, dt);
        fc->out_elevator    = pid_update(&fc->pitch_rate_pid,
                                         pitch_rate_sp - pitch_rate_dps, dt);

        /* Yaw rate doğrudan */
        fc->out_rudder = pid_update(&fc->yaw_rate_pid,
                                    target_yaw_rate - yaw_rate_dps, dt);
        break;
    }

    default:
        return;
    }

    /* ── Servo çıkışları yaz ──────────────────────────────── */
    servo_set(0, fc->out_aileron);
    servo_set(1, fc->out_aileron);   /* servo.c ters çevirir */
    servo_set(2, fc->out_elevator);
    servo_set(3, fc->out_rudder);
    servo_set_throttle(fc->out_throttle);
}
