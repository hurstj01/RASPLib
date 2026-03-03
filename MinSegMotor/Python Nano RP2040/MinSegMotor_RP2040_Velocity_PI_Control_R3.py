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

t0 = time.monotonic_ns() / 1_000_000_000
ts = 5e-3           # sample time
ts_ns = int(ts * 1_000_000_000)

T = 1               # step period

vsupply = 4.8  # supply volts

def read_pos():
    data = bytearray(12)
    while not i2c.try_lock():
        pass
    i2c.readfrom_into(0x08, data)
    i2c.unlock()
    pos1, pos2, dm = struct.unpack('lll', data)
    return pos1, pos2, dm


# Initialization
ref = 0
pos, pos2, dm = read_pos()
pos_ = pos
vel = 0
vel_ = vel

kP, kI = 0.0144, 0.0144 * 47
z = 0
ref_ = 200

# Binary struct for fast transfer: vel, ref, loop_dt_us
PACK_FMT = "<fff"
PACK_SIZE = 12

# ✅ NEW: Initialize last loop timestamp like Code #1
last_t_ns = time.monotonic_ns()

def ControlLoop(t):
    global vel, vel_, pos, pos_, ref, z, ref_

    pos, posR, dm = read_pos()
    dt_enc = dm / 1_000_000     # convert encoder timing to seconds

    # velocity compute
    vel = (pos - pos_) / dt_enc * 2 * math.pi / (4*336)
    vel_ = vel
    pos_ = pos

    # REF STEP WAVE
    if (t % (2*T)) < T:
        ref = +ref_
    else:
        ref = 0

    # PID
    z += (ref - vel) * dt_enc
    v = kP*(ref - vel) + kI*z

    V2PWM(v, PWM_M1B, PWM_M1A)

    return vel, ref

def V2PWM(V, pwm_a: pwmio.PWMOut, pwm_b: pwmio.PWMOut):
    pwmval = 65535
    pwm = int((V * pwmval) / vsupply)

    mag = abs(pwm)
    if mag > pwmval:
        mag = pwmval

    if pwm >= 0:
        pwm_a.duty_cycle = pwmval
        pwm_b.duty_cycle = pwmval - mag
    else:
        pwm_b.duty_cycle = pwmval
        pwm_a.duty_cycle = pwmval - mag

while True:
    t_start = time.monotonic_ns()

    # ✅ FIXED TIMING: true loop-to-loop dt (same as Code #1)
    loop_dt_us = (t_start - last_t_ns) / 1000.0
    last_t_ns = t_start

    t = t_start/1_000_000_000 - t0

    vel_val, ref_val = ControlLoop(t)

    elapsed = time.monotonic_ns() - t_start

    packet = struct.pack(PACK_FMT, float(vel_val), float(ref_val), float(loop_dt_us))
    ser.write(packet)

    if elapsed > ts_ns:
        # Overrun (optional: add LED if desired)
        pass
    else:
        while (time.monotonic_ns() - t_start) < ts_ns:
            pass
