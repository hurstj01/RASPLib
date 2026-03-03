import struct
import serial
import csv
import scipy.io as sio
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
from serial.tools import list_ports


# ---------- SETTINGS (persistent) ----------
SETTINGS = QtCore.QSettings("MinSeg", "VelocityLogger")
LAST_GOOD_PORT = SETTINGS.value("last_good_port", "", type=str)

# ---------- GLOBALS ----------
rxbuf = bytearray()   # robust packet framing buffer

# Safety: cap parsing per GUI tick so the UI never "hangs" if the device floods data
MAX_PACKETS_PER_TICK = 250

# ---------- GLOBALS ----------
ser = None

# Motor plant parameters
K = 59.0          # steady-state gain
TAU = 0.08       # time constant (seconds)

# --- PI Controller Params (MATCH FIRMWARE) ---
kP = 0.008
kI = 0.008 * 47
z_pi = 0.0          # integrator state

# Voltage limits (optional but realistic)
V_MIN = -4.8
V_MAX = +4.8

# Predicted velocity
y_theory = 0.0

MAX_POINTS = 1000
PACK_FMT = "<fff"
PACK_SIZE = 12

# Rolling-window data (for fast plotting)
t_data = []
vel_data = []
ref_data = []
theory_data = []

# Full dataset (for export)
full_time = []
full_vel = []
full_ref = []
full_theory = []

current_time_s = 0.0

# Timing stats
dt_history = []
dt_print_timer = 0.0


# ---------- STATUS INDICATOR ----------
def set_status(state: str, detail: str = ""):
    """Update the small status indicator next to the Connect/Disconnect buttons.

    state: "DISCONNECTED" | "CONNECTING" | "CONNECTED" | "FAILED"
    """
    if state == "CONNECTED":
        lbl_status.setText("● Connected")
        lbl_status.setToolTip(detail or "Serial connected")
        lbl_status.setStyleSheet("QLabel { color: #1f7a1f; font-weight: bold; }")
    elif state == "CONNECTING":
        lbl_status.setText("● Connecting")
        lbl_status.setToolTip(detail or "Attempting to connect...")
        lbl_status.setStyleSheet("QLabel { color: #b36b00; font-weight: bold; }")
    elif state == "FAILED":
        lbl_status.setText("● Failed")
        lbl_status.setToolTip(detail or "Connection failed")
        lbl_status.setStyleSheet("QLabel { color: #b00020; font-weight: bold; }")
    else:
        lbl_status.setText("● Disconnected")
        lbl_status.setToolTip(detail or "Serial disconnected")
        lbl_status.setStyleSheet("QLabel { color: #666666; font-weight: bold; }")


# ---------- UPDATE FUNCTION ----------

def update():
    global current_time_s, y_theory, z_pi
    global ser, K, TAU, kP, kI
    global dt_print_timer, rxbuf

    if ser is None:
        return

    # Non-blocking read of whatever is available
    try:
        n = ser.in_waiting
        if n > 0:
            rxbuf.extend(ser.read(n))
    except Exception as e:
        print(f"[SER] Read error: {repr(e)}")
        return

    # Parse packets, but cap per tick so the UI never "hangs" if data floods
    parsed = 0
    while len(rxbuf) >= PACK_SIZE and parsed < MAX_PACKETS_PER_TICK:
        raw = rxbuf[:PACK_SIZE]
        del rxbuf[:PACK_SIZE]

        try:
            vel, ref, dt_us = struct.unpack(PACK_FMT, raw)
        except Exception:
            rxbuf.clear()
            print("[SER] Packet decode error; buffer flushed. (Are you streaming ASCII instead of binary?)")
            break

        dt_s = dt_us / 1_000_000.0
        current_time_s += dt_s

        # ---- CLOSED-LOOP PI + PLANT THEORY ----

        # PI controller
        error = ref - y_theory
        z_pi += error * dt_s
        u = kP * error + kI * z_pi

        # Voltage saturation
        if u > V_MAX:
            u = V_MAX
        elif u < V_MIN:
            u = V_MIN

        # First-order motor model
        dy = (-1.0 / TAU) * y_theory + (K / TAU) * u
        y_theory += dt_s * dy

        theory_value = y_theory

        # ---- Window data ----
        t_data.append(current_time_s)
        vel_data.append(vel)
        ref_data.append(ref)
        theory_data.append(theory_value)

        # ---- Full data ----
        full_time.append(current_time_s)
        full_vel.append(vel)
        full_ref.append(ref)
        full_theory.append(theory_value)

        # Trim window
        if len(t_data) > MAX_POINTS:
            t_data.pop(0)
            vel_data.pop(0)
            ref_data.pop(0)
            theory_data.pop(0)

        # ---- Timing stats ----
        dt_history.append(dt_s)

        parsed += 1

    # ---- Print timing about once per second ----
    if len(dt_history) > 0:
        dt_print_timer += dt_history[-1]
        if dt_print_timer >= 1.0:
            avg_dt = sum(dt_history) / len(dt_history)
            rate = 1.0 / avg_dt
            print(f"Avg dt = {avg_dt:.6f} s   Rate = {rate:.1f} Hz")
            dt_history.clear()
            dt_print_timer = 0.0

    # ---- Update plot ----
    curve_vel.setData(t_data, vel_data)
    curve_ref.setData(t_data, ref_data)
    curve_theory.setData(t_data, theory_data)


