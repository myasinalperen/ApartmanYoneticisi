#ifndef MADGWICK_H
#define MADGWICK_H

#include <stdint.h>

typedef struct {
    float q0, q1, q2, q3;   /* kuaterniyon [w, x, y, z] */
    float beta;              /* gradient descent adım katsayısı */
} MadgwickFilter;

void madgwick_init(MadgwickFilter *f, float beta);

/* ax/ay/az: m/s², gx/gy/gz: rad/s, dt: saniye */
void madgwick_update(MadgwickFilter *f,
                     float ax, float ay, float az,
                     float gx, float gy, float gz,
                     float dt);

void madgwick_get_euler(const MadgwickFilter *f,
                        float *roll_rad, float *pitch_rad, float *yaw_rad);

#endif /* MADGWICK_H */
