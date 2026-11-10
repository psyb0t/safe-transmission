---
title: "Home"
description: "safe-transmission runs the Transmission BitTorrent daemon behind nginx in one Docker image, with optional basic auth, rate limiting and an OpenVPN client."
nav_order: 1
permalink: /
seo:
  type: WebSite
---

# safe-transmission

A Docker image that runs the [Transmission](https://transmissionbt.com/) BitTorrent daemon with its web interface behind nginx. nginx adds a per-client rate limit and, when you set a user name and password, HTTP basic authentication. An optional OpenVPN client starts before Transmission, so torrent traffic can leave through your VPN provider instead of your own connection.

The image is `psyb0t/safe-transmission` on [Docker Hub](https://hub.docker.com/r/psyb0t/safe-transmission), built for `linux/amd64` and `linux/arm64`, so it also runs on a 64-bit Raspberry Pi.

## What's inside

| Part | Does |
| --- | --- |
| Transmission 4.0 | The BitTorrent daemon and its web interface, run as the user and group you pick with `PUID` and `PGID`. |
| nginx | The only exposed port (80). Proxies to Transmission, limits each client to 1 request per second with a burst of 5, and asks for a password when `USERNAME` and `PASSWORD` are set. |
| OpenVPN 2.6 | Started from your `.ovpn` file when `WITH_OPENVPN=true`. Off by default. |
| `run.sh` | The entrypoint. Starts everything in order, watches the processes, and stops the container when one of them dies. |

Everything comes from the Alpine 3.22 package repositories. See the [`Dockerfile`](https://github.com/psyb0t/safe-transmission/blob/master/Dockerfile).

## Quick start

Without a VPN, with a password on the web interface:

```bash
docker run -d \
  --name safe-transmission \
  -e USERNAME=your_username \
  -e PASSWORD=your_password \
  -v "$PWD/config:/config" \
  -v "$PWD/downloads:/downloads" \
  -v "$PWD/watch:/watch" \
  -p 8080:80 \
  psyb0t/safe-transmission:latest
```

Open `http://localhost:8080/`, log in, and add a torrent. [Getting started](getting-started.md) has the VPN version and the Compose file.

## You want to

| You want to | Read |
| --- | --- |
| Run it for the first time, with or without a VPN | [Getting started](getting-started.md) |
| Look up a variable, volume or port | [Configuration](configuration.md) |
| Route torrent traffic through OpenVPN and check that it works | [OpenVPN](openvpn.md) |
| Know what is protected and what is not before exposing it | [Security](security.md) |
| Understand the startup order and shutdown | [How it works](how-it-works.md) |
| Fix a container that exits, a 503, or a wrong clock | [Troubleshooting](troubleshooting.md) |
| Change the image, run the tests, build these docs | [Development](development.md) |
