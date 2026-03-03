import struct
import serial
import csv
import scipy.io as sio
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
from serial.tools import list_ports

# ---------- GLOBALS ----------
ser = None

# Motor plant parameters
K = 55.0          # steady-state gain
TAU = 0.055       # time constant (seconds)

# --- PI Controller Params (MATCH FIRMWARE) ---
kP = 0.0144
kI = 0.0144 * 47
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


# ---------- UPDATE FUNCTION ----------
def update():
    global current_time_s, y_theory, z_pi
    global ser, K, TAU, kP, kI
    global dt_print_timer

    if ser is None:
        return

    while ser.in_waiting >= PACK_SIZE:
        raw = ser.read(PACK_SIZE)

        try:
            vel, ref, dt_us = struct.unpack(PACK_FMT, raw)
        except:
            continue

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
    # Sort ports numerically, highest last
    port_list = sorted(
        [p.device for p in list_ports.comports()],
        key=lambda s: int(''.join(filter(str.isdigit, s))) if any(c.isdigit() for c in s) else -1
    )

    combo_ports.clear()
    combo_ports.addItems(port_list)

    # Auto-select highest COM
    if port_list:
        combo_ports.setCurrentText(port_list[-1])


def connect_port():
    global ser
    port = combo_ports.currentText()
    if port:
        try:
            ser = serial.Serial(port, 115200, timeout=0.01)
            btn_connect.setText("Connected")
        except:
            btn_connect.setText("Failed")


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
btn_apply.clicked.connect(update_params)

btn_csv_win.clicked.connect(export_csv_window)
btn_mat_win.clicked.connect(export_mat_window)
btn_csv_all.clicked.connect(export_csv_all)
btn_mat_all.clicked.connect(export_mat_all)

# ---------- STARTUP ----------
refresh_ports()

# ✅ Auto-connect to highest COM if available
if combo_ports.count() > 0:
    connect_port()

# ---------- TIMER ----------
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(16)

main.show()
app.exec_()
