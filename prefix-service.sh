#!/bin/bash

# Prefix Service Management Script
# This script helps manage the prefix LaunchAgent

PLIST_NAME="com.prefix"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist"
BINARY_PATH="$(brew --prefix)/bin/prefix"
DOMAIN="gui/$(id -u)"

# Helper function to check if service is loaded (works with both bootstrap and load)
is_service_loaded() {
    if launchctl list "$DOMAIN/$PLIST_NAME" &>/dev/null; then
        return 0  # bootstrap method
    elif launchctl list | grep -q "$PLIST_NAME"; then
        return 0  # load method
    else
        return 1
    fi
}

# Helper function to start the service
start_service() {
    if launchctl bootstrap "$DOMAIN" "$PLIST_PATH" 2>/dev/null; then
        return 0
    elif launchctl load -w "$PLIST_PATH" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Helper function to stop the service
stop_service() {
    if launchctl bootout "$DOMAIN/$PLIST_NAME" 2>/dev/null; then
        return 0
    elif launchctl unload "$PLIST_PATH" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

case "$1" in
    install)
        echo "Installing prefix LaunchAgent..."
        
        # Check if binary exists
        if [ ! -f "$BINARY_PATH" ]; then
            echo "Error: prefix binary not found at $BINARY_PATH"
            echo "Please install prefix first: brew install prefix"
            exit 1
        fi
        
        # Check if config exists
        if [ ! -f "$HOME/.prefix.yaml" ]; then
            echo "Warning: Config file not found at ~/.prefix.yaml"
            echo "Please create and configure ~/.prefix.yaml before starting the service"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        
        # Create LaunchAgents directory if it doesn't exist
        mkdir -p "$LAUNCH_AGENTS_DIR"
        
        # Generate plist with correct binary path
        cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/prefix.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/prefix.error.log</string>
    
    <key>WorkingDirectory</key>
    <string>$HOME</string>
    
    <key>ProcessType</key>
    <string>Background</string>
    
    <key>Nice</key>
    <integer>1</integer>
</dict>
</plist>
EOF
        
        # Load the service (use bootstrap for newer macOS versions)
        if launchctl bootstrap gui/$(id -u) "$PLIST_PATH" 2>/dev/null; then
            echo "✓ LaunchAgent installed and started (bootstrap)"
        elif launchctl load -w "$PLIST_PATH" 2>/dev/null; then
            echo "✓ LaunchAgent installed and started (load)"
        else
            echo "⚠ LaunchAgent installed but failed to start automatically"
            echo "  Try: launchctl load -w $PLIST_PATH"
        fi
        echo "  Service will automatically start on boot"
        echo "  Logs: ~/Library/Logs/prefix.log"
        ;;
    
    uninstall)
        echo "Uninstalling prefix LaunchAgent..."
        
        # Stop the service if it's running
        if [ -f "$PLIST_PATH" ]; then
            if stop_service; then
                echo "✓ Service stopped"
            fi
            rm -f "$PLIST_PATH"
            echo "✓ LaunchAgent uninstalled"
        else
            echo "LaunchAgent not found"
        fi
        ;;
    
    start)
        if [ ! -f "$PLIST_PATH" ]; then
            echo "Error: LaunchAgent not installed"
            echo "Run: prefix-service install"
            exit 1
        fi
        
        if is_service_loaded; then
            echo "Service is already running"
        elif start_service; then
            echo "✓ Service started"
        else
            echo "✗ Failed to start service"
            exit 1
        fi
        ;;
    
    stop)
        if [ ! -f "$PLIST_PATH" ]; then
            echo "Error: LaunchAgent not installed"
            exit 1
        fi
        
        if ! is_service_loaded; then
            echo "Service is not running"
        elif stop_service; then
            echo "✓ Service stopped"
        else
            echo "✗ Failed to stop service (may not be running)"
        fi
        ;;
    
    restart)
        echo "Restarting prefix service..."
        if [ -f "$PLIST_PATH" ]; then
            stop_service 2>/dev/null || true
            sleep 1
            if start_service; then
                echo "✓ Service restarted"
            else
                echo "✗ Failed to restart service"
                exit 1
            fi
        else
            echo "Error: LaunchAgent not installed"
            echo "Run: prefix-service install"
            exit 1
        fi
        ;;
    
    status)
        if [ ! -f "$PLIST_PATH" ]; then
            echo "Status: Not installed"
            exit 0
        fi
        
        if is_service_loaded; then
            echo "Status: Running"
            # Try to get PID (works differently for bootstrap vs load)
            PID=$(launchctl list "$DOMAIN/$PLIST_NAME" 2>/dev/null | tail -1 | awk '{print $1}' || \
                  launchctl list | grep "$PLIST_NAME" | awk '{print $1}' || echo "N/A")
            if [ "$PID" != "N/A" ] && [ "$PID" != "-" ]; then
                echo "PID: $PID"
            fi
        else
            echo "Status: Stopped"
        fi
        
        echo ""
        echo "Config: $HOME/.prefix.yaml"
        if [ -f "$HOME/.prefix.yaml" ]; then
            echo "  ✓ Config file exists"
        else
            echo "  ✗ Config file missing"
        fi
        
        echo ""
        echo "Logs:"
        if [ -f "$HOME/Library/Logs/prefix.log" ]; then
            LOG_SIZE=$(ls -lh "$HOME/Library/Logs/prefix.log" | awk '{print $5}')
            echo "  Output: $HOME/Library/Logs/prefix.log ($LOG_SIZE)"
        else
            echo "  Output: $HOME/Library/Logs/prefix.log (not created yet)"
        fi
        if [ -f "$HOME/Library/Logs/prefix.error.log" ]; then
            ERR_SIZE=$(ls -lh "$HOME/Library/Logs/prefix.error.log" | awk '{print $5}')
            echo "  Errors: $HOME/Library/Logs/prefix.error.log ($ERR_SIZE)"
        else
            echo "  Errors: $HOME/Library/Logs/prefix.error.log (no errors)"
        fi
        ;;
    
    logs)
        if [ -f "$HOME/Library/Logs/prefix.log" ]; then
            tail -f "$HOME/Library/Logs/prefix.log"
        else
            echo "Log file not found. Service may not be running."
        fi
        ;;
    
    *)
        echo "Usage: $0 {install|uninstall|start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  install   - Install and start the LaunchAgent"
        echo "  uninstall - Remove the LaunchAgent"
        echo "  start    - Start the service"
        echo "  stop     - Stop the service"
        echo "  restart  - Restart the service"
        echo "  status   - Show service status"
        echo "  logs     - Follow log output"
        exit 1
        ;;
esac