# ---------- GUI CALLBACKS ----------
def refresh_ports():
    # Refresh available COM ports and prefer the last successful port
    port_list = sorted(
        [p.device for p in list_ports.comports()],
        key=lambda s: int(''.join(filter(str.isdigit, s))) if any(c.isdigit() for c in s) else -1
    )

    combo_ports.clear()
    combo_ports.addItems(port_list)

    # Prefer last successful port if present
    global LAST_GOOD_PORT
    if LAST_GOOD_PORT and LAST_GOOD_PORT in port_list:
        combo_ports.setCurrentText(LAST_GOOD_PORT)
        return

    # Fallback: select first available port (or leave empty)
    if port_list:
        combo_ports.setCurrentText(port_list[0])


def connect_port():
    global ser, LAST_GOOD_PORT, rxbuf
    port = combo_ports.currentText()
    if not port:
        btn_connect.setText("Failed / click to reconnect")
        btn_connect.setToolTip("No COM port selected.")
        set_status("FAILED", "No COM port selected.")
        print("[CONNECT] No COM port selected.")
        return

    # Close any existing connection
    try:
        if ser is not None and ser.is_open:
            ser.close()
    except Exception:
        pass

    print(f"[CONNECT] Trying {port} @ 115200")
    set_status("CONNECTING", f"Trying {port} @ 115200")
    try:
        # timeout=0 => non-blocking reads (UI stays responsive)
        ser = serial.Serial(port, 115200, timeout=0)

        # Give boards that auto-reset on open a moment to boot
        QtCore.QThread.msleep(150)

        # Clear any startup junk
        try:
            ser.reset_input_buffer()
        except Exception:
            pass

        rxbuf.clear()

        btn_connect.setText("Reconnect")
        btn_connect.setToolTip(f"Connected: {port} (click to reconnect)")
        set_status("CONNECTED", f"Connected: {port}")
        print(f"[CONNECT] Connected to {port}")

        LAST_GOOD_PORT = port
        SETTINGS.setValue("last_good_port", port)

    except Exception as e:
        ser = None
        btn_connect.setText("Failed / click to reconnect")
        btn_connect.setToolTip(f"Failed to open {port}\n{repr(e)}\nClick Connect to try again.")
        set_status("FAILED", f"Failed to open {port}: {repr(e)}")
        print(f"[CONNECT] FAILED to open {port}: {repr(e)}")


def disconnect_port():
    global ser, rxbuf
    # Close any existing connection so the Arduino IDE can upload immediately.
    try:
        if ser is not None and ser.is_open:
            ser.close()
            print("[DISCONNECT] Serial port closed.")
    except Exception as e:
        print(f"[DISCONNECT] Error closing port: {repr(e)}")

    ser = None
    rxbuf.clear()

    btn_connect.setText("Connect")
    btn_connect.setToolTip("Click to connect.")
    set_status("DISCONNECTED")




def update_params():
    global K, TAU, kP, kI, y_theory, z_pi
    try:
        K = float(edit_K.text())
        TAU = float(edit_TAU.text())
        kP = float(edit_kP.text())
        kI = float(edit_kI.text())
        # Reset states for clean restart
        y_theory = 0.0
        z_pi = 0.0
    except:
        pass


