#ifndef PID_H
#define PID_H

typedef struct {
    float kp, ki, kd;
    float i_max;        /* integratör doyum limiti */
    float integral;
    float prev_error;
    float output;
} PID;

void  pid_init  (PID *pid, float kp, float ki, float kd, float i_max);
void  pid_reset (PID *pid);
float pid_update(PID *pid, float error, float dt);

/* -1.0 … +1.0 aralığını kırp */
static inline float pid_clamp(float v, float lo, float hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

#endif /* PID_H */
