---
title: "Security"
description: "What safe-transmission protects and what it does not: nginx basic auth, the rate limit, Transmission's RPC whitelist, VPN leaks, and secrets in the environment."
nav_order: 5
---

# Security

safe-transmission puts a password and a rate limit in front of Transmission and can push its traffic through a VPN. This page says what each of those does, and where each one stops, so you can decide what else you need before exposing the web interface.

## What is reachable

Only nginx's port 80 is exposed by the image. Inside the container, Transmission's RPC listens on port 9091 on every interface, but Transmission accepts connections there only from `127.0.0.1` and `::1`, its default whitelist. Another container or host that reaches port 9091 directly gets refused. Everything goes through nginx.

Transmission's own RPC authentication is off. nginx is the only lock. Publishing port 9091 or turning off `rpc-whitelist-enabled` in `settings.json` bypasses it.

## Basic authentication

With `USERNAME` and `PASSWORD` both set, nginx asks for them on every request (see [`nginx/default.conf`](https://github.com/psyb0t/safe-transmission/blob/master/nginx/default.conf)). Without them, there is no authentication at all.

- Basic auth sends the password with every request, encoded but not encrypted. nginx here serves plain HTTP on port 80. Over anything but your own machine or LAN, put a TLS reverse proxy in front of it or reach it through a VPN or SSH tunnel.
- The password is a container environment variable. `docker inspect`, `docker compose config` and anyone with access to the Docker socket can read it.
- There is one account, and it has full control: add and remove torrents, delete data, change settings.

## Rate limit

nginx allows each client address 1 request per second, with a burst of 5 queued requests (`limit_req_zone` in [`nginx/nginx.conf`](https://github.com/psyb0t/safe-transmission/blob/master/nginx/nginx.conf), `limit_req` in `nginx/default.conf`). Requests past the burst get `503 Service Temporarily Unavailable`.

That caps password guessing at about one try per second per address. It does not lock anyone out, and it counts all requests, including the web interface's own. The address is the one nginx sees, so behind another reverse proxy every user shares the proxy's address and its budget.

## The VPN

OpenVPN encrypts traffic between the container and your VPN provider and changes the address peers see. It does not:

- Block traffic when the tunnel is down. There is no kill switch and no firewall rule.
- Hold Transmission back until the tunnel is up. Transmission starts after a fixed 10 second wait.
- Change DNS, unless your `.ovpn` file sets that up.

If OpenVPN exits, the whole container stops. If it keeps running while reconnecting, Transmission keeps running too. [OpenVPN](openvpn.md) explains how to check the tunnel and what each limit means in practice.

## Files and permissions

- The `.ovpn` file and the auth file hold your VPN credentials. Keep them `600` on the host and out of version control.
- Transmission runs as `PUID:PGID`, not as root. The entrypoint, nginx's master process and OpenVPN run as root inside the container. nginx's workers run as the `nginx` user.
- On every start the container runs `chown -R` and `chmod -R 755` over `/config`, `/downloads` and `/watch`. Anything mounted there becomes readable by every user on the host who can reach the directory. Do not mount a directory whose permissions you want to keep.
- nginx hides its version (`server_tokens off`).

## Before exposing it

1. Set `USERNAME` and a long random `PASSWORD`.
2. Serve it over HTTPS through a reverse proxy, or keep it on a private network.
3. With a VPN, [check the tunnel](openvpn.md#check-the-tunnel) after every start, or add your own firewall rules on the host if a leak is not acceptable.
4. Mount only the directories Transmission needs.
