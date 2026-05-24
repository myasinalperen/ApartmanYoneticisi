#ifndef FLIGHT_CONTROL_H
#define FLIGHT_CONTROL_H

#include "imu.h"
#include "gps.h"
#include "pid.h"
#include "rc_input.h"
#include <stdbool.h>

typedef enum {
    MODE_DISARMED  = 0,
    MODE_MANUAL,       /* RC direkt geçiş – saf manuel uçuş      */
    MODE_STABILIZE,    /* FBW-A: RC açı komut verir, PID tutar    */
    MODE_AUTO          /* GPS waypoint (ileride)                  */
} FlightMode;

typedef struct {
    /* Aktif mod */
    FlightMode mode;
    bool       armed;

    /* PID – kaskad yapısı */
    PID roll_angle_pid;
    PID roll_rate_pid;
    PID pitch_angle_pid;
    PID pitch_rate_pid;
    PID yaw_rate_pid;

    /* Son hesaplanan çıkışlar (telemetri için) */
    float out_aileron;
    float out_elevator;
    float out_rudder;
    float out_throttle;
} FlightController;

void fc_init   (FlightController *fc);
void fc_update (FlightController *fc, const IMU *imu, const RCInput *rc, float dt);
void fc_arm    (FlightController *fc);
void fc_disarm (FlightController *fc);

const char *fc_mode_str(FlightMode mode);

#endif /* FLIGHT_CONTROL_H */
