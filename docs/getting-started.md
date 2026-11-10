---
title: "Getting started"
description: "Run safe-transmission with docker run or Docker Compose, with or without OpenVPN, and open the Transmission web interface behind nginx basic auth."
nav_order: 2
---

# Getting started

This page takes you from nothing to a running Transmission web interface. You need Docker on a `linux/amd64` or `linux/arm64` machine. For the VPN route you also need an OpenVPN config file (`.ovpn`) from your VPN provider, and usually a file with your VPN user name and password.

## 1. Make the directories

The container stores its state in three directories you mount from the host:

```bash
mkdir -p config downloads watch
```

- `config` holds Transmission's `settings.json`, resume data and torrent files.
- `downloads` is where finished downloads land. Unfinished ones sit in `downloads/_incomplete`.
- `watch` is a drop box: a `.torrent` file copied into it gets added automatically.

On every start the container gives all three, and everything inside them, to the user and group in `PUID` and `PGID` (default `1000`). Pick the IDs of the host user that should own the downloads. See [Configuration](configuration.md#user-and-group) for what that does to existing files.

## 2. Start it without a VPN

```bash
docker run -d \
  --name safe-transmission \
  -e USERNAME=your_username \
  -e PASSWORD=your_password \
  -e PUID=1000 \
  -e PGID=1000 \
  -v "$PWD/config:/config" \
  -v "$PWD/downloads:/downloads" \
  -v "$PWD/watch:/watch" \
  -p 8080:80 \
  psyb0t/safe-transmission:latest
```

Open `http://localhost:8080/`. nginx asks for the user name and password, then redirects to Transmission's web interface at `/transmission/web/`.

Leave out `USERNAME` and `PASSWORD` and there is no password at all: anyone who can reach port 8080 controls your Transmission. Read [Security](security.md) before publishing the port beyond your own machine.

## 3. Or start it with OpenVPN

Put the provider's files next to the other directories:

```bash
mkdir -p openvpn
cp /path/to/provider.ovpn openvpn/config.ovpn
printf '%s\n' 'vpn_user' 'vpn_password' > openvpn/auth.txt
chmod 600 openvpn/auth.txt
```

The auth file is OpenVPN's `--auth-user-pass` format: the user name on the first line, the password on the second. Skip it if your `.ovpn` file does not ask for a login.

Then add `NET_ADMIN`, `WITH_OPENVPN=true` and the two files:

```bash
docker run -d \
  --name safe-transmission \
  --cap-add=NET_ADMIN \
  -e WITH_OPENVPN=true \
  -e USERNAME=your_username \
  -e PASSWORD=your_password \
  -e PUID=1000 \
  -e PGID=1000 \
  -v "$PWD/openvpn/config.ovpn:/vpn-config.ovpn" \
  -v "$PWD/openvpn/auth.txt:/vpn-auth.txt" \
  -v "$PWD/config:/config" \
  -v "$PWD/downloads:/downloads" \
  -v "$PWD/watch:/watch" \
  -p 8080:80 \
  psyb0t/safe-transmission:latest
```

The container starts OpenVPN, waits 10 seconds, then starts Transmission. Check that the tunnel came up before you trust it: [OpenVPN](openvpn.md#check-the-tunnel) shows how.

## 4. Or use Docker Compose

The repository ships a [`docker-compose.yml`](https://github.com/psyb0t/safe-transmission/blob/master/docker-compose.yml) for the VPN route. It expects the same layout as above: `./openvpn/config.ovpn`, `./openvpn/auth.txt`, `./config`, `./downloads` and `./watch` next to it.

```yaml
services:
  safe-transmission:
    image: psyb0t/safe-transmission:latest
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WITH_OPENVPN=true
      - USERNAME=your_username
      - PASSWORD=your_password
    ports:
      - "8080:80"
    volumes:
      - ./openvpn/config.ovpn:/vpn-config.ovpn
      - ./openvpn/auth.txt:/vpn-auth.txt
      - ./config:/config
      - ./downloads:/downloads
      - ./watch:/watch
    restart: always
```

Change `USERNAME` and `PASSWORD` first, then:

```bash
docker compose up -d
docker compose logs -f
```

The shipped file also has a `version: "3.8"` line at the top. Current Docker Compose ignores it and prints a warning.

## 5. Check the logs

```bash
docker logs safe-transmission
```

A healthy start without a VPN prints these lines from `run.sh`, followed by Transmission's own log:

```text
Setting up HTTP basic authentication...
Adding password for user your_username
Starting Nginx...
OpenVPN will not be started.
Starting Transmission...
```

With `WITH_OPENVPN=true` you see `Ensuring the TUN device is available...` and `Starting OpenVPN...` instead of the `OpenVPN will not be started.` line, then OpenVPN's log. If the container exits, [Troubleshooting](troubleshooting.md) lists the messages and what they mean.

## Upgrading

Pull the new image and recreate the container. Everything that matters is in the mounted directories:

```bash
docker pull psyb0t/safe-transmission:latest
docker rm -f safe-transmission
```

Then run the same `docker run` command again, or `docker compose pull && docker compose up -d`. Release notes are in the [CHANGELOG](https://github.com/psyb0t/safe-transmission/blob/master/CHANGELOG.md). Each release is also tagged on Docker Hub as `vX.Y.Z` if you want to pin one.
