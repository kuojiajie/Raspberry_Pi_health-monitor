# Health Monitor

A lightweight Linux / Raspberry Pi health monitoring daemon written in Bash.

It monitors network, CPU, memory, and disk usage, and runs as a long-running systemd service with automatic restart support.

---

## Features

- Network connectivity check (ping)
- CPU load monitoring (load average)
- Memory availability monitoring
- Disk usage monitoring
- Modular check architecture
- systemd integration with auto-restart
- Non-root service execution
- Environment-based configuration
- journald logging integration

---

## Project Structure

```text
health-monitor/
├── config/
│   ├── config.example
│   └── health-monitor.env
│
├── daemon/
│   └── health_monitor.sh
│
├── lib/
│   └── logger.sh
│
├── scripts/
│   ├── network_check.sh
│   ├── cpu_check.sh
│   ├── memory_check.sh
│   └── disk_check.sh
│
├── systemd/
│   └── health-monitor.service.example
│
├── tools/
│   └── crash_test.sh
│
├── logs/
│   └── .gitkeep
│
├── .gitignore
└── README.md
```

---

## Configuration (Environment File)

Configuration is loaded via systemd:

```bash
EnvironmentFile=/home/your_user/projects/health-monitor/config/health-monitor.env
```

Example `health-monitor.env`:

```bash
PING_TARGET=8.8.8.8
CHECK_INTERVAL=30

CPU_LOAD_WARN=1.50
CPU_LOAD_ERROR=3.00

MEM_AVAIL_WARN_PCT=15
MEM_AVAIL_ERROR_PCT=5

DISK_USED_WARN_PCT=80
DISK_USED_ERROR_PCT=90
```

No `export` keyword required.

---

## Logging

Logging is handled through stdout/stderr and captured by systemd journald.

View logs:

```text
sudo journalctl -u health-monitor.service -f
```

Log format:

```text
[YYYY-MM-DD HH:MM:SS] [LEVEL] message
```

Example:

```text
[2026-02-10 19:53:29] [INFO] CPU OK (load1=0.05)
```

---

## Manual Run (Development Only)

If running manually, you must define required environment variables:
```bash
export PING_TARGET=8.8.8.8
export CHECK_INTERVAL=30
bash daemon/health_monitor.sh
```

Stop with:

```text
Ctrl + C
```

---

## systemd Installation

1. Copy service template:

```bash
sudo cp systemd/health-monitor.service.example \
  /etc/systemd/system/health-monitor.service
```

2. Edit user paths inside the file.

3. Reload & start

```bash
sudo systemctl daemon-reload
sudo systemctl enable health-monitor.service
sudo systemctl start health-monitor.service
```

4. Check status
```bash
systemctl status health-monitor.service
```

---

## Restart Policy

Service includes:

```ini
Restart=always
RestartSec=5
```

If the daemon exits with a non-zero code, systemd restarts it after 5 seconds.

---

## Crash test

To test restart behavior:

```bash
bash tools/crash_test.sh
```

Then monitor:

```bash
sudo journalctl -u health-monitor.service -f
```

---

## Module Design Philosophy
Each check module:
- Returns exit codes only
    - `0` = OK
    - `1` = WARN
    - `2` = ERROR
- Does not log directly
- Exposes helper functionis for metrics
Architecture separation:
- Orchestration → `daemon/`
- Health checks → `scripts/`
- Logging abstraction → `lib/`
- Deployment layer → `systemd/`

---
