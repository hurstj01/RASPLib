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
ser = None
rxbuf = bytearray()   # robust packet framing buffer

# Default model parameters
K = 59.0
TAU = 0.08
VSTART = 0.5
SCALE = 20.0   # visualization only

OFFSET = -VSTART * K
y_theory = 0.0

# Plot settings
MAX_POINTS = 1000
PACK_FMT = "<fff"
PACK_SIZE = 12

# Safety: cap parsing per GUI tick so the UI never "hangs" if the device floods data
MAX_PACKETS_PER_TICK = 250

# Rolling buffers
t_data = []
vel_data = []
ref_data = []
theory_data = []

# Full logs
full_t = []
full_vel = []
full_ref = []
full_theory = []

current_time_s = 0.0


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


def update():
    """Timer callback: read serial bytes, parse <fff> packets, update plots."""
    global current_time_s, y_theory, ser, rxbuf
    global K, TAU, VSTART, SCALE, OFFSET

    if ser is None:
        return

    try:
        # Non-blocking read of whatever is available
        n = ser.in_waiting
        if n > 0:
            rxbuf.extend(ser.read(n))
    except Exception as e:
        # If serial dies mid-run, show it and stop reading
        print(f"[SER] Read error: {repr(e)}")
        return

    # Parse as many whole packets as are available, but cap per tick to keep UI responsive
    parsed = 0
    while len(rxbuf) >= PACK_SIZE and parsed < MAX_PACKETS_PER_TICK:
        pkt = rxbuf[:PACK_SIZE]
        del rxbuf[:PACK_SIZE]

        try:
            vel, ref, dt_us = struct.unpack(PACK_FMT, pkt)
        except Exception:
            # If framing gets corrupted (e.g., ASCII mixed in), flush buffer to recover
            rxbuf.clear()
            print("[SER] Packet decode error; buffer flushed. (Are you streaming ASCII instead of binary?)")
            break

        dt_s = dt_us * 1e-6
        current_time_s += dt_s

        # First-order model (uses raw ref, NOT scaled)
        if TAU > 0:
            dy = (-1.0 / TAU) * y_theory + (K / TAU) * ref
            y_theory += dy * dt_s

        theory = y_theory + OFFSET

        # Visualization scaling only
        ref_vis = ref * SCALE

        # Rolling buffers
        t_data.append(current_time_s)
        vel_data.append(vel)
        ref_data.append(ref_vis)
        theory_data.append(theory)

        if len(t_data) > MAX_POINTS:
            t_data.pop(0)
            vel_data.pop(0)
            ref_data.pop(0)
            theory_data.pop(0)

        # Full logs
        full_t.append(current_time_s)
        full_vel.append(vel)
        full_ref.append(ref)
        full_theory.append(theory)

        parsed += 1

    # Update plot curves (even if nothing parsed, this is cheap)
    curve_vel.setData(t_data, vel_data)
    curve_ref.setData(t_data, ref_data)
    curve_theory.setData(t_data, theory_data)


def refresh_ports():
    combo_ports.clear()
    ports = list(list_ports.comports())
    for p in ports:
        combo_ports.addItem(p.device)

    # Prefer last successful port
    global LAST_GOOD_PORT
    if LAST_GOOD_PORT:
        for i in range(combo_ports.count()):
            if combo_ports.itemText(i) == LAST_GOOD_PORT:
                combo_ports.setCurrentIndex(i)
                return

    # Fallback
    if combo_ports.count() > 0:
        combo_ports.setCurrentIndex(0)


def connect_port():
    global ser, LAST_GOOD_PORT, rxbuf
    port = combo_ports.currentText()

    if not port:
        btn_connect.setText("Failed / click to reconnect")
        btn_connect.setToolTip("No COM port selected.")
        set_status("FAILED", "No COM port selected.")
        print("[CONNECT] No COM port selected.")
        return

    try:
        if ser and ser.is_open:
            ser.close()
    except Exception:
        pass

    print(f"[CONNECT] Trying {port} @ 115200")
    set_status("CONNECTING", f"Trying {port} @ 115200")
    try:
        ser = serial.Serial(port, 115200, timeout=0)  # timeout=0 => non-blocking
        # Give boards that auto-reset on open a moment to boot
        QtCore.QThread.msleep(150)
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
        btn_connect.setToolTip(f"Failed to open {port}\n{repr(e)}")
        set_status("FAILED", f"Failed to open {port}: {repr(e)}")
        print(f"[CONNECT] FAILED to open {port}: {repr(e)}")


def disconnect_port():
    global ser, rxbuf
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
    global K, TAU, VSTART, SCALE, OFFSET, y_theory
    try:
        K = float(edit_K.text())
        TAU = float(edit_TAU.text())
        VSTART = float(edit_VSTART.text())
        SCALE = float(edit_SCALE.text())
        OFFSET = -VSTART * K
        y_theory = 0.0
        print(f"[PARAMS] K={K}, TAU={TAU}, VSTART={VSTART}, SCALE={SCALE}")
    except Exception as e:
        print(f"[PARAMS] Failed to parse params: {repr(e)}")


# ---------- GUI ----------
app = QtWidgets.QApplication([])
win = QtWidgets.QWidget()
win.setWindowTitle("Velocity Logger")
layout = QtWidgets.QVBoxLayout(win)

ctrl = QtWidgets.QGridLayout()

combo_ports = QtWidgets.QComboBox()
btn_refresh = QtWidgets.QPushButton("Refresh Ports")
btn_connect = QtWidgets.QPushButton("Connect")
btn_disconnect = QtWidgets.QPushButton("Disconnect")
lbl_status = QtWidgets.QLabel("● Disconnected")
lbl_status.setToolTip("Serial disconnected")
lbl_status.setStyleSheet("QLabel { color: #666666; font-weight: bold; }")

ctrl.addWidget(QtWidgets.QLabel("COM Port:"), 0, 0)
ctrl.addWidget(combo_ports, 0, 1)
ctrl.addWidget(btn_refresh, 0, 2)
ctrl.addWidget(btn_connect, 0, 3)
ctrl.addWidget(btn_disconnect, 0, 4)
ctrl.addWidget(lbl_status, 0, 5)

# ---- Model parameters ----
ctrl.addWidget(QtWidgets.QLabel("<b>Model parameters</b>"), 1, 0)

edit_K = QtWidgets.QLineEdit(str(K))
edit_TAU = QtWidgets.QLineEdit(str(TAU))
edit_VSTART = QtWidgets.QLineEdit(str(VSTART))
btn_apply = QtWidgets.QPushButton("Apply Params")

ctrl.addWidget(QtWidgets.QLabel("K:"), 2, 0)
ctrl.addWidget(edit_K, 2, 1)
ctrl.addWidget(QtWidgets.QLabel("Tau:"), 2, 2)
ctrl.addWidget(edit_TAU, 2, 3)
ctrl.addWidget(QtWidgets.QLabel("VSTART:"), 2, 4)
ctrl.addWidget(edit_VSTART, 2, 5)
ctrl.addWidget(btn_apply, 2, 6)

# ---- Reference input scaling ----
ctrl.addWidget(QtWidgets.QLabel("<b>Reference input scaling</b>"), 3, 0)

edit_SCALE = QtWidgets.QLineEdit(str(SCALE))
ctrl.addWidget(QtWidgets.QLabel("Scale:"), 4, 0)
ctrl.addWidget(edit_SCALE, 4, 1)

layout.addLayout(ctrl)

# ---------- PLOT ----------
plot = pg.PlotWidget(title="Velocity (yellow) | Reference/Input (cyan) | Theory+Offset (magenta)")
plot.showGrid(x=True, y=True)
plot.setLabel('bottom', 'Time', units='s')
plot.addLegend(offset=(10, 10))

curve_vel = plot.plot(pen=pg.mkPen('y', width=2), name="Velocity")
curve_ref = plot.plot(pen=pg.mkPen('c', width=2), name="Reference / Input")
curve_theory = plot.plot(pen=pg.mkPen('m', width=2), name="Theory+Offset")

layout.addWidget(plot)

# ---------- SIGNALS ----------
btn_refresh.clicked.connect(refresh_ports)
btn_connect.clicked.connect(connect_port)
btn_disconnect.clicked.connect(disconnect_port)
btn_apply.clicked.connect(update_params)

# ---------- STARTUP ----------
refresh_ports()
set_status("DISCONNECTED")

def delayed_autoconnect():
    if combo_ports.count() > 0:
        connect_port()

QtCore.QTimer.singleShot(800, delayed_autoconnect)

timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(50)

win.resize(1100, 650)
win.show()
app.exec_()
