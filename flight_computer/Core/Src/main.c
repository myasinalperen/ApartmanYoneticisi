/*
 * Fixed-Wing IHA Uçuş Bilgisayarı
 * Hedef: STM32F407VGT6 + FreeRTOS
 *
 * Mod mantığı:
 *   RC CH5 < 0  → MANUAL    (saf manuel, PID yok)
 *   RC CH5 > 0  → STABILIZE (FBW-A, RC açı komutu verir PID tamamlar)
 *   RC CH6 > 0.5 → ARM / < 0.5 → DISARM
 *   RC kaybı (>500ms) → FAILSAFE (STABILIZE + sabit throttle)
 */

#ifndef SIMULATION

#include "stm32f4xx_hal.h"
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

#include "config.h"
#include "imu.h"
#include "gps.h"
#include "rc_input.h"
#include "flight_control.h"
#include "hal_wrapper.h"

/* ── Çevre birimleri ─────────────────────────────────────── */
I2C_HandleTypeDef  hi2c1;
UART_HandleTypeDef huart1;   /* SBUS RC alıcı */
UART_HandleTypeDef huart2;   /* GPS */
TIM_HandleTypeDef  htim1;
TIM_HandleTypeDef  htim3;

/* ── Paylaşılan durum ────────────────────────────────────── */
static IMU              g_imu;
static GPSData          g_gps;
static RCInput          g_rc;
static FlightController g_fc;

/* iBUS DMA tamponu (32 byte × 2 = çift tampon) */
static uint8_t ibus_dma_buf[IBUS_FRAME_LEN * 2];

/* ── RC görevi – SBUS DMA tamamlanınca çağrılır ────────── */
static void task_rc(void *arg)
{
    (void)arg;
    for (;;) {
        /* DMA transfer tamamlanana kadar bekle */
        ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(20));

        /* iBUS çerçevesini bul (header: 0x20 0x40) ve işle */
        for (int i = 0; i <= IBUS_FRAME_LEN; i++) {
            if (ibus_dma_buf[i]     == IBUS_HEADER0 &&
                ibus_dma_buf[i + 1] == IBUS_HEADER1) {
                rc_input_parse(&g_rc, &ibus_dma_buf[i]);
                break;
            }
        }
        /* DMA'yı yeniden başlat */
        HAL_UART_Receive_DMA(&huart1, ibus_dma_buf, IBUS_FRAME_LEN);
    }
}

/* ── IMU görevi – 1000 Hz ────────────────────────────────── */
static void task_imu(void *arg)
{
    (void)arg;
    TickType_t xLastWake = xTaskGetTickCount();
    for (;;) {
        imu_update(&g_imu);
        vTaskDelayUntil(&xLastWake, pdMS_TO_TICKS(1));
    }
}

/* ── Kontrol döngüsü – 400 Hz ────────────────────────────── */
static void task_control(void *arg)
{
    (void)arg;
    TickType_t xLastWake = xTaskGetTickCount();
    for (;;) {
        fc_update(&g_fc, &g_imu, &g_rc, CTRL_DT);
        vTaskDelayUntil(&xLastWake, pdMS_TO_TICKS(1000 / CTRL_LOOP_RATE_HZ));
    }
}

/* ── GPS görevi – 10 Hz ──────────────────────────────────── */
static void task_gps(void *arg)
{
    (void)arg;
    TickType_t xLastWake = xTaskGetTickCount();
    for (;;) {
        gps_update(&g_gps);
        vTaskDelayUntil(&xLastWake, pdMS_TO_TICKS(100));
    }
}

/* ── Telemetri – 5 Hz ────────────────────────────────────── */
static void task_telemetry(void *arg)
{
    (void)arg;
    TickType_t xLastWake = xTaskGetTickCount();
    for (;;) {
        hw_log("MOD:%s R:%+5.1f P:%+5.1f Y:%+5.1f THR:%.2f GPS:%d\n",
               fc_mode_str(g_fc.mode),
               imu_roll_deg(&g_imu),
               imu_pitch_deg(&g_imu),
               imu_yaw_deg(&g_imu),
               g_fc.out_throttle,
               g_gps.fix_valid);
        vTaskDelayUntil(&xLastWake, pdMS_TO_TICKS(200));
    }
}

/* ── Çevre birimi başlatma fonksiyonları ─────────────────── */
static void system_clock_config(void);
static void mx_gpio_init(void);
static void mx_i2c1_init(void);
static void mx_usart1_sbus_init(void);
static void mx_usart2_gps_init(void);
static void mx_tim1_pwm_init(void);
static void mx_tim3_pwm_init(void);

static TaskHandle_t rc_task_handle = NULL;

int main(void)
{
    HAL_Init();
    system_clock_config();
    mx_gpio_init();
    mx_i2c1_init();
    mx_usart1_sbus_init();
    mx_usart2_gps_init();
    mx_tim1_pwm_init();
    mx_tim3_pwm_init();

    if (!imu_init(&g_imu)) while (1);
    gps_init();
    rc_input_init(&g_rc);
    fc_init(&g_fc);

    /* iBUS DMA başlat */
    HAL_UART_Receive_DMA(&huart1, ibus_dma_buf, IBUS_FRAME_LEN);

    xTaskCreate(task_rc,        "RC",   256, NULL, TASK_PRIO_RC,        &rc_task_handle);
    xTaskCreate(task_imu,       "IMU",  512, NULL, TASK_PRIO_IMU,       NULL);
    xTaskCreate(task_control,   "CTRL", 512, NULL, TASK_PRIO_CONTROL,   NULL);
    xTaskCreate(task_gps,       "GPS",  512, NULL, TASK_PRIO_GPS,       NULL);
    xTaskCreate(task_telemetry, "TEL",  256, NULL, TASK_PRIO_TELEMETRY, NULL);

    vTaskStartScheduler();
    while (1);
}

/* UART1 DMA tamamlanınca RC görevini uyandır */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART1 && rc_task_handle) {
        BaseType_t higher_prio_woken = pdFALSE;
        vTaskNotifyGiveFromISR(rc_task_handle, &higher_prio_woken);
        portYIELD_FROM_ISR(higher_prio_woken);
    }
}

/* ── STM32F407 @ 168 MHz ─────────────────────────────────── */
static void system_clock_config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    RCC_OscInitStruct.HSEState       = RCC_HSE_ON;
    RCC_OscInitStruct.PLL.PLLState   = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource  = RCC_PLLSOURCE_HSE;
    RCC_OscInitStruct.PLL.PLLM       = 4;
    RCC_OscInitStruct.PLL.PLLN       = 168;
    RCC_OscInitStruct.PLL.PLLP       = RCC_PLLP_DIV2;
    RCC_OscInitStruct.PLL.PLLQ       = 7;
    HAL_RCC_OscConfig(&RCC_OscInitStruct);

    RCC_ClkInitStruct.ClockType      = RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK
                                     | RCC_CLOCKTYPE_PCLK1  | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource   = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider  = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;
    HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5);
}

static void mx_gpio_init(void)
{
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOE_CLK_ENABLE();
}

static void mx_i2c1_init(void)
{
    __HAL_RCC_I2C1_CLK_ENABLE();
    hi2c1.Instance             = I2C1;
    hi2c1.Init.ClockSpeed      = 400000;
    hi2c1.Init.DutyCycle       = I2C_DUTYCYCLE_2;
    hi2c1.Init.OwnAddress1     = 0;
    hi2c1.Init.AddressingMode  = I2C_ADDRESSINGMODE_7BIT;
    hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
    hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
    hi2c1.Init.NoStretchMode   = I2C_NOSTRETCH_DISABLE;
    HAL_I2C_Init(&hi2c1);
}

/* USART1 – FlySky iBUS: 115200 baud, 8N1, NORMAL lojik
 * PA10 = RX → Alıcı iBUS pinine DOĞRUDAN bağla, inverter gereksiz */
