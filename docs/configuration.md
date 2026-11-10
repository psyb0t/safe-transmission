---
title: "Configuration"
description: "Every safe-transmission environment variable, volume, port and capability, with defaults, plus where Transmission keeps its own settings.json."
nav_order: 3
---

# Configuration

safe-transmission is configured with environment variables and mounted files. Every variable is read once at container start by [`run.sh`](https://github.com/psyb0t/safe-transmission/blob/master/run.sh), so a change needs the container recreated.

## Environment variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `USERNAME` | empty | User name for HTTP basic authentication in nginx. |
| `PASSWORD` | empty | Password for HTTP basic authentication. Authentication is on only when both `USERNAME` and `PASSWORD` are non-empty. |
| `WITH_OPENVPN` | empty (off) | `true` starts OpenVPN before Transmission. Any other value, including `True` or `1`, leaves it off. |
| `PUID` | `1000` | User ID Transmission runs as, and the owner given to `/config`, `/downloads` and `/watch`. |
| `PGID` | `1000` | Group ID Transmission runs as, and the group given to those directories. |
| `TZ` | `Etc/UTC` | Time zone variable. The image has no time zone database, so zone names such as `Europe/Berlin` have no effect and the clock stays on UTC. See [Troubleshooting](troubleshooting.md#log-times-are-in-utc). |

`PUID`, `PGID` and `TZ` have their defaults in the [`Dockerfile`](https://github.com/psyb0t/safe-transmission/blob/master/Dockerfile). The other three are unset unless you pass them.

### Basic authentication

With both `USERNAME` and `PASSWORD` set, the container writes them to `/etc/nginx/.htpasswd` with `htpasswd` at every start, and nginx asks for them on every request. A wrong or missing login gets `401 Unauthorized`. With either one empty, the log says `No HTTP basic authentication will be used.` and the web interface is open.

There is one account. The values sit in the container's environment, so anyone who can run `docker inspect` on the host can read them.

### User and group

Before Transmission starts, `run.sh` runs `chown -R PUID:PGID` and `chmod -R 755` on `/config`, `/downloads` and `/watch`. This happens on every start and covers every file already in those directories. Two things follow from that:

- Files you put in `downloads` from the host end up owned by `PUID:PGID` with mode `755` after the next restart.
- On a large download library the log pauses after `Starting Transmission...` while the container walks every file, and Transmission's own log starts only after that.

Transmission then runs through `su-exec PUID:PGID`, and it creates new files with its default umask `022`.

## Volumes

| Path in the container | Type | Holds |
| --- | --- | --- |
| `/config` | directory | Transmission's configuration directory: `settings.json`, `resume/`, `torrents/`, `blocklists/`, `bandwidth-groups.json`. Created on first start. |
| `/downloads` | directory | Finished downloads. `/downloads/_incomplete` holds downloads in progress. |
| `/watch` | directory | Watch directory. Transmission adds any `.torrent` file that appears here. |
| `/vpn-config.ovpn` | file | Your OpenVPN client config. Required when `WITH_OPENVPN=true`. |
| `/vpn-auth.txt` | file | Optional OpenVPN login: user name on line 1, password on line 2. Passed as `--auth-user-pass` when the file exists. |

None of the three directories is declared as a Docker volume. Without a mount, the data lives in the container and goes away with it.

Mount the two VPN files as files. When the host path does not exist, Docker creates an empty directory in its place. For `/vpn-config.ovpn` the container then stops with `OpenVPN configuration file not found`; for `/vpn-auth.txt` OpenVPN starts without a login.

## Ports

| Port | Protocol | What listens |
| --- | --- | --- |
| `80` | TCP | nginx, in front of the Transmission web interface and RPC. The only port in `EXPOSE`. |

Inside the container Transmission also listens on `9091` for RPC and on `51413` (TCP and UDP) for peers. Port 9091 only accepts connections from inside the container (Transmission's whitelist is `127.0.0.1,::1`), so publish port 80, not 9091.

The image does not publish `51413`. Transmission still downloads without it, but other peers cannot open connections to you. Without a VPN you can publish it with `-p 51413:51413 -p 51413:51413/udp`. With a VPN, incoming connections depend on whether your provider forwards a port to you.

## Capabilities

`--cap-add=NET_ADMIN` is needed only with `WITH_OPENVPN=true`, so OpenVPN can open the tunnel device and set routes. When `/dev/net/tun` is missing, `run.sh` creates it with `mknod`, which Docker's default capabilities allow. Without `NET_ADMIN` OpenVPN exits with `Cannot ioctl TUNSETIFF tun: Operation not permitted`.

## Transmission settings

The container passes only these options to `transmission-daemon`: `--foreground`, `--config-dir /config`, `--download-dir /downloads`, `--incomplete-dir /downloads/_incomplete` and `--watch-dir /watch`. Everything else (speed limits, queue size, peer port, encryption, ratio limits) is Transmission's own, kept in `/config/settings.json`.

Change those from the web interface, or edit `settings.json` while the container is stopped. Transmission rewrites the file when it shuts down, so edits made while it runs are lost. The options above override the matching keys in `settings.json` on every start.

Do not change `rpc-port`, `rpc-url` or `rpc-whitelist`. nginx expects Transmission at `localhost:9091` under `/transmission/`, and the whitelist keeps port 9091 closed to everything but nginx. See [Security](security.md).

## nginx settings

nginx's configuration is baked into the image: [`nginx/nginx.conf`](https://github.com/psyb0t/safe-transmission/blob/master/nginx/nginx.conf) and [`nginx/default.conf`](https://github.com/psyb0t/safe-transmission/blob/master/nginx/default.conf). No variable changes the rate limit or the listen port. To change them, mount your own file over `/etc/nginx/sites/default.conf`, or build your own image.
