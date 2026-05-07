CC      = gcc
CFLAGS  = -O2 -Wall -Wextra -DSIMULATION -I../Core/Inc
LDFLAGS = -lm
TARGET  = sim_fc

SRCS = sim_main.c \
       mock_hal.c \
       ../Core/Src/imu.c \
       ../Core/Src/gps.c \
       ../Core/Src/madgwick.c \
       ../Core/Src/pid.c \
       ../Core/Src/servo.c \
       ../Core/Src/flight_control.c

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "Derlendi: ./$(TARGET)"

clean:
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
