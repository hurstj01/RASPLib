/*
  Arduino Mega PI Velocity Control (derived from step-response sketch)

  - Human-readable Serial Plotter output by default (decimated)
      ASCII columns: vel, ref
  - Binary packet output kept in place for Python GUI (<fff> = vel, ref, dt_us)
      (Enable by setting USE_PYTHON_GUI = 1)

  Hardware:
  - Motor PWM pins: 6, 7
  - Encoder pins: 2, 3 (INT0/INT1 on Mega2560)
  - Overflow LED: LED_BUILTIN (latches ON if loop overruns ts)
*/

#include <Arduino.h>
#include <math.h>

// ---------- OUTPUT MODE SWITCH ----------
// 0 = Arduino Serial Plotter (ASCII), 1 = Python GUI (binary <fff>)
#define USE_PYTHON_GUI 1

// ---------- PWM PINS ----------
const int PWM_M1A_PIN = 6;
const int PWM_M1B_PIN = 7;

// ---------- ENCODER PINS ----------
volatile long Enc1 = 0;
const int Enc1_PinA = 2;
const int Enc1_PinB = 3;

// ---------- LED (overflow indicator) ----------
const int LED_PIN = LED_BUILTIN;

// ---------- TIMING ----------
static const float ts = 2e-3f;  // sample time (seconds)
static const uint32_t ts_us = (uint32_t)(ts * 1000000.0f);

// ---------- Serial Plotter decimation ----------
// Prints once every DECIM control loops.
// Loop rate is (1/ts). With ts=0.005s => 200 Hz.
// Example: DECIM=25 => 8 Hz printing.
static const int DECIM = 8;
static int decim_ctr = 0;

// ---------- CONTROL (match Python: MinSegMotor_Velocity_PI_Control_R3.py) ----------
static const float kP = 0.008f;  //  for a good theory match avoid saturation
static const float kI = 0.008f * 47.0f;  // (for pole at orgin, zero at -47)

static const float T = 1.0f;        // step period (seconds)
static const float ref_ = 200.0f;   // reference magnitude (same units as vel)
static const float vsupply = 4.8f;  // supply volts

// ---------- STATE ----------
float ref = 0.0f;  // command
float z = 0.0f;    // integrator state

long pos = 0;
long pos_ = 0;
float vel = 0.0f;  // measured velocity

// ---------- Binary packet for Python GUI (matches "<fff") ----------
// GUI expects 12 bytes per sample: vel, ref, dt_us
struct __attribute__((packed)) Packet3F {
  float a;  // vel
  float b;  // ref
  float c;  // dt_us (as float)
};

// ----------------- Encoder ISRs -----------------
// Using direct port read on Mega2560: PE4=pin2, PE5=pin3

static void isrPinAEn0(void) {
  int PINE_REG = PINE;
  int drB = bool(PINE_REG & (1 << 5));
  int drA = bool(PINE_REG & (1 << 4));

  if (drA) {
    if (!drB) Enc1++;
    else Enc1--;
  } else {
    if (drB) Enc1++;
    else Enc1--;
  }
}

static void isrPinBEn0(void) {
  int PINE_REG = PINE;
  int drA = bool(PINE_REG & (1 << 4));
  int drB = bool(PINE_REG & (1 << 5));

  if (drB) {
    if (drA) Enc1++;
    else Enc1--;
  } else {
    if (!drA) Enc1++;
    else Enc1--;
  }
}

// ---------- V2PWM() ----------
static inline void V2PWM(float V, int pin_a, int pin_b) {
  const int pwmval = 255;
  int pwm = (int)((V * pwmval) / vsupply);

  int mag = abs(pwm);
  if (mag > pwmval) mag = pwmval;

  if (pwm >= 0) {
    analogWrite(pin_a, pwmval);
    analogWrite(pin_b, pwmval - mag);
  } else {
    analogWrite(pin_b, pwmval);
    analogWrite(pin_a, pwmval - mag);
  }
}

// ---------- SETUP ----------
void setup() {
  Serial.begin(115200);

  // ---------- PWM FREQUENCY: ~31.37 kHz (Timer4, pins 6 & 7) ----------
// Phase-correct PWM, 8-bit, prescaler = 1
// f_PWM = 16 MHz / (1 * 510) ≈ 31,372 Hz

TCCR4A = 0;
TCCR4B = 0;

// Phase-correct PWM, 8-bit: WGM43:0 = 0b0001 (WGM40=1)
TCCR4A |= (1 << WGM40);

// Enable PWM on OC4A (pin 6) and OC4B (pin 7)
TCCR4A |= (1 << COM4A1) | (1 << COM4B1);

// Prescaler = 1
TCCR4B |= (1 << CS40);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  pinMode(PWM_M1A_PIN, OUTPUT);
  pinMode(PWM_M1B_PIN, OUTPUT);

  pinMode(Enc1_PinA, INPUT_PULLUP);
  pinMode(Enc1_PinB, INPUT_PULLUP);

  attachInterrupt(0, isrPinAEn0, CHANGE);
  attachInterrupt(1, isrPinBEn0, CHANGE);

  analogWrite(PWM_M1A_PIN, 0);
  analogWrite(PWM_M1B_PIN, 0);
}

// ---------- LOOP ----------
static uint32_t t0_us = 0;

void loop() {
  uint32_t loop_start_us = micros();
  if (t0_us == 0) t0_us = loop_start_us;

  // time (seconds since start) for step waveform
  float t = (float)(loop_start_us - t0_us) * 1e-6f;

  // --- READ ENCODER DIRECTLY (atomic copy) ---
  noInterrupts();
  pos = Enc1;
  interrupts();

  // --- VELOCITY (assume dt == ts) ---
  // vel = (pos - pos_) / ts * 2*pi / (4*336)
  vel = ((float)(pos - pos_)) / ts * (2.0f * (float)M_PI) / (4.0f * 336.0f);
  pos_ = pos;

  // --- STEP REFERENCE (same structure as Python) ---
  if (fmodf(t, 2.0f * T) < T) ref = ref_;
  else ref = 0.0f;

  // --- PI CONTROL (same math as Python) ---
  float e = ref - vel;
  z += e * ts;                     // integrator
  float v = kP * e + kI * z ;  // control output

  // --- APPLY PWM ---
  V2PWM(v, PWM_M1A_PIN, PWM_M1B_PIN);

  // ---------- OUTPUT ----------
#if USE_PYTHON_GUI
  // Python GUI expects 12 bytes per sample: <fff> = vel, ref, dt_us
  Packet3F pkt;
  pkt.a = vel;
  pkt.b = ref;
  pkt.c = (float)ts_us;
  Serial.write((uint8_t *)&pkt, sizeof(pkt));
#else
  // Human-readable output for Arduino Serial Plotter (decimated):
  // Columns: velocity, reference
  decim_ctr++;
  if (decim_ctr >= DECIM) {
    decim_ctr = 0;
    Serial.print(vel);
    Serial.print(",");
    Serial.print(ref);
    Serial.print(",");
    Serial.println(v);
  }
  // NOTE: When switching to Python GUI mode, do NOT open Serial Plotter.
#endif

  // --- FIXED-RATE TIMING (balance-code style) ---
  // If we exceed the sample time, light the LED (overflow / overrun indicator)
  uint32_t elapsed_us = (uint32_t)(micros() - loop_start_us);
  if (elapsed_us > ts_us) {
    digitalWrite(LED_PIN, HIGH);  // stays on once we ever overrun
  } else {
    while ((uint32_t)(micros() - loop_start_us) < ts_us) {
      // busy wait to maintain fixed sample period
    }
  }
}
