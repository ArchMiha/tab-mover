#!/usr/bin/env python3
"""
Native Messaging Host for Tab Mover Chrome Extension.
Receives messages from the extension and opens URL in main Chromium browser.
"""

import json
import struct
import subprocess
import sys
import os

# Configuration
CHROMIUM_PATHS = [
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable'
]



def find_chromium():
    """Find available Chromium/Chrome executable."""
    for path in CHROMIUM_PATHS:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None


def read_message():
    """Read a message from stdin (native messaging protocol)."""
    # Read message length (4 bytes, native byte order)
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) == 0:
        return None

    message_length = struct.unpack('@I', raw_length)[0]

    # Read message content
    message_data = sys.stdin.buffer.read(message_length)
    return json.loads(message_data.decode('utf-8'))


def send_message(message):
    """Send a message to stdout (native messaging protocol)."""
    encoded = json.dumps(message).encode('utf-8')

    # Write message length (4 bytes, native byte order)
    sys.stdout.buffer.write(struct.pack('@I', len(encoded)))

    # Write message content
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def send_response(success, error=None, data=None):
    """Send a standardized response."""
    response = {'success': success}
    if error:
        response['error'] = error
    if data:
        response['data'] = data
    send_message(response)


def open_in_new_instance(url, title=None):
    """Open URL in new window using main Chromium profile."""

    # Find Chromium executable
    chromium_path = find_chromium()
    if not chromium_path:
        return False, 'Chromium/Chrome not found. Searched: ' + ', '.join(CHROMIUM_PATHS)

    # Validate URL (basic check)
    if not url or not url.startswith(('http://', 'https://', 'file://')):
        return False, f'Invalid URL scheme: {url}'

    # Build command - use default profile, open in new window
    cmd = [
        chromium_path,
        '--new-window',
        url
    ]

    try:
        # Launch Chromium (detached from parent process)
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
        return True, None

    except subprocess.SubprocessError as e:
        return False, f'Failed to launch Chromium: {str(e)}'
    except Exception as e:
        return False, f'Unexpected error: {str(e)}'


def main():
    """Main entry point."""
    try:
        # Read incoming message
        message = read_message()

        if message is None:
            send_response(False, 'No message received')
            return

        action = message.get('action')

        if action == 'open_in_new_instance':
            url = message.get('url')
            title = message.get('title')

            success, error = open_in_new_instance(url, title)
            send_response(success, error)

        elif action == 'ping':
            # Health check
            send_response(True, data={'status': 'alive', 'version': '1.0.0'})

        else:
            send_response(False, f'Unknown action: {action}')

    except json.JSONDecodeError as e:
        send_response(False, f'Invalid JSON: {str(e)}')
    except Exception as e:
        send_response(False, f'Host error: {str(e)}')


if __name__ == '__main__':
    main()
