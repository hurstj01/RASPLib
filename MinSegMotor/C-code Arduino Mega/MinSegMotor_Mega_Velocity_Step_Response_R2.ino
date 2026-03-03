/*
  Arduino Mega version of:
  MinSegMotor_Velocity_Step_Response_R2.py

  Now supports TWO output modes:
  - Python GUI mode (binary <fff> = vel, ref, dt_us)  [matches PLOT_step_velocity_reference_theory_editable_R2.py]
  - Arduino Serial Plotter mode (ASCII, decimated): vel, 10*v

  Keep GUI unmodified by matching:
    PACK_FMT = "<fff"
    vel, ref, dt_us
*/

#include <Arduino.h>
#include <math.h>

// ---------- OUTPUT MODE SWITCH ----------
#define USE_PYTHON_GUI 1  // 1 = binary stream for Python GUI, 0 = ASCII for Serial Plotter

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
static const float ts = 5e-3f;                 // sample time (seconds)
static const uint32_t ts_us = (uint32_t)(ts * 1000000.0f);

// ---------- STEP SETTINGS ----------
static const float T = 2.0f;                   // step period (seconds)
static const float vsupply = 4.8f;             // supply volts

// ---------- Serial Plotter window control ----------
static const float PLOT_WINDOW_SEC = 10.0f;     // target visible time in Serial Plotter
static const int   PLOT_POINTS_EST = 300;       // typical-ish plotter history depth (varies by version)
static const float PRINT_HZ = (PLOT_POINTS_EST / PLOT_WINDOW_SEC);  // e.g. 30 Hz
static const int   DECIM = (int)lroundf((1.0f / ts) / PRINT_HZ);     // at ts=0.005, DECIM ~ 7 (for 30 Hz)
static int decim_ctr = 0;

// ---------- STATE ----------
float ref = 0.0f;
float ref_ = 2.0f;                             // step magnitude

long pos = 0;
long pos_ = 0;

float vel = 0.0f;

// ---------- Binary packet for Python GUI (matches "<fff") ----------
struct __attribute__((packed)) Packet3F {
  float a;   // vel
  float b;   // ref  (we send applied voltage v here)
  float c;   // dt_us (as float)
};

// ----------------- Encoder ISRs -----------------

static void isrPinAEn0(void)
{
  int PINE_REG = PINE;
  int drB = bool(PINE_REG & (1 << 5));
  int drA = bool(PINE_REG & (1 << 4));

  if (drA) {
    if (!drB) Enc1++;
    else      Enc1--;
  } else {
    if (drB)  Enc1++;
    else      Enc1--;
  }
}

static void isrPinBEn0(void)
{
  int PINE_REG = PINE;
  int drA = bool(PINE_REG & (1 << 4));
  int drB = bool(PINE_REG & (1 << 5));

  if (drB) {
    if (drA)  Enc1++;
    else      Enc1--;
  } else {
    if (!drA) Enc1++;
    else      Enc1--;
  }
}

// ---------- V2PWM() ----------
static inline void V2PWM(float V, int pin_a, int pin_b)
{
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
void setup()
{
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

void loop()
{
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
  vel = ((float)(pos - pos_)) / ts *
        (2.0f * (float)M_PI) / (4.0f * 336.0f);
  pos_ = pos;

  // --- STEP WAVEFORM (same logic as Python) ---
  if (fmodf(t, 2.0f * T) < T) ref = ref_;
  else                       ref = 0.0f;

  // --- VOLTAGE STEP (same as Python) ---
  float v = 1.5f + ref;

  // --- APPLY PWM ---
  V2PWM(v, PWM_M1A_PIN, PWM_M1B_PIN);

  // ---------- OUTPUT ----------
#if USE_PYTHON_GUI
  // Python GUI expects 12 bytes per sample: <fff> = vel, ref, dt_us
  // We send v as "ref" (input to the theory model), and dt_us as float(ts_us).
  Packet3F pkt;
  pkt.a = vel;
  pkt.b = v;
  pkt.c = (float)ts_us;

  Serial.write((uint8_t *)&pkt, sizeof(pkt));
#else
  // Human-readable output for Serial Plotter (decimated)
  // ONLY two traces: velocity, and voltage scaled by 10
  decim_ctr++;
  if (decim_ctr >= DECIM) {
    decim_ctr = 0;

    Serial.print(vel);
    Serial.print(",");
    Serial.println(10.0f * v);
  }
#endif

  // --- FIXED-RATE TIMING (balance-code style) ---
  // If we exceed the sample time, light the LED (overflow / overrun indicator)
  uint32_t elapsed_us = (uint32_t)(micros() - loop_start_us);
  if (elapsed_us > ts_us) {
    digitalWrite(LED_PIN, HIGH);   // stays on once we ever overrun
  } else {
    while ((uint32_t)(micros() - loop_start_us) < ts_us) {
      // busy wait to maintain fixed sample period
    }
  }
}
