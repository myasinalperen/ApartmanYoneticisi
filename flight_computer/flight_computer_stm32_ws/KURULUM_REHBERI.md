# STM32F407 Uçuş Bilgisayarı – VS Code Kurulum Rehberi

> **Hedef kart:** STM32F407VGT6 (Black Pill / Discovery / custom board)  
> **İşletim sistemi:** Windows 10/11  
> **Süre:** yaklaşık 45–60 dakika (ilk kurulum)

---

## Gerekli Araçlar (Özet)

| Araç | Ne işe yarar |
|------|--------------|
| VS Code | Kod editörü |
| arm-none-eabi-gcc | ARM için C derleyici |
| CMake + Ninja | Build sistemi |
| STM32CubeMX | HAL + FreeRTOS kütüphanelerini indir |
| STM32CubeProgrammer | Karta .hex yükle |
| OpenOCD | Debug (isteğe bağlı) |
| ST-Link sürücüsü | USB programlayıcı sürücüsü |

---

## ADIM 1 – VS Code Eklentilerini Kur

VS Code'u açın → Sol çubukta **Extensions** (Ctrl+Shift+X) → Aşağıdakileri arayıp kurun:

1. **C/C++** — Microsoft (`ms-vscode.cpptools`)
2. **CMake Tools** — Microsoft (`ms-vscode.cmake-tools`)
3. **Cortex-Debug** — marus25 (`marus25.cortex-debug`)
4. **STM32 VS Code Extension** — STMicroelectronics *(isteğe bağlı ama önerilir)*

> **Not:** Bu workspace'i açtığınızda VS Code otomatik olarak önerilen eklentileri gösterecek.

---

## ADIM 2 – Araçları Kur (Windows)

### 2a. ARM GCC Toolchain
1. Şu adrese gidin:  
   `https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads`
2. **Windows (mingw-w64-i686)** → `arm-none-eabi` başlıklı son sürümü indirin  
   *(dosya adı: `arm-gnu-toolchain-XX.X-mingw-w64-i686-arm-none-eabi.exe`)*
3. Kurun → kurulum sonunda **"Add to PATH"** kutusunu işaretleyin
4. Doğrulama (PowerShell/CMD):
   ```
   arm-none-eabi-gcc --version
   ```
   Çıktı: `arm-none-eabi-gcc (Arm GNU Toolchain ...) 13.x.x`

### 2b. CMake
1. `https://cmake.org/download/` → **Windows x64 Installer** indirin
2. Kurun → kurulum sırasında **"Add CMake to the system PATH"** seçin
3. Doğrulama:
   ```
   cmake --version
   ```

### 2c. Ninja Build
1. `https://github.com/ninja-build/ninja/releases` → `ninja-win.zip` indirin
2. İçindeki `ninja.exe`'yi `C:\tools\` gibi bir yere kopyalayın
3. Bu klasörü PATH'e ekleyin:  
   Başlat → "Ortam Değişkenleri" → Path → Yeni → `C:\tools`
4. Doğrulama:
   ```
   ninja --version
   ```

### 2d. STM32CubeMX (HAL kütüphanesi için)
1. `https://www.st.com/en/development-tools/stm32cubemx.html` → **Get Software** (ücretsiz, kayıt gerekebilir)
2. Kurun (varsayılan ayarlar)

### 2e. STM32CubeProgrammer (Flash için)
1. `https://www.st.com/en/development-tools/stm32cubeprog.html` → İndir ve kur
2. Bu program ST-Link sürücüsünü de otomatik kurar

### 2f. ST-Link Sürücüsü
STM32CubeProgrammer kurulumunda otomatik gelir.  
Yoksa: `https://www.st.com/en/development-tools/stsw-link009.html`

---

## ADIM 3 – HAL ve FreeRTOS Kütüphanelerini İndir

Bu adım **en önemli** adımdır. Projemizin derlenmesi için STM32 HAL kütüphanesi gerekir.

### STM32CubeMX ile otomatik indirme:

1. STM32CubeMX'i açın
2. **File → New Project** → arama kutusuna `STM32F407VG` yazın → kartı seçin → **Start Project**
3. **Project Manager** sekmesi:
   - Project Name: `temp_project`
   - Project Location: `D:\temp\`
   - Toolchain: **STM32CubeIDE** (veya **Makefile**)
4. **Code Generator** → ✅ "Copy only necessary library files" seçin
5. **GENERATE CODE** → HAL dosyaları indirilir ve oluşturulur

6. Oluşturulan dosyaları projemize kopyalayın:

```
D:\temp\temp_project\Drivers\    →  kopyala →  D:\Claude\revenge\ApartmanYoneticisi\flight_computer\Drivers\
D:\temp\temp_project\Middlewares\ →  kopyala →  D:\Claude\revenge\ApartmanYoneticisi\flight_computer\Middlewares\
```

### Beklenen klasör yapısı:
```
flight_computer\
├── Core\               ← bizim kodlarımız (zaten var)
├── Drivers\
│   ├── CMSIS\
│   │   ├── Include\         ← core_cm4.h vb.
│   │   └── Device\ST\STM32F4xx\Include\  ← stm32f407xx.h
│   ├── STM32F4xx_HAL_Driver\
│   │   ├── Inc\             ← stm32f4xx_hal.h vb.
│   │   └── Src\             ← stm32f4xx_hal.c vb.
│   └── STM32\
│       └── stm32_hal_impl.c ← zaten var
└── Middlewares\
    └── FreeRTOS\
        └── Source\          ← FreeRTOS kaynak
```

> **Kısayol (GitHub):** HAL kütüphanesini GitHub'dan da indirebilirsiniz:
> `https://github.com/STMicroelectronics/STM32CubeF4`  
> `Drivers/` ve `Middlewares/` klasörlerini alın.

---

## ADIM 4 – FreeRTOSConfig.h Dosyası

FreeRTOS'un çalışması için bir yapılandırma dosyası gerekir.  
`flight_computer\Core\Inc\FreeRTOSConfig.h` dosyasını oluşturun:

```c
#pragma once
#define configUSE_PREEMPTION                    1
#define configUSE_IDLE_HOOK                     0
#define configUSE_TICK_HOOK                     0
#define configCPU_CLOCK_HZ                      168000000
#define configTICK_RATE_HZ                      1000
#define configMAX_PRIORITIES                    7
#define configMINIMAL_STACK_SIZE                128
#define configTOTAL_HEAP_SIZE                   (32 * 1024)
#define configMAX_TASK_NAME_LEN                 16
#define configUSE_TRACE_FACILITY                0
#define configUSE_16_BIT_TICKS                  0
#define configIDLE_SHOULD_YIELD                 1
#define configUSE_MUTEXES                       1
#define configQUEUE_REGISTRY_SIZE               8
#define configUSE_RECURSIVE_MUTEXES             1
#define configUSE_COUNTING_SEMAPHORES           1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 1

#define INCLUDE_vTaskPrioritySet                1
#define INCLUDE_uxTaskPriorityGet               1
#define INCLUDE_vTaskDelete                     1
#define INCLUDE_vTaskSuspend                    1
#define INCLUDE_xResumeFromISR                  1
#define INCLUDE_vTaskDelayUntil                 1
#define INCLUDE_vTaskDelay                      1
#define INCLUDE_xTaskGetSchedulerState          1
#define INCLUDE_xTaskGetCurrentTaskHandle       1
#define INCLUDE_uxTaskGetStackHighWaterMark     0
#define INCLUDE_xTaskGetIdleTaskHandle          0
#define INCLUDE_eTaskGetState                   0
#define INCLUDE_xEventGroupSetBitFromISR        1
#define INCLUDE_xTimerPendFunctionCall          1
#define INCLUDE_xTaskAbortDelay                 0
#define INCLUDE_xTaskGetHandle                  0

#ifdef __NVIC_PRIO_BITS
    #define configPRIO_BITS __NVIC_PRIO_BITS
#else
    #define configPRIO_BITS 4
#endif

#define configLIBRARY_LOWEST_INTERRUPT_PRIORITY         15
#define configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY    5
#define configKERNEL_INTERRUPT_PRIORITY     (configLIBRARY_LOWEST_INTERRUPT_PRIORITY << (8 - configPRIO_BITS))
#define configMAX_SYSCALL_INTERRUPT_PRIORITY (configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY << (8 - configPRIO_BITS))

#define xPortPendSVHandler   PendSV_Handler
#define vPortSVCHandler      SVC_Handler
#define xPortSysTickHandler  SysTick_Handler
```

---

## ADIM 5 – stm32f4xx_hal_conf.h

CubeMX bu dosyayı otomatik oluşturur. Manuel olarak da oluşturabilirsiniz.  
`flight_computer\Core\Inc\stm32f4xx_hal_conf.h`:

```c
#pragma once
#include "stm32f4xx.h"

#define HAL_MODULE_ENABLED
#define HAL_GPIO_MODULE_ENABLED
#define HAL_I2C_MODULE_ENABLED
#define HAL_UART_MODULE_ENABLED
#define HAL_DMA_MODULE_ENABLED
#define HAL_TIM_MODULE_ENABLED
#define HAL_RCC_MODULE_ENABLED
#define HAL_FLASH_MODULE_ENABLED
#define HAL_PWR_MODULE_ENABLED
#define HAL_CORTEX_MODULE_ENABLED

#define HSE_VALUE    8000000U    /* ← Kartınızdaki kristal frekansı (Hz) */
#define HSE_STARTUP_TIMEOUT 100U
#define HSI_VALUE    16000000U
#define VDD_VALUE    3300U
#define TICK_INT_PRIORITY  0x0FU
#define USE_RTOS    0U
#define USE_SPI_CRC 0U

#include "stm32f4xx_hal_rcc.h"
#include "stm32f4xx_hal_gpio.h"
#include "stm32f4xx_hal_dma.h"
#include "stm32f4xx_hal_cortex.h"
#include "stm32f4xx_hal_uart.h"
#include "stm32f4xx_hal_i2c.h"
#include "stm32f4xx_hal_tim.h"
#include "stm32f4xx_hal_flash.h"
#include "stm32f4xx_hal_pwr.h"
```

> **ÖNEMLİ:** `HSE_VALUE` değerini kartınızdaki kristal osilatör değeriyle eşleştirin.  
> STM32F407 Discovery → 8 MHz, özel kart → etiketine bakın.

---

## ADIM 6 – Workspace'i Aç ve Derle

1. VS Code'u açın
2. **File → Open Workspace from File...**
3. Şu dosyayı seçin:  
   `D:\Claude\revenge\ApartmanYoneticisi\flight_computer\flight_computer_stm32_ws\flight_computer.code-workspace`