def export_csv_window():
    fname, _ = QtWidgets.QFileDialog.getSaveFileName(None, "Save Window CSV", "", "*.csv")
    if not fname:
        return
    with open(fname, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Time_s", "Vel", "Ref", "Theory"])
        for i in range(len(t_data)):
            writer.writerow([t_data[i], vel_data[i], ref_data[i], theory_data[i]])


def export_csv_all():
    fname, _ = QtWidgets.QFileDialog.getSaveFileName(None, "Save ALL CSV", "", "*.csv")
    if not fname:
        return
    with open(fname, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Time_s", "Vel", "Ref", "Theory"])
        for i in range(len(full_time)):
            writer.writerow([full_time[i], full_vel[i], full_ref[i], full_theory[i]])


def export_mat_window():
    fname, _ = QtWidgets.QFileDialog.getSaveFileName(None, "Save Window MAT", "", "*.mat")
    if not fname:
        return
    sio.savemat(fname, {
        "time": t_data,
        "velocity": vel_data,
        "reference": ref_data,
        "theory": theory_data
    })


def export_mat_all():
    fname, _ = QtWidgets.QFileDialog.getSaveFileName(None, "Save ALL MAT", "", "*.mat")
    if not fname:
        return
    sio.savemat(fname, {
        "time": full_time,
        "velocity": full_vel,
        "reference": full_ref,
        "theory": full_theory
    })


# ---------- QT APP ----------
app = QtWidgets.QApplication([])
main = QtWidgets.QWidget()
main.setWindowTitle("RP2040 Velocity Logger (Closed-Loop Predictor)")
main.resize(1100, 700)

layout = QtWidgets.QVBoxLayout(main)

# ---------- CONTROL PANEL ----------
ctrl = QtWidgets.QGridLayout()

combo_ports = QtWidgets.QComboBox()
btn_refresh = QtWidgets.QPushButton("Refresh Ports")
btn_connect = QtWidgets.QPushButton("Connect")
btn_disconnect = QtWidgets.QPushButton("Disconnect")
lbl_status = QtWidgets.QLabel("● Disconnected")
lbl_status.setToolTip("Serial disconnected")
lbl_status.setStyleSheet("QLabel { color: #666666; font-weight: bold; }")

edit_K = QtWidgets.QLineEdit(str(K))
edit_TAU = QtWidgets.QLineEdit(str(TAU))
edit_kP = QtWidgets.QLineEdit(str(kP))
edit_kI = QtWidgets.QLineEdit(str(kI))
btn_apply = QtWidgets.QPushButton("Apply Params")

btn_csv_win = QtWidgets.QPushButton("Export Window CSV")
btn_mat_win = QtWidgets.QPushButton("Export Window MAT")
btn_csv_all = QtWidgets.QPushButton("Export ALL CSV")
btn_mat_all = QtWidgets.QPushButton("Export ALL MAT")

ctrl.addWidget(QtWidgets.QLabel("COM Port:"), 0, 0)
ctrl.addWidget(combo_ports, 0, 1)
ctrl.addWidget(btn_refresh, 0, 2)
ctrl.addWidget(btn_connect, 0, 3)
ctrl.addWidget(btn_disconnect, 0, 4)
ctrl.addWidget(lbl_status, 0, 5)

ctrl.addWidget(QtWidgets.QLabel("K:"), 1, 0)
ctrl.addWidget(edit_K, 1, 1)
ctrl.addWidget(QtWidgets.QLabel("Tau:"), 1, 2)
ctrl.addWidget(edit_TAU, 1, 3)

ctrl.addWidget(QtWidgets.QLabel("kP:"), 2, 0)
ctrl.addWidget(edit_kP, 2, 1)
ctrl.addWidget(QtWidgets.QLabel("kI:"), 2, 2)
ctrl.addWidget(edit_kI, 2, 3)

ctrl.addWidget(btn_apply, 2, 4)

ctrl.addWidget(btn_csv_win, 3, 0)
ctrl.addWidget(btn_mat_win, 3, 1)
ctrl.addWidget(btn_csv_all, 4, 0)
ctrl.addWidget(btn_mat_all, 4, 1)

layout.addLayout(ctrl)

# ---------- PLOT ----------
plot = pg.PlotWidget(title="Velocity (yellow) | Reference (cyan) | Theory (magenta)")
plot.showGrid(x=True, y=True)
plot.setLabel('bottom', 'Time', units='s')

curve_vel = plot.plot(pen=pg.mkPen('y', width=2))
curve_ref = plot.plot(pen=pg.mkPen('c', width=2))
curve_theory = plot.plot(pen=pg.mkPen('m', width=2))

layout.addWidget(plot)

# ---------- SIGNALS ----------
btn_refresh.clicked.connect(refresh_ports)
btn_connect.clicked.connect(connect_port)
btn_disconnect.clicked.connect(disconnect_port)
btn_apply.clicked.connect(update_params)

btn_csv_win.clicked.connect(export_csv_window)
btn_mat_win.clicked.connect(export_mat_window)
btn_csv_all.clicked.connect(export_csv_all)
btn_mat_all.clicked.connect(export_mat_all)

# ---------- STARTUP ----------
refresh_ports()
set_status("DISCONNECTED")

def delayed_autoconnect():
    if combo_ports.count() > 0:
        connect_port()

QtCore.QTimer.singleShot(800, delayed_autoconnect)

# ---------- TIMER ----------
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(16)

main.show()
app.exec_()
