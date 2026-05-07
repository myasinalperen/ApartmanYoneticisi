#include "madgwick.h"
#include <math.h>

void madgwick_init(MadgwickFilter *f, float beta)
{
    f->q0   = 1.0f;
    f->q1   = 0.0f;
    f->q2   = 0.0f;
    f->q3   = 0.0f;
    f->beta = beta;
}

void madgwick_update(MadgwickFilter *f,
                     float ax, float ay, float az,
                     float gx, float gy, float gz,
                     float dt)
{
    float q0 = f->q0, q1 = f->q1, q2 = f->q2, q3 = f->q3;
    float norm;
    float s0, s1, s2, s3;
    float qDot0, qDot1, qDot2, qDot3;
    float _2q0, _2q1, _2q2, _2q3;
    float _4q0, _4q1, _4q2;
    float _8q1, _8q2;
    float q0q0, q1q1, q2q2, q3q3;

    /* İvmeölçer normalleştirme */
    norm = sqrtf(ax*ax + ay*ay + az*az);
    if (norm < 1e-6f) return;
    norm = 1.0f / norm;
    ax *= norm; ay *= norm; az *= norm;

    _2q0 = 2.0f * q0; _2q1 = 2.0f * q1;
    _2q2 = 2.0f * q2; _2q3 = 2.0f * q3;
    _4q0 = 4.0f * q0; _4q1 = 4.0f * q1; _4q2 = 4.0f * q2;
    _8q1 = 8.0f * q1; _8q2 = 8.0f * q2;
    q0q0 = q0*q0; q1q1 = q1*q1; q2q2 = q2*q2; q3q3 = q3*q3;

    /* Gradyan hesabı */
    s0 = _4q0*q2q2 + _2q2*ax + _4q0*q1q1 - _2q1*ay;
    s1 = _4q1*q3q3 - _2q3*ax + 4.0f*(q0q0*q1 - q0q0*q1) + _4q1*q2q2
       - _2q0*ay - _4q1 + _8q1*q1q1 + _8q1*q2q2 + _4q1*az;
    s2 = 4.0f*q0q0*q2 + _2q0*ax + _4q2*q3q3 - _2q3*ay
       - _4q2 + _8q2*q1q1 + _8q2*q2q2 + _4q2*az;
    s3 = 4.0f*q1q1*q3 - _2q1*ax + 4.0f*q2q2*q3 - _2q2*ay;

    /* Sebastián Madgwick'in orijinal formülasyonu */
    s0 = _4q0*q2q2 + _2q2*ax + _4q0*q1q1 - _2q1*ay;
    s1 = _4q1*q3q3 - _2q3*ax + 4.0f*q0q0*q1 + 4.0f*q1*q2q2
       - _2q0*ay - _4q1 + _8q1*q1q1 + _8q1*q2q2 + _4q1*az;
    s2 = 4.0f*q0q0*q2 + _2q0*ax + 4.0f*q2*q3q3 - _2q3*ay
       - _4q2 + _8q2*q1q1 + _8q2*q2q2 + _4q2*az;
    s3 = 4.0f*q1q1*q3 - _2q1*ax + 4.0f*q2q2*q3 - _2q2*ay;

    norm = 1.0f / sqrtf(s0*s0 + s1*s1 + s2*s2 + s3*s3);
    s0 *= norm; s1 *= norm; s2 *= norm; s3 *= norm;

    /* Kuaterniyon türevi = jiroskop + düzeltme */
    qDot0 = 0.5f*(-q1*gx - q2*gy - q3*gz) - f->beta * s0;
    qDot1 = 0.5f*( q0*gx + q2*gz - q3*gy) - f->beta * s1;
    qDot2 = 0.5f*( q0*gy - q1*gz + q3*gx) - f->beta * s2;
    qDot3 = 0.5f*( q0*gz + q1*gy - q2*gx) - f->beta * s3;

    /* Entegrasyon */
    q0 += qDot0 * dt;
    q1 += qDot1 * dt;
    q2 += qDot2 * dt;
    q3 += qDot3 * dt;

    /* Kuaterniyon normalleştirme */
    norm = 1.0f / sqrtf(q0*q0 + q1*q1 + q2*q2 + q3*q3);
    f->q0 = q0 * norm;
    f->q1 = q1 * norm;
    f->q2 = q2 * norm;
    f->q3 = q3 * norm;
}

void madgwick_get_euler(const MadgwickFilter *f,
                        float *roll_rad, float *pitch_rad, float *yaw_rad)
{
    float q0 = f->q0, q1 = f->q1, q2 = f->q2, q3 = f->q3;

    *roll_rad  = atan2f(2.0f*(q0*q1 + q2*q3),
                        1.0f - 2.0f*(q1*q1 + q2*q2));
    *pitch_rad = asinf (2.0f*(q0*q2 - q3*q1));
    *yaw_rad   = atan2f(2.0f*(q0*q3 + q1*q2),
                        1.0f - 2.0f*(q2*q2 + q3*q3));
}
