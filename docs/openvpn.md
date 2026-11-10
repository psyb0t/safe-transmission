---
title: "OpenVPN"
description: "Route safe-transmission's torrent traffic through an OpenVPN tunnel: the files it needs, the 10 second start delay, how to check the tunnel, and its limits."
nav_order: 4
---

# OpenVPN

With `WITH_OPENVPN=true`, the container starts an OpenVPN client from your provider's `.ovpn` file before it starts Transmission. The routes OpenVPN sets apply to the whole container, Transmission included. A config that has `redirect-gateway`, or a server that pushes it, sends all of the container's traffic through the tunnel.

## What it needs

- `WITH_OPENVPN=true`, spelled exactly like that.
- `--cap-add=NET_ADMIN` (or `cap_add: [NET_ADMIN]` in Compose).
- Your client config mounted as a file at `/vpn-config.ovpn`.
- If the config asks for a login, a file at `/vpn-auth.txt` with the user name on the first line and the password on the second.

[Getting started](getting-started.md#3-or-start-it-with-openvpn) has the full `docker run` command and the Compose file.

The image ships OpenVPN 2.6 from Alpine. Any file the config refers to by path, such as a separate CA certificate or key, has to be mounted at that path too. Provider files that put the certificates inline in the `.ovpn` need nothing extra.

## What happens at start

1. `run.sh` creates `/dev/net/tun` if it does not exist.
2. It stops the container if `/vpn-config.ovpn` is not a file: `OpenVPN configuration file not found: /vpn-config.ovpn`.
3. It runs `openvpn --config /vpn-config.ovpn`, adding `--auth-user-pass /vpn-auth.txt` when that file exists.
4. It waits 10 seconds.
5. It starts Transmission.

The 10 second wait is fixed. The script does not check that the tunnel is up before step 5. If OpenVPN needs longer to connect, Transmission starts on your normal connection and switches to the tunnel only once OpenVPN changes the routes. If OpenVPN fails outright, the container stops within about a second after that, because the process monitor sees OpenVPN gone, but Transmission has already started by then.

## Check the tunnel

Compare the address the container uses on the internet with your own:

```bash
docker exec safe-transmission wget -qO- https://api.ipify.org
echo
curl -s https://api.ipify.org
echo
```

The first line should show your VPN provider's address, the second your own. If they match, traffic is not going through the tunnel: look in `docker logs safe-transmission` for OpenVPN's `Initialization Sequence Completed` line and for errors around it.

## Limits

- There is no kill switch. The container sets no firewall rules, so if the tunnel goes down while OpenVPN keeps running and reconnecting, traffic follows whatever routes are left. Whether that leaks depends on your `.ovpn` file (for example `persist-tun` keeps the tunnel device and its routes in place during a reconnect).
- If the OpenVPN process exits, the container stops all processes and exits with status 1. Use a restart policy such as `restart: always` or `--restart unless-stopped` to bring it back.
- DNS stays on the resolver Docker gives the container. `run.sh` passes no `--up` script, so DNS servers your provider pushes are ignored. The Alpine package ships `/etc/openvpn/up.sh`, which writes pushed DNS servers into `/etc/resolv.conf`; to use it, add `script-security 2` and `up /etc/openvpn/up.sh` to your `.ovpn` file.
- Incoming peer connections need a port forwarded by your VPN provider. The image does not set one up.

See [Security](security.md) for what this means before you rely on it.
