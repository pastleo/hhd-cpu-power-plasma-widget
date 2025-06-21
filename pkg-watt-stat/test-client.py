#!/usr/bin/env python3
"""
Simple test client for pkg-watt-stat service
"""

import socket
import json
import time

SOCKET_PATH = "/tmp/pkg-watt-stat.sock"

def test_connection():
    try:
        # Connect to Unix socket
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(SOCKET_PATH)
        
        print("Connected to pkg-watt-stat service")
        print("Receiving power data (Ctrl+C to stop):")
        print()
        
        while True:
            data = client.recv(1024).decode().strip()
            if data:
                try:
                    power_data = json.loads(data)
                    print(f"Power: {power_data['power_watts']:.2f}W | "
                          f"Time: {time.strftime('%H:%M:%S', time.localtime(power_data['timestamp']))}")
                except json.JSONDecodeError:
                    print(f"Raw data: {data}")
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        print("\nDisconnected")
    except FileNotFoundError:
        print(f"Error: Socket {SOCKET_PATH} not found. Is the service running?")
    except ConnectionRefusedError:
        print("Error: Connection refused. Is the service running?")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        try:
            client.close()
        except:
            pass

if __name__ == "__main__":
    test_connection()