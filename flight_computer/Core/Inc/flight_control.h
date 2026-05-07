#ifndef FLIGHT_CONTROL_H
#define FLIGHT_CONTROL_H

#include "imu.h"
#include "gps.h"
#include "pid.h"
#include <stdbool.h>

typedef enum {
    MODE_DISARMED = 0,
    MODE_STABILIZE,     /* Attitude hold – roll/pitch sıfıra döner */
    MODE_AUTO           /* GPS waypoint takibi (ileride) */
} FlightMode;

typedef struct {
    /* İstenen değerler (setpoint) */
    float target_roll_deg;
    float target_pitch_deg;
    float target_yaw_rate_dps;
    float throttle;           /* 0.0 … 1.0 */

    /* PID nesneleri – kaskad yapısı */
    PID roll_angle_pid;       /* dış halka: açı → rate setpoint */
    PID roll_rate_pid;        /* iç halka: rate → aileron çıkışı */
    PID pitch_angle_pid;
    PID pitch_rate_pid;
    PID yaw_rate_pid;         /* yaw için sadece rate halkası */

    FlightMode mode;
    bool armed;
} FlightController;

void fc_init   (FlightController *fc);
void fc_update (FlightController *fc, const IMU *imu, float dt);

/* RC karıştırıcı (mixer) – servo çıkışlarını yazar */
void fc_mix_and_output(const FlightController *fc);

/* Arm/disarm */
void fc_arm   (FlightController *fc);
void fc_disarm(FlightController *fc);

#endif /* FLIGHT_CONTROL_H */