4. Sol altta **CMake Yapılandır** yazısına tıklayın **VEYA** terminal açın (Ctrl+`):

```powershell
# Workspace klasöründe:
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/stm32f407.cmake -G Ninja
cmake --build build
```

5. Hatasız derlendiyse `build/` klasöründe şunlar oluşur:
   - `FlightComputer.elf` — debug için
   - `FlightComputer.hex` — flash için  
   - `FlightComputer.bin` — alternatif flash formatı

---

## ADIM 7 – Karta Yükleme (Flash)

### Yöntem A: STM32CubeProgrammer (GUI – En Kolay)

1. ST-Link kablosunu bilgisayara ve karta bağlayın
2. STM32CubeProgrammer'ı açın
3. Sağ üstte **ST-LINK** seçin → **Connect**
4. Sol menüde **Erasing & Programming**
5. **Browse** → `build\FlightComputer.hex` seçin
6. **Start Programming** → tamamlandığında "Download verified successfully" görürsünüz
7. Kart otomatik reset atar ve kod çalışmaya başlar

### Yöntem B: VS Code Task (Terminal)

VS Code'da **Ctrl+Shift+B** → **"3. Karta Yükle (Flash)"** seçin

*(Bu task `STM32_Programmer_CLI` komutunu çalıştırır — PATH'te olması gerekir)*

### Yöntem C: OpenOCD (Gelişmiş)

```powershell
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg `
  -c "program build/FlightComputer.bin verify reset exit 0x08000000"
```

---

## ADIM 8 – Seri Port ile Log Takibi

Uçuş bilgisayarı USART2 üzerinden telemetri gönderir (PA2 = TX, PA3 = RX):

1. USB-TTL dönüştürücü bağlayın: **PA2 → RX pini**
2. VS Code'da **Serial Monitor** eklentisi kurun veya kullanın:
   - PuTTY / Tera Term / Windows Terminal
   - Baud: **115200**, Data: 8N1
3. Normal çıktı:
   ```
   MOD:DISARMED R: +0.0 P: +0.0 Y: +0.0 THR:0.00 GPS:0
   MOD:STABILIZE R: +0.3 P: +0.1 Y:+15.2 THR:0.35 GPS:1
   ```

---

## Sık Karşılaşılan Hatalar

| Hata | Çözüm |
|------|-------|
| `arm-none-eabi-gcc: command not found` | PATH'e toolchain ekleyin, terminal yeniden başlatın |
| `Cannot find -lnosys` | `libc_nano.a` eksik; toolchain'i yeniden kurun |
| `stm32f4xx_hal.h: No such file` | ADIM 3'ü tekrarlayın, Drivers/ klasörünü kontrol edin |
| `FreeRTOS.h: No such file` | Middlewares/FreeRTOS/Source/include/ klasörünü kontrol edin |
| `ST-Link: No target connected` | Kablo bağlı değil veya BOOT0 pini yanlış konumda |
| Flash başarılı ama kod çalışmıyor | HSE_VALUE kristal frekansını kontrol edin |
| Derleme başarılı ama IMU bulunamadı | I2C bağlantısını ve MPU6050 adresini (0x68) kontrol edin |

---

## YouTube Video Önerileri

### Türkçe:
- **"STM32 Programlama Dersleri"** – YouTube'da arayın, birçok Türkçe kanal var
- **"ARM Cortex-M STM32 Uygulamaları"** anahtar kelimesiyle arama yapın

### İngilizce (Daha kapsamlı):
| Kanal | Konu | Arama |
|-------|------|-------|
| **Phil's Lab** | VS Code + STM32 CMake kurulumu | "STM32 VS Code CMake" |
| **Embedded Geek** | STM32 HAL FreeRTOS | "STM32 FreeRTOS tutorial" |
| **Low Level Learning** | Bare metal STM32 | "STM32 bare metal" |
| **Controllers Tech** | STM32CubeMX başlangıç | "STM32CubeMX tutorial" |

### Öncelikli izleme sırası:
1. **"Phil's Lab #4 – STM32 CMake VS Code"** → Derleme ortamı
2. **"STM32CubeMX Complete Tutorial"** → HAL kütüphanesi oluşturma
3. **"Cortex-Debug VS Code STM32"** → Debug kurulumu

---

## Proje Dosya Yapısı (Özet)

```
ApartmanYoneticisi\flight_computer\
│
├── Core\                        ← Uçuş bilgisayarı kodu
│   ├── Inc\
│   │   ├── config.h             ← PID, pin, frekans ayarları
│   │   ├── flight_control.h     ← MANUAL/STABILIZE mod
│   │   ├── imu.h / madgwick.h   ← IMU + AHRS filtresi
│   │   ├── rc_input.h           ← FlySky iBUS
│   │   └── FreeRTOSConfig.h     ← (oluşturmanız gerekiyor)
│   └── Src\
│       ├── main.c               ← FreeRTOS görevleri
│       ├── flight_control.c     ← PID kontrol döngüsü
│       └── ...
│
├── Drivers\                     ← STM32CubeMX'ten gelecek
│   ├── STM32F4xx_HAL_Driver\
│   └── CMSIS\
│
├── Middlewares\                 ← STM32CubeMX'ten gelecek
│   └── FreeRTOS\
│
├── flight_computer_stm32_ws\   ← VS Code workspace (bu klasör)
│   ├── CMakeLists.txt
│   ├── STM32F407VGTx_FLASH.ld
│   ├── cmake\stm32f407.cmake
│   ├── startup\startup_stm32f407xx.s
│   └── .vscode\
│
├── Simulation\                  ← PC simülasyonu (donanımsız test)
│   └── (bash testler.sh ile çalıştırın)
│
└── docs\wiring.txt              ← Bağlantı şeması
```

---

## Hızlı Başlangıç Kontrol Listesi

- [ ] arm-none-eabi-gcc kuruldu ve PATH'te (`arm-none-eabi-gcc --version`)
- [ ] CMake kuruldu (`cmake --version`)
- [ ] Ninja kuruldu (`ninja --version`)
- [ ] STM32CubeMX ile Drivers/ ve Middlewares/ oluşturuldu
- [ ] FreeRTOSConfig.h dosyası oluşturuldu
- [ ] stm32f4xx_hal_conf.h dosyası oluşturuldu ve HSE_VALUE doğru
- [ ] `cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/stm32f407.cmake -G Ninja` → hata yok
- [ ] `cmake --build build` → `FlightComputer.hex` oluştu
- [ ] ST-Link bağlandı, STM32CubeProgrammer ile flash atıldı
- [ ] Seri port (115200) üzerinden "MOD:DISARMED" görüldü
- [ ] RC kumanda bağlandı, ARM edildi → "MOD:STABILIZE" görüldü
