cmake_minimum_required(VERSION 3.20)

# Toolchain dosyasını BUILD komutuyla geçir:
# cmake -DCMAKE_TOOLCHAIN_FILE=cmake/stm32f407.cmake ..
project(FlightComputer C ASM)

set(CMAKE_C_STANDARD 11)

# ── Kütüphane konumu otomatik algılama ───────────────────────────
# Önce revengefc/ (CubeMX ile oluşturulan) dizinine bak,
# yoksa ../Drivers/ ve ../Middlewares/ dizinlerine bak.
set(_CUBEMX_DIR "${CMAKE_SOURCE_DIR}/revengefc")

if(EXISTS "${_CUBEMX_DIR}/Drivers/STM32F4xx_HAL_Driver/Inc/stm32f4xx_hal.h")
    # CubeMX revengefc/ altında kod üretmiş
    set(HAL_DIR      "${_CUBEMX_DIR}/Drivers/STM32F4xx_HAL_Driver")
    set(CMSIS_DEVICE "${_CUBEMX_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Include")
    set(CMSIS_CORE   "${_CUBEMX_DIR}/Drivers/CMSIS/Include")
    set(FREERTOS_DIR "${_CUBEMX_DIR}/Middlewares/FreeRTOS/Source")
    set(CUBEMX_CORE  "${_CUBEMX_DIR}/Core")
    message(STATUS "HAL kaynağı: revengefc/ (CubeMX çıktısı)")
elseif(EXISTS "${CMAKE_SOURCE_DIR}/../Drivers/STM32F4xx_HAL_Driver/Inc/stm32f4xx_hal.h")
    # Eski konum (manuel kurulum)
    set(HAL_DIR      "${CMAKE_SOURCE_DIR}/../Drivers/STM32F4xx_HAL_Driver")
    set(CMSIS_DEVICE "${CMAKE_SOURCE_DIR}/../Drivers/CMSIS/Device/ST/STM32F4xx/Include")
    set(CMSIS_CORE   "${CMAKE_SOURCE_DIR}/../Drivers/CMSIS/Include")
    set(FREERTOS_DIR "${CMAKE_SOURCE_DIR}/../Middlewares/FreeRTOS/Source")
    set(CUBEMX_CORE  "")
    message(STATUS "HAL kaynağı: ../Drivers/ (manuel kurulum)")
else()
    message(FATAL_ERROR
        "\n"
        "============================================================\n"
        " HAL sürücüleri bulunamadı!\n"
        "\n"
        " Seçenek 1 (Önerilen): STM32CubeMX ile revengefc.ioc dosyasını\n"
        "   açın → 'Generate Code' butonuna basın.\n"
        "   Beklenen: revengefc/Drivers/STM32F4xx_HAL_Driver/\n"
        "\n"
        " Seçenek 2: KURULUM_REHBERI.md → ADIM 3'ü uygulayın.\n"
        "   Beklenen: ../Drivers/STM32F4xx_HAL_Driver/\n"
        "============================================================\n"
    )
endif()

if(NOT EXISTS "${FREERTOS_DIR}/include/FreeRTOS.h")
    message(FATAL_ERROR
        "\n"
        "============================================================\n"
        " FreeRTOS bulunamadı!\n"
        " STM32CubeMX ile revengefc.ioc'yi açıp 'Generate Code' yapın.\n"
        " Beklenen: ${FREERTOS_DIR}/include/FreeRTOS.h\n"
        "============================================================\n"
    )
endif()

# ── Kaynak dosyalar ──────────────────────────────────────────────
# CubeMX tarafından üretilen başlatma dosyaları (varsa)
set(CUBEMX_SOURCES "")
if(NOT "${CUBEMX_CORE}" STREQUAL "")
    file(GLOB CUBEMX_SOURCES
        "${CUBEMX_CORE}/Src/stm32f4xx_hal_msp.c"
        "${CUBEMX_CORE}/Src/stm32f4xx_it.c"
        "${CUBEMX_CORE}/Src/freertos.c"
        "${CUBEMX_CORE}/Src/syscalls.c"
        "${CUBEMX_CORE}/Src/sysmem.c"
    )
    # CubeMX'in main.c'si KULLANILMIYOR – uçuş bilgisayarı kendi main()'ini kullanır
