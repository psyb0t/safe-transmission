# safe-transmission

[![CI](https://github.com/psyb0t/safe-transmission/actions/workflows/pipeline.yml/badge.svg?branch=master)](https://github.com/psyb0t/safe-transmission/actions/workflows/pipeline.yml)
[![version](https://raw.githubusercontent.com/psyb0t/safe-transmission/badges/version.svg)](https://github.com/psyb0t/safe-transmission/releases)
[![license](https://raw.githubusercontent.com/psyb0t/safe-transmission/badges/license.svg)](https://github.com/psyb0t/safe-transmission/blob/master/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/psyb0t/safe-transmission?style=flat-square)](https://hub.docker.com/r/psyb0t/safe-transmission)

Welcome to **safe-transmission**, torrenting for the gritty streets of the cyberpunk future. This Docker image mashes together Transmission, nginx and OpenVPN in one container. nginx stands in front of the Transmission web interface with optional, rate-limited HTTP basic authentication to fend off those pesky netrunners, and the optional OpenVPN client sends your torrent traffic out through your VPN provider instead of your own line.

## Features

- **Transmission**: the sleek, shadowy BitTorrent daemon and its web interface, running as the user and group you choose.
- **nginx**: the only open port. One request per second per client with a burst of 5, plus basic auth when you set a user name and password.
- **OpenVPN**: tunnels your torrent traffic when you hand it your provider's `.ovpn` file. No kill switch, so check the tunnel; the docs show how.
- **Alpine Linux**: small and lean, like a well-oiled cyberarm. Built for `linux/amd64` and `linux/arm64` (yes, it runs on a Raspberry Pi).

## Quick start

Jack in with your VPN config, a login for the web interface, and three directories for state:

```bash
docker run -d \
  --name safe-transmission \
  --cap-add=NET_ADMIN \
  -e WITH_OPENVPN=true \
  -e USERNAME=your_username \
  -e PASSWORD=your_password \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/config.ovpn:/vpn-config.ovpn \
  -v /path/to/auth.txt:/vpn-auth.txt \
  -v /path/to/config:/config \
  -v /path/to/downloads:/downloads \
  -v /path/to/watch:/watch \
  -p 8080:80 \
  psyb0t/safe-transmission:latest
```

Replace the `/path/to/...` parts with your own files and directories, and `your_username` and `your_password` with real credentials. Keep those secrets close. Then open `http://localhost:8080/`.

No VPN? Drop `--cap-add`, `WITH_OPENVPN` and the two VPN mounts. There is also a [`docker-compose.yml`](https://github.com/psyb0t/safe-transmission/blob/master/docker-compose.yml) for `docker compose up -d`.

## Documentation

The full manual lives at **https://psyb0t.github.io/safe-transmission/**.

| Section | What's there |
| --- | --- |
| [Getting started](https://psyb0t.github.io/safe-transmission/getting-started/) | First run with and without a VPN, Compose, logs, upgrades |
| [Configuration](https://psyb0t.github.io/safe-transmission/configuration/) | Every variable, volume, port and capability, and Transmission's own settings |
| [OpenVPN](https://psyb0t.github.io/safe-transmission/openvpn/) | What the tunnel needs, the start delay, how to check it, its limits |
| [Security](https://psyb0t.github.io/safe-transmission/security/) | What basic auth, the rate limit and the VPN protect, and what they don't |
| [How it works](https://psyb0t.github.io/safe-transmission/how-it-works/) | Startup order, request path, the process monitor, shutdown |
| [Troubleshooting](https://psyb0t.github.io/safe-transmission/troubleshooting/) | Each error message and HTTP status, what causes it, how to fix it |
| [Development](https://psyb0t.github.io/safe-transmission/development/) | Layout, Make targets, tests, CI and releases |

## Hack the planet

With **safe-transmission**, you're ready to take on the dystopian digital future. Torrent behind a password, send the swarm traffic through your VPN, and stay one step ahead of the corpos and their surveillance.

Remember, the internet is vast and infinite. Happy torrenting, console cowboy!

## Sponsor

<a href="https://www.buymeacoffee.com/psyb0t"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me a Coffee" height="60" width="217"></a>

## License

This project is licensed under the [WTFPL](http://www.wtfpl.net/about/). Do what the fuck you want.

---

Don't forget to star this repo if you dig it. Welcome to the future, choom.
