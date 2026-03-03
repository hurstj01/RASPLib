#!/usr/bin/env python3
"""
Arduino_GUI_Uploader_Enhanced.pyw

Single-file Arduino compile & upload GUI with quality-of-life features:

- Lists available COM ports so you don't have to open Device Manager.
- Tries to put the most likely USB serial / Arduino ports first.
- Still lets you type any COM port manually.
- Remembers the last .ino file you used between runs.
- When browsing for a file, starts in the folder of the last file.

Requirements:
- Python 3 (associated with .pyw on Windows so you can double-click).
- arduino-cli installed and either on PATH or referenced by full path below.
- For automatic COM-port listing:
    - Preferably the 'pyserial' package installed:
        pip install pyserial
  (If pyserial is missing, it will fall back to 'arduino-cli board list'.)
"""

import json
import shutil
import subprocess
import tempfile
from pathlib import Path
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Fully qualified board name; change if you normally use a different Arduino.
DEFAULT_FQBN = "arduino:avr:mega"

# Name or full path to arduino-cli. If it's not on PATH, set this to the
# full path, e.g. r"C:\Tools\ArduinoCLI\arduino-cli.exe"
ARDUINO_CLI = "arduino-cli"

# Where to store simple config (remembers last .ino).
CONFIG_PATH = Path.home() / ".arduino_uploader_gui.json"


# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

def append_text(widget, text):
    widget.configure(state="normal")
    widget.insert("end", text)
    widget.see("end")
    widget.configure(state="disabled")
    widget.update_idletasks()


def run_cli(cmd, text_widget):
    full_cmd = [ARDUINO_CLI] + cmd
    append_text(text_widget, f"\n[cmd] {' '.join(full_cmd)}\n")

    try:
        proc = subprocess.Popen(
            full_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except FileNotFoundError:
        append_text(
            text_widget,
            "\nERROR: 'arduino-cli' not found.\n"
            "Either install it and put it on PATH, or set ARDUINO_CLI in this script\n"
            "to the full path of arduino-cli.exe.\n",
        )
        return 1

    for line in proc.stdout:
        append_text(text_widget, line)

    proc.wait()
    return proc.returncode


def list_ports_pyserial():
    """
    Use pyserial (if installed) to list COM ports.

    Returns a list of (device, label, score) tuples, where:
      - device: 'COM11'
      - label:  'COM11 - USB-SERIAL CH340 (COM11)'
      - score:  higher means more likely to be the "main" Arduino port
    """
    try:
        import serial.tools.list_ports as list_ports_mod  # type: ignore
    except Exception:
        return []

    ports = []
    for p in list_ports_mod.comports():
        dev = p.device or ""
        desc = p.description or ""
        label = f"{dev} - {desc}" if desc else dev

        score = 0
        # Prefer real USB serial devices
        upper_desc = desc.upper()
        if "USB-SERIAL" in upper_desc or "CH340" in upper_desc or "CP210" in upper_desc:
            score += 5
        if "ARDUINO" in upper_desc:
            score += 5
        if "USB" in upper_desc:
            score += 2
        # Deprioritize Bluetooth and weird virtual ports
        if "BLUETOOTH" in upper_desc:
            score -= 5

        ports.append((dev, label, score))

    # Sort by score (desc), then by device name
    ports.sort(key=lambda t: (-t[2], t[0]))
    return ports


def list_ports_arduino_cli(text_widget=None):
    """
    Fallback: use 'arduino-cli board list --format json' to list ports.

    Returns a list of (device, label, score).
    """
    try:
        result = subprocess.run(
            [ARDUINO_CLI, "board", "list", "--format", "json"],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)
    except FileNotFoundError:
        if text_widget is not None:
            append_text(
                text_widget,
                "\nCould not run 'arduino-cli board list'. Is arduino-cli installed?\n",
            )
        return []
    except Exception as e:
        if text_widget is not None:
            append_text(
                text_widget,
                f"\nError parsing 'arduino-cli board list' output: {e}\n",
            )
        return []

    ports = []
    for p in data.get("ports", []):
        dev = p.get("address") or ""
        desc = p.get("protocol") or "serial"
        label = dev
        # Some CLI versions may have a 'label' or 'protocol' / 'type' fields
        if p.get("label"):
            label = f"{dev} - {p['label']}"
            desc = p["label"]
        elif p.get("type"):
            label = f"{dev} - {p['type']}"
            desc = p["type"]

        score = 0
        u = str(desc).upper()
        if "USB" in u:
            score += 3
        if "ARDUINO" in u or "MEGA" in u or "NANO" in u or "UNO" in u:
            score += 5
        if "BLUETOOTH" in u:
            score -= 5

        ports.append((dev, label, score))

    ports.sort(key=lambda t: (-t[2], t[0]))
    return ports


def list_ports(text_widget=None):
    """
    Unified port listing:
      1) Try pyserial (best view of real Windows COM ports).
      2) If that fails, fall back to arduino-cli board list.
    """
    ports = list_ports_pyserial()
    if ports:
        return ports

    if text_widget is not None:
        append_text(
            text_widget,
            "\nNote: 'pyserial' not available, falling back to 'arduino-cli board list'.\n",
        )
    return list_ports_arduino_cli(text_widget)


def compile_and_upload(ino_path_str, fqbn, port, text_widget, button):
    ino_path = Path(ino_path_str)
    if not ino_path.is_file():
        append_text(text_widget, f"\nERROR: File not found: {ino_path}\n")
        button.config(state="normal")
        return

    sketch_name = ino_path.stem
    temp_ctx = tempfile.TemporaryDirectory(prefix=f"{sketch_name}_")
    temp_dir = Path(temp_ctx.name)
    sketch_folder = temp_dir / sketch_name
    sketch_folder.mkdir(parents=True, exist_ok=True)

    dest = sketch_folder / ino_path.name
    shutil.copy2(ino_path, dest)

    append_text(text_widget, "\n=== Compiling ===\n")
    rc = run_cli(["compile", "--fqbn", fqbn, str(sketch_folder)], text_widget)
    if rc != 0:
        append_text(text_widget, f"\nCompile failed ({rc})\n")
        button.config(state="normal")
        return

    append_text(text_widget, "\n=== Uploading ===\n")
    rc = run_cli(["upload", "-p", port, "--fqbn", fqbn, str(sketch_folder)], text_widget)
    if rc != 0:
        append_text(text_widget, f"\nUpload failed ({rc})\n")
        button.config(state="normal")
        return

    append_text(text_widget, "\nDone ✔\n")
    button.config(state="normal")


def load_config():
    if not CONFIG_PATH.is_file():
        return {}
    try:
        with CONFIG_PATH.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_config(cfg):
    try:
        with CONFIG_PATH.open("w", encoding="utf-8") as f:
            json.dump(cfg, f)
    except Exception:
        pass


# ---------------------------------------------------------------------------
# GUI Application
# ---------------------------------------------------------------------------

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Arduino Uploader")
        self.geometry("700x450")

        self.config_data = load_config()

        top = ttk.Frame(self, padding=10)
        top.pack(fill="x")

        ttk.Label(top, text=".ino file:").grid(row=0, column=0, sticky="w")
        self.ino_var = tk.StringVar()
        self.ino_entry = ttk.Entry(top, textvariable=self.ino_var, width=55)
        self.ino_entry.grid(row=0, column=1, padx=5)
        ttk.Button(top, text="Browse", command=self.browse).grid(row=0, column=2)

        # If we have a last-used .ino, restore it
        last_ino = self.config_data.get("last_ino")
        if last_ino and Path(last_ino).is_file():
            self.ino_var.set(last_ino)

        ttk.Label(top, text="FQBN:").grid(row=1, column=0, sticky="w", pady=(5, 0))
        self.fqbn_var = tk.StringVar(value=self.config_data.get("last_fqbn", DEFAULT_FQBN))
        ttk.Entry(top, textvariable=self.fqbn_var, width=40).grid(
            row=1, column=1, sticky="w", padx=5, pady=(5, 0)
        )

        ttk.Label(top, text="COM port:").grid(row=2, column=0, sticky="w", pady=(5, 0))
        self.port_var = tk.StringVar()
        self.port_combo = ttk.Combobox(top, textvariable=self.port_var, width=25)
        self.port_combo.grid(row=2, column=1, sticky="w", padx=5, pady=(5, 0))
        ttk.Button(top, text="Refresh", command=self.refresh_ports).grid(
            row=2, column=2, pady=(5, 0)
        )

        self.upload_btn = ttk.Button(top, text="Upload", command=self.start_upload)
        self.upload_btn.grid(row=3, column=1, sticky="e", pady=(10, 0))

        top.columnconfigure(1, weight=1)

        frame = ttk.Frame(self, padding=(10, 0, 10, 10))
        frame.pack(fill="both", expand=True)

        self.log = tk.Text(frame, wrap="word", state="disabled")
        self.log.pack(side="left", fill="both", expand=True)

        scroll = ttk.Scrollbar(frame, command=self.log.yview)
        scroll.pack(side="right", fill="y")
        self.log.configure(yscrollcommand=scroll.set)

        # Initial port list
        self.refresh_ports(first_time=True)

        # Ensure config is saved on close
        self.protocol("WM_DELETE_WINDOW", self.on_close)

    # ------------------------------------------------------------------
    # File browsing / config
    # ------------------------------------------------------------------

    def browse(self):
        # Decide starting directory for file dialog
        start_dir = None
        current = self.ino_var.get().strip()
        if current:
            p = Path(current)
            if p.is_file():
                start_dir = str(p.parent)
        if start_dir is None:
            last_ino = self.config_data.get("last_ino")
            if last_ino:
                p = Path(last_ino)
                if p.exists():
                    start_dir = str(p.parent)
        if start_dir is None:
            # Use directory of this script instead of System32
            try:
                script_dir = Path(__file__).resolve().parent
                start_dir = str(script_dir)
            except Exception:
                start_dir = str(Path.home())

        path = filedialog.askopenfilename(
            title="Select Arduino sketch",
            filetypes=[("Arduino sketch", "*.ino"), ("All files", "*.*")],
            initialdir=start_dir,
        )
        if path:
            self.ino_var.set(path)
            self.config_data["last_ino"] = path
            save_config(self.config_data)

    def on_close(self):
        # Save last FQBN and last .ino
        self.config_data["last_fqbn"] = self.fqbn_var.get().strip()
        ino = self.ino_var.get().strip()
        if ino:
            self.config_data["last_ino"] = ino
        save_config(self.config_data)
        self.destroy()

    # ------------------------------------------------------------------
    # Ports
    # ------------------------------------------------------------------

    def refresh_ports(self, first_time=False):
        ports = list_ports(self.log)
        labels = [p[1] for p in ports]
        self.port_combo["values"] = labels

        if labels:
            # Choose the first (most likely real USB / Arduino)
            self.port_combo.current(0)
            # Set just the device (e.g. 'COM11') into the variable
            self.port_var.set(ports[0][0])
        else:
            if not first_time:
                append_text(
                    self.log,
                    "\nNo COM ports auto-detected.\n"
                    "If your board is plugged in, you can still type a COM port\n"
                    "manually above (e.g. COM11).\n",
                )

        # If we have a saved last port and it's in the list, prefer that
        last_port = self.config_data.get("last_port")
        if last_port:
            for dev, label, _score in ports:
                if dev == last_port:
                    self.port_var.set(dev)
                    # also set combo text to label
                    self.port_combo.set(label)
                    break

    # ------------------------------------------------------------------
    # Upload
    # ------------------------------------------------------------------

    def start_upload(self):
        ino = self.ino_var.get().strip()
        fqbn = self.fqbn_var.get().strip()
        port_text = self.port_var.get().strip()

        if not ino or not fqbn or not port_text:
            messagebox.showerror("Error", "Select .ino, FQBN, and COM port.")
            return

        # If the combobox contains a label like 'COM11 - USB-SERIAL CH340',
        # extract just the device part.
        port = port_text.split()[0]

        # Remember last port & fqbn
        self.config_data["last_port"] = port
        self.config_data["last_fqbn"] = fqbn
        save_config(self.config_data)

        self.upload_btn.config(state="disabled")
        append_text(self.log, "\nStarting...\n")

        t = threading.Thread(
            target=compile_and_upload,
            args=(ino, fqbn, port, self.log, self.upload_btn),
            daemon=True,
        )
        t.start()


# ---------------------------------------------------------------------------

if __name__ == "__main__":
    App().mainloop()
