#!/usr/bin/env python3
"""
pkg-watt-stat - CPU Package Power Consumption Monitor Service

This service runs turbostat to monitor CPU package power consumption 
and exposes the data via Unix socket for userland applications.
"""

import subprocess
import socket
import os
import sys
import signal
import time
import threading
import json
import re
import logging
import select
import argparse
from pathlib import Path

SOCKET_PATH = "/tmp/pkg-watt-stat.sock"
TURBOSTAT_INTERVAL = 4  # seconds


class PkgWattMonitor:
    def __init__(self, log_level=logging.INFO):
        self.running = False
        self.current_power = 0.0
        self.last_update = 0
        self.clients = []
        self.lock = threading.Lock()
        self.turbostat_process = None
        
        # Setup logging
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('pkg-watt-stat')
        
    def cleanup_socket(self):
        """Remove existing socket file if it exists"""
        try:
            os.unlink(SOCKET_PATH)
        except OSError:
            pass
            
    def parse_turbostat_line(self, line):
        """Parse a turbostat output line to extract PkgWatt value"""
        try:
            # Debug: log every line we receive
            self.logger.debug(f"Received line: '{line}'")
            
            # Skip header lines and empty lines
            if line.startswith('PkgWatt') or not line.strip():
                self.logger.debug("Skipping header/empty line")
                return None
                
            # Try to parse the line as a float (simple format)
            line = line.strip()
            if line:
                try:
                    pkg_watt = float(line)
                    self.logger.debug(f"Parsed PkgWatt: {pkg_watt}W")
                    return pkg_watt
                except ValueError:
                    self.logger.debug(f"Could not parse '{line}' as float")
                    return None
            else:
                self.logger.debug("Empty line after strip")
                return None
        except Exception as e:
            self.logger.debug(f"Error parsing line '{line}': {e}")
            return None
            
    def run_turbostat(self):
        """Run turbostat and parse output continuously"""
        cmd = [
            'turbostat', 
            '--quiet',  # Skip system configuration header
            '--interval', str(TURBOSTAT_INTERVAL),
            '--show', 'PkgWatt'  # Only show package power
        ]
        
        try:
            self.logger.info("Starting turbostat monitoring...")
            self.turbostat_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                bufsize=1
            )
            
            while self.running:
                # Use select to make readline non-blocking with timeout
                ready, _, _ = select.select([self.turbostat_process.stdout], [], [], 1.0)
                if not ready:
                    continue  # Timeout, check self.running again
                    
                line = self.turbostat_process.stdout.readline()
                if not line:
                    if self.turbostat_process.poll() is not None:
                        break
                    continue
                    
                power = self.parse_turbostat_line(line.strip())
                if power is not None:
                    with self.lock:
                        self.current_power = power
                        self.last_update = time.time()
                    self.logger.debug(f"Updated power: {power}W")
                    
        except Exception as e:
            self.logger.error(f"Error running turbostat: {e}")
        finally:
            self.cleanup_turbostat()
    
    def cleanup_turbostat(self):
        """Clean up turbostat process"""
        if self.turbostat_process:
            try:
                self.turbostat_process.terminate()
                self.turbostat_process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.logger.warning("Turbostat didn't terminate, killing...")
                self.turbostat_process.kill()
                self.turbostat_process.wait()
            except Exception as e:
                self.logger.error(f"Error cleaning up turbostat: {e}")
            finally:
                self.turbostat_process = None
                
    def handle_client(self, client_socket):
        """Handle a client connection"""
        try:
            while self.running:
                with self.lock:
                    data = {
                        'power_watts': self.current_power,
                        'timestamp': self.last_update,
                        'status': 'ok'
                    }
                
                response = json.dumps(data) + '\n'
                try:
                    client_socket.send(response.encode())
                    time.sleep(0.1)  # Send updates every 100ms
                except (BrokenPipeError, ConnectionResetError):
                    break
                    
        except Exception as e:
            self.logger.debug(f"Client handler error: {e}")
        finally:
            try:
                client_socket.close()
            except:
                pass
                
    def run_socket_server(self):
        """Run the Unix socket server"""
        self.cleanup_socket()
        
        try:
            server_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            server_socket.bind(SOCKET_PATH)
            server_socket.listen(5)
            server_socket.settimeout(1.0)  # Non-blocking with timeout
            
            # Make socket accessible to all users
            os.chmod(SOCKET_PATH, 0o666)
            
            self.logger.info(f"Socket server listening on {SOCKET_PATH}")
            
            while self.running:
                try:
                    client_socket, _ = server_socket.accept()
                    self.logger.debug("Client connected")
                    
                    # Handle client in a separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket,)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except socket.timeout:
                    continue  # Check self.running again
                except Exception as e:
                    if self.running:
                        self.logger.error(f"Socket server error: {e}")
                        
        except Exception as e:
            self.logger.error(f"Failed to create socket server: {e}")
        finally:
            try:
                server_socket.close()
            except:
                pass
            self.cleanup_socket()
            
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
        self.cleanup_turbostat()
        
    def run(self):
        """Main service loop"""
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        self.running = True
        self.logger.info("Starting pkg-watt-stat service...")
        
        # Start turbostat monitoring thread
        turbostat_thread = threading.Thread(target=self.run_turbostat)
        turbostat_thread.daemon = True
        turbostat_thread.start()
        
        # Start socket server (blocks until shutdown)
        self.run_socket_server()
        
        self.logger.info("Service stopped")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='CPU Package Power Consumption Monitor Service')
    parser.add_argument('--log-level', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'], 
                       default='INFO', help='Set logging level (default: INFO)')
    args = parser.parse_args()
    
    if os.geteuid() != 0:
        print("This service requires root privileges to access turbostat", file=sys.stderr)
        sys.exit(1)
        
    # Convert log level string to logging constant
    log_level = getattr(logging, args.log_level.upper())
    
    monitor = PkgWattMonitor(log_level=log_level)
    try:
        monitor.run()
    except KeyboardInterrupt:
        monitor.logger.info("Interrupted by user")
    except Exception as e:
        monitor.logger.error(f"Service error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()