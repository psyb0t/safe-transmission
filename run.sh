#!/bin/bash

# Exit immediately if a command exits with a non-zero status, and treat unset variables as an error
set -euo pipefail

# Function to cleanly stop processes
cleanup() {
    echo "Caught signal or error, stopping OpenVPN, Transmission, and Nginx..."

    if [[ -n "${openvpn_pid-}" ]]; then
        kill -SIGTERM "$openvpn_pid" 2>/dev/null || true
        wait "$openvpn_pid" 2>/dev/null || true
    fi

    if [[ -n "${transmission_pid-}" ]]; then
        kill -SIGTERM "$transmission_pid" 2>/dev/null || true
        wait "$transmission_pid" 2>/dev/null || true
    fi

    if [[ -n "${nginx_pid-}" ]]; then
        kill -SIGTERM "$nginx_pid" 2>/dev/null || true
        wait "$nginx_pid" 2>/dev/null || true
    fi

    echo "All processes have been stopped. Exiting."
    exit 1
}

# Function to check the status of a process
check_process() {
    local pid=$1
    local name=$2
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "$name has terminated unexpectedly."
        cleanup
    fi
}

# Trap termination signals and errors
trap cleanup SIGINT SIGTERM ERR

AUTH_CONF_FILE="/etc/nginx/conf.d/auth.conf"
HTPASSWD_FILE="/etc/nginx/.htpasswd"
VPN_CONFIG_FILE="/vpn-config.ovpn"
VPN_AUTH_FILE="/vpn-auth.txt"
TUN_FILE="/dev/net/tun"
CONFIG_DIR="/config"
DOWNLOADS_DIR="/downloads"
INCOMPLETE_DOWNLOADS_DIR="/downloads/_incomplete"
WATCH_DIR="/watch"

echo "" >$AUTH_CONF_FILE

# Setup authentication if environment variables are set
if [[ -n "${USERNAME-}" && -n "${PASSWORD-}" ]]; then
    echo "Setting up HTTP basic authentication..."
    htpasswd -bc "$HTPASSWD_FILE" "$USERNAME" "$PASSWORD"
    echo 'auth_basic "Restricted Content";' >$AUTH_CONF_FILE
    echo 'auth_basic_user_file '"$HTPASSWD_FILE"';' >>$AUTH_CONF_FILE
else
    echo "No HTTP basic authentication will be used."
fi

echo "Starting Nginx..."
nginx -g 'daemon off;' &
nginx_pid=$!
if ! kill -0 $nginx_pid 2>/dev/null; then
    echo "Failed to start Nginx."
    cleanup
fi

# Start OpenVPN if WITH_OPENVPN is set to "true"
if [[ "${WITH_OPENVPN-}" == "true" ]]; then
    echo "Ensuring the TUN device is available..."

    mkdir -p /dev/net
    if [ ! -c "$TUN_FILE" ]; then
        mknod $TUN_FILE c 10 200
        chmod 600 $TUN_FILE
    fi

    if [ ! -f "$VPN_CONFIG_FILE" ]; then
        echo "OpenVPN configuration file not found: $VPN_CONFIG_FILE"
        cleanup
    fi

    echo "Starting OpenVPN..."
    openvpn_cmd="openvpn --config $VPN_CONFIG_FILE"

    if [ -f "$VPN_AUTH_FILE" ]; then
        openvpn_cmd="$openvpn_cmd --auth-user-pass $VPN_AUTH_FILE"
    fi

    $openvpn_cmd &
    openvpn_pid=$!
    if ! kill -0 $openvpn_pid 2>/dev/null; then
        echo "Failed to start OpenVPN."
        cleanup
    fi

    # Wait for the VPN to establish a connection
    sleep 10
else
    echo "OpenVPN will not be started."
fi

echo "Starting Transmission..."
# Ensure correct permissions on the transmission directories
chown -R "$PUID":"$PGID" "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

chown -R "$PUID":"$PGID" "$DOWNLOADS_DIR"
chmod -R 755 "$DOWNLOADS_DIR"

chown -R "$PUID":"$PGID" "$WATCH_DIR"
chmod -R 755 "$WATCH_DIR"

# Run Transmission as the specified user
su-exec "$PUID":"$PGID" transmission-daemon \
    --foreground \
    --config-dir "$CONFIG_DIR" \
    --download-dir "$DOWNLOADS_DIR" \
    --incomplete-dir "$INCOMPLETE_DOWNLOADS_DIR" \
    --incomplete-dir-enabled \
    --watch-dir "$WATCH_DIR" \
    --watch-dir-enabled &

transmission_pid=$!
if ! kill -0 $transmission_pid 2>/dev/null; then
    echo "Failed to start Transmission."
    cleanup
fi

# Background loop to monitor the processes
while true; do
    check_process $nginx_pid "Nginx"
    check_process $transmission_pid "Transmission"
    if [[ -n "${openvpn_pid-}" ]]; then
        check_process "$openvpn_pid" "OpenVPN"
    fi
    sleep 1
done &

monitor_pid=$!

# Wait for all processes to finish
wait $nginx_pid
nginx_status=$?

wait $transmission_pid
transmission_status=$?

if [[ -n "${openvpn_pid-}" ]]; then
    wait "$openvpn_pid"
    openvpn_status=$?
else
    openvpn_status=0
fi

kill $monitor_pid 2>/dev/null

# Check the exit statuses
if [[ $nginx_status -ne 0 || $transmission_status -ne 0 || $openvpn_status -ne 0 ]]; then
    cleanup
else
    echo "All processes completed successfully. Exiting."
    exit 0
fi