static void mx_usart1_sbus_init(void)
{
    __HAL_RCC_USART1_CLK_ENABLE();
    huart1.Instance          = USART1;
    huart1.Init.BaudRate     = IBUS_BAUDRATE;
    huart1.Init.WordLength   = UART_WORDLENGTH_8B;
    huart1.Init.StopBits     = UART_STOPBITS_1;
    huart1.Init.Parity       = UART_PARITY_NONE;
    huart1.Init.Mode         = UART_MODE_RX;
    huart1.Init.HwFlowCtl    = UART_HWCONTROL_NONE;
    huart1.Init.OverSampling = UART_OVERSAMPLING_16;
    HAL_UART_Init(&huart1);
}

static void mx_usart2_gps_init(void)
{
    __HAL_RCC_USART2_CLK_ENABLE();
    huart2.Instance          = USART2;
    huart2.Init.BaudRate     = GPS_BAUDRATE;
    huart2.Init.WordLength   = UART_WORDLENGTH_8B;
    huart2.Init.StopBits     = UART_STOPBITS_1;
    huart2.Init.Parity       = UART_PARITY_NONE;
    huart2.Init.Mode         = UART_MODE_TX_RX;
    huart2.Init.HwFlowCtl    = UART_HWCONTROL_NONE;
    huart2.Init.OverSampling = UART_OVERSAMPLING_16;
    HAL_UART_Init(&huart2);
}

/* TIM1 → 4 servo: PE9/PE11/PE13/PE14, 400 Hz PWM */
static void mx_tim1_pwm_init(void)
{
    __HAL_RCC_TIM1_CLK_ENABLE();
    TIM_OC_InitTypeDef sConfig = {0};

    htim1.Instance               = TIM1;
    htim1.Init.Prescaler         = 167;    /* 168 MHz / 168 = 1 MHz sayacı */
    htim1.Init.CounterMode       = TIM_COUNTERMODE_UP;
    htim1.Init.Period            = 2500 - 1;  /* 1 MHz / 2500 = 400 Hz */
    htim1.Init.ClockDivision     = TIM_CLOCKDIVISION_DIV1;
    htim1.Init.RepetitionCounter = 0;
    HAL_TIM_PWM_Init(&htim1);

    sConfig.OCMode     = TIM_OCMODE_PWM1;
    sConfig.Pulse      = SERVO_PULSE_MID_US;
    sConfig.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfig.OCNPolarity= TIM_OCNPOLARITY_HIGH;
    sConfig.OCFastMode = TIM_OCFAST_DISABLE;

    HAL_TIM_PWM_ConfigChannel(&htim1, &sConfig, TIM_CHANNEL_1);
    HAL_TIM_PWM_ConfigChannel(&htim1, &sConfig, TIM_CHANNEL_2);
    HAL_TIM_PWM_ConfigChannel(&htim1, &sConfig, TIM_CHANNEL_3);
    HAL_TIM_PWM_ConfigChannel(&htim1, &sConfig, TIM_CHANNEL_4);
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_3);
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_4);
}

/* TIM3 → ESC: PA6, 400 Hz PWM */
static void mx_tim3_pwm_init(void)
{
    __HAL_RCC_TIM3_CLK_ENABLE();
    TIM_OC_InitTypeDef sConfig = {0};

    htim3.Instance           = TIM3;
    htim3.Init.Prescaler     = 83;    /* 84 MHz / 84 = 1 MHz sayacı */
    htim3.Init.CounterMode   = TIM_COUNTERMODE_UP;
    htim3.Init.Period        = 2500 - 1;
    htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    HAL_TIM_PWM_Init(&htim3);

    sConfig.OCMode     = TIM_OCMODE_PWM1;
    sConfig.Pulse      = ESC_PULSE_MIN_US;
    sConfig.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfig.OCFastMode = TIM_OCFAST_DISABLE;
    HAL_TIM_PWM_ConfigChannel(&htim3, &sConfig, TIM_CHANNEL_1);
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask; (void)pcTaskName;
    while (1);
}

#endif /* !SIMULATION */
