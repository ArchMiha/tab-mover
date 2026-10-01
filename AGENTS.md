# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chrome extension that moves the active browser tab to a new window in the user's main Chromium browser. Uses Chrome Native Messaging to communicate between the extension and a Python host process.

## Architecture

```
┌─────────────────────────────┐     Native Messaging     ┌──────────────────────────────┐
│   Chrome Extension          │◄───────────────────────►│   Python Native Host         │
│   (background.js)           │      JSON over stdio     │   (tab_mover_host.py)        │
│                             │                          │                              │
│   - Keyboard shortcut       │                          │   - Receives URL from ext    │
│   - Icon click handler      │                          │   - Opens URL in new window  │
│   - Closes original tab     │                          │     using default profile    │
└─────────────────────────────┘                          └──────────────────────────────┘
```

**Extension** (`extension/`): Manifest V3 service worker that captures Ctrl+Shift+G or toolbar click, sends URL to native host via `chrome.runtime.sendNativeMessage`.

**Native Host** (`native-host/tab_mover_host.py`): Python script using Chrome Native Messaging protocol (4-byte length prefix + JSON). Opens URL in a new window using the default Chromium profile.

## Installation

1. Load extension unpacked at `chrome://extensions` (enable Developer mode)
2. Copy the 32-character extension ID
3. Run `./install.sh` and paste the extension ID when prompted

The install script:
- Copies native host to `~/.local/share/tab-mover/`
- Creates host manifest in `~/.config/chromium/NativeMessagingHosts/` (or google-chrome equivalent)

## Key Configuration

- Host name: `com.tabmover.host` (must match in manifest.json, background.js, and host JSON)
- Keyboard shortcut: `Ctrl+Shift+G`

## Testing Native Host Directly

```bash
# Test the native host manually (requires proper message format)
echo -en '\x0d\x00\x00\x00{"action":"ping"}' | python3 native-host/tab_mover_host.py
```
