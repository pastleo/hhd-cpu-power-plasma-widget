# pkg-watt-stat

CPU Package Power Consumption Monitor Service that exposes real-time power consumption data via Unix socket for userland applications.

## Overview

`pkg-watt-stat` is a systemd service that runs `turbostat` to monitor CPU package power consumption and exposes the data through a Unix socket at `/tmp/pkg-watt-stat.sock`. This allows other applications (like Plasma widgets) to access real-time power consumption data without requiring root privileges.

## Features

- Real-time CPU package power monitoring using `turbostat`
- Unix socket API for easy integration with userland applications
- JSON-formatted data output
- Systemd service integration
- Configurable logging levels
- Multi-client support

## Installation (AUR Package)

This project includes an Arch Linux package (PKGBUILD) for easy installation:

```bash
# Build and install the package
makepkg -si

# Enable and start the service
sudo systemctl enable pkg-watt-stat.service
sudo systemctl start pkg-watt-stat.service
```

## Manual Installation

1. Copy `pkg-watt-stat.py` to `/usr/bin/pkg-watt-stat`
2. Copy `pkg-watt-stat.service` to `/usr/lib/systemd/system/`
3. Make the script executable: `sudo chmod +x /usr/bin/pkg-watt-stat`
4. Enable and start the service:
   ```bash
   sudo systemctl enable pkg-watt-stat.service
   sudo systemctl start pkg-watt-stat.service
   ```

## Dependencies

- Python 3
- `turbostat` (part of linux-tools or similar package)
- Root privileges (for accessing turbostat)

## Usage

### Service Management

```bash
# Start the service
sudo systemctl start pkg-watt-stat.service

# Stop the service
sudo systemctl stop pkg-watt-stat.service

# Check service status
sudo systemctl status pkg-watt-stat.service

# View logs
sudo journalctl -u pkg-watt-stat.service -f
```

### API Usage

Connect to the Unix socket at `/tmp/pkg-watt-stat.sock` to receive JSON data:

```python
import socket
import json

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect('/tmp/pkg-watt-stat.sock')

data = sock.recv(1024).decode().strip()
power_info = json.loads(data)
print(f"Power: {power_info['power_watts']}W")
```

### JSON Response Format

```json
{
  "power_watts": 15.2,
  "timestamp": 1640995200.123,
  "status": "ok"
}
```

## Configuration

The service accepts the following command-line arguments:

- `--log-level`: Set logging level (DEBUG, INFO, WARNING, ERROR)

## Files

- `pkg-watt-stat.py`: Main service script
- `pkg-watt-stat.service`: Systemd service file
- `pkg-watt-stat.install`: Post-install script for AUR package
- `PKGBUILD`: Arch Linux package build script
- `test-client.py`: Example client for testing the service

## Testing

Use the included test client to verify the service is working:

```bash
python test-client.py
```

## License

MIT License