#include "pid.h"
#include <string.h>

void pid_init(PID *pid, float kp, float ki, float kd, float i_max)
{
    memset(pid, 0, sizeof(PID));
    pid->kp    = kp;
    pid->ki    = ki;
    pid->kd    = kd;
    pid->i_max = i_max;
}

void pid_reset(PID *pid)
{
    pid->integral   = 0.0f;
    pid->prev_error = 0.0f;
    pid->output     = 0.0f;
}

float pid_update(PID *pid, float error, float dt)
{
    pid->integral += error * dt;
    pid->integral  = pid_clamp(pid->integral, -pid->i_max, pid->i_max);

    float derivative = (error - pid->prev_error) / dt;
    pid->prev_error  = error;

    pid->output = pid->kp * error
                + pid->ki * pid->integral
                + pid->kd * derivative;

    pid->output = pid_clamp(pid->output, -1.0f, 1.0f);
    return pid->output;
}