endif()

set(APP_SOURCES
    # Uçuş bilgisayarı çekirdek
    ${CMAKE_SOURCE_DIR}/../Core/Src/main.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/flight_control.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/imu.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/madgwick.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/pid.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/servo.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/rc_input.c
    ${CMAKE_SOURCE_DIR}/../Core/Src/gps.c
    # STM32 HAL sarmalayıcı
    ${CMAKE_SOURCE_DIR}/../Drivers/STM32/stm32_hal_impl.c
    # Startup
    ${CMAKE_SOURCE_DIR}/startup/startup_stm32f407xx.s
    # CubeMX init dosyaları
    ${CUBEMX_SOURCES}
)

# ── HAL kaynak dosyaları ─────────────────────────────────────────
file(GLOB HAL_SOURCES "${HAL_DIR}/Src/*.c")
# stm32f4xx_hal_template.c derleme dışı bırak
list(FILTER HAL_SOURCES EXCLUDE REGEX ".*_template\\.c$")

# ── FreeRTOS kaynak dosyaları ────────────────────────────────────
set(FREERTOS_SOURCES
    ${FREERTOS_DIR}/croutine.c
    ${FREERTOS_DIR}/event_groups.c
    ${FREERTOS_DIR}/list.c
    ${FREERTOS_DIR}/queue.c
    ${FREERTOS_DIR}/stream_buffer.c
    ${FREERTOS_DIR}/tasks.c
    ${FREERTOS_DIR}/timers.c
    ${FREERTOS_DIR}/portable/GCC/ARM_CM4F/port.c
    ${FREERTOS_DIR}/portable/MemMang/heap_4.c
)

# ── Hedef oluştur ────────────────────────────────────────────────
add_executable(${PROJECT_NAME}.elf
    ${APP_SOURCES}
    ${HAL_SOURCES}
    ${FREERTOS_SOURCES}
)

# ── Include dizinleri ────────────────────────────────────────────
set(_CUBEMX_INC "")
if(NOT "${CUBEMX_CORE}" STREQUAL "")
    set(_CUBEMX_INC "${CUBEMX_CORE}/Inc")
endif()

target_include_directories(${PROJECT_NAME}.elf PRIVATE
    ${CMAKE_SOURCE_DIR}/../Core/Inc
    ${_CUBEMX_INC}
    ${HAL_DIR}/Inc
    ${HAL_DIR}/Inc/Legacy
    ${CMSIS_DEVICE}
    ${CMSIS_CORE}
    ${FREERTOS_DIR}/include
    ${FREERTOS_DIR}/portable/GCC/ARM_CM4F
)

# ── Derleme bayrakları ───────────────────────────────────────────
target_compile_options(${PROJECT_NAME}.elf PRIVATE
    -Wall
    -Wextra
    -Os                     # Flash boyutunu küçült
    -fdata-sections
    -ffunction-sections
    -fno-exceptions
    -fno-rtti
)

target_compile_definitions(${PROJECT_NAME}.elf PRIVATE
    STM32F407xx
    USE_HAL_DRIVER
    HSE_VALUE=8000000       # 8 MHz kristal (kartınıza göre değiştirin!)
)

# ── Linker ayarları ──────────────────────────────────────────────
target_link_options(${PROJECT_NAME}.elf PRIVATE
    -T${CMAKE_SOURCE_DIR}/STM32F407VGTx_FLASH.ld
    -Wl,--gc-sections
    -Wl,--print-memory-usage
    -lm
    -lnosys
)

# ── Build sonrası: .bin ve .hex dosyası üret ─────────────────────
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex   $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE}    $<TARGET_FILE:${PROJECT_NAME}.elf>
    COMMENT "→ ${PROJECT_NAME}.hex ve ${PROJECT_NAME}.bin oluşturuldu"
)
