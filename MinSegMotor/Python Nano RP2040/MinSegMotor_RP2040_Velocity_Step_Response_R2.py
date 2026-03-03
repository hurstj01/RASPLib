import time
import math
import board
import struct

import usb_cdc
ser = usb_cdc.data     # SERIAL PORT FOR HIGH-SPEED LOGGING

import pwmio
PWM_M1B = pwmio.PWMOut(board.D12, frequency=5000, duty_cycle=0)
PWM_M1A = pwmio.PWMOut(board.D10, frequency=5000, duty_cycle=0)
PWM_M1B.duty_cycle = 0
PWM_M1A.duty_cycle = 0

i2c = board.I2C()

# OPTIONAL: LED for overrun indication
import digitalio
led = digitalio.DigitalInOut(board.LED)
led.direction = digitalio.Direction.OUTPUT
led.value = False

# ---------- TIMING ----------
t0 = time.monotonic_ns() / 1_000_000_000
ts = 5e-3           # desired sample time (seconds)
ts_ns = int(ts * 1_000_000_000)

T = 2               # step period (seconds)

vsupply = 4.8       # supply volts

def read_pos():
    data = bytearray(12)
    while not i2c.try_lock():
        pass
    i2c.readfrom_into(0x08, data)
    i2c.unlock()
    pos1, pos2, dm = struct.unpack('lll', data)  # encoder 1, encoder 2, time since last read (ns)
    return pos1, pos2, dm


# Initialization
ref = 0
pos, pos2, dm = read_pos()
pos_ = pos
vel = 0.0
vel_ = vel

ref_ = 2.0  # magnitude of step

# Binary struct for fast transfer: vel, ref, loop_dt_us
PACK_FMT = "<fff"
PACK_SIZE = 12


def ControlLoop(t):
    global vel, vel_, pos, pos_, ref, ref_

    pos, posR, dm = read_pos()
    dt_enc = dm / 1_000_000.0     # convert encoder timing to seconds (dm is ns)

    # velocity compute
    vel = (pos - pos_) / dt_enc * 2 * math.pi / (4 * 336)
    vel_ = vel
    pos_ = pos

    # REF STEP WAVE
    if (t % (2 * T)) < T:
        ref = +ref_
    else:
        ref = 0.0

    # Voltage Step Response
    v = 1.5 + ref  # from 1.5 volts to 3.5 volts
    
    V2PWM(v, PWM_M1B, PWM_M1A)
  
    return vel, v


def V2PWM(V, pwm_a: pwmio.PWMOut, pwm_b: pwmio.PWMOut):
    # Convert voltage V to two complementary PWM signals for DRV8833
    pwmval = 65535  # Max duty cycle for RP2040
    pwm = int((V * pwmval) / vsupply)

    mag = abs(pwm)
    if mag > pwmval:
        mag = pwmval

    if pwm >= 0:
        # Forward
        pwm_a.duty_cycle = pwmval
        pwm_b.duty_cycle = pwmval - mag
    else:
        # Backward
        pwm_b.duty_cycle = pwmval
        pwm_a.duty_cycle = pwmval - mag


# ---------- MAIN LOOP ----------
last_t_ns = time.monotonic_ns()

while True:
    t_start = time.monotonic_ns()

    # Actual time since last loop iteration (microseconds)
    loop_dt_us = (t_start - last_t_ns) / 1000.0
    last_t_ns = t_start
    
    # Time used for step waveform
    t = t_start / 1_000_000_000.0 - t0

    # --- RUN CONTROL ---
    vel_val, ref_val = ControlLoop(t)

    elapsed = time.monotonic_ns() - t_start

    # --- SEND BINARY PACKET ---
    # float32 (vel, ref, loop_dt_us)
    packet = struct.pack(PACK_FMT, float(vel_val), float(ref_val), float(loop_dt_us))
    ser.write(packet)

    # --- OVERRUN CHECK & WAIT ---
    if elapsed > ts_ns:
        # Overrun: work took longer than sample time
        led.value = True      # stays on forever; we never turn it off
    else:
        # Not overrun: wait out the remaining time to keep approx fixed period
        while (time.monotonic_ns() - t_start) < ts_ns:
            pass
