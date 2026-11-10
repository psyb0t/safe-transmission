---
title: "How it works"
description: "The safe-transmission startup order, the request path through nginx to Transmission, the process monitor, and what happens on stop or when a process dies."
nav_order: 6
---

# How it works

The image is Alpine 3.22 with four packages doing the work (Transmission, nginx, OpenVPN and `htpasswd` from `apache2-utils`) and one Bash script, [`run.sh`](https://github.com/psyb0t/safe-transmission/blob/master/run.sh), as the entrypoint. There is no init system: `run.sh` starts the processes itself and stays as PID 1.

## Request path

```text
browser -> host port (8080 in the examples)
        -> nginx :80     rate limit, optional basic auth
        -> Transmission  localhost:9091, /transmission/web/ and /transmission/rpc
```

nginx proxies every path to Transmission and sets the `Host` header to `127.0.0.1`. Transmission's RPC rejects host names it does not know with `421 Misdirected Request`; the fixed header means you can reach the interface under any host name or address. A request for `/` gets Transmission's redirect to `/transmission/web/`.

## Startup order

1. Write `/etc/nginx/conf.d/auth.conf`. It stays empty without `USERNAME` and `PASSWORD`. With both, `htpasswd` writes `/etc/nginx/.htpasswd` and the file gets the `auth_basic` lines.
2. Start nginx (`nginx -g 'daemon off;'`) as a background job of the script.
3. With `WITH_OPENVPN=true`: create `/dev/net/tun` if needed, check for `/vpn-config.ovpn`, start OpenVPN, wait 10 seconds. See [OpenVPN](openvpn.md).
4. `chown -R PUID:PGID` and `chmod -R 755` on `/config`, `/downloads` and `/watch`.
5. Start `transmission-daemon --foreground` as `PUID:PGID` through `su-exec`, with `/config` as the config directory, `/downloads` as the download directory, `/downloads/_incomplete` for unfinished downloads and `/watch` as the watch directory.

nginx starts before Transmission. Until Transmission listens, which takes 10 seconds longer with a VPN, nginx answers `502 Bad Gateway`.

## Process monitor

A background loop checks every second that nginx, Transmission and, when started, OpenVPN are still running. When one is gone, it prints `<name> has terminated unexpectedly.`, sends SIGTERM to the others, and the container exits with status 1. Nothing restarts a single process. Use a Docker restart policy to bring the container back.

## Stopping

`docker stop` sends SIGTERM to `run.sh`. It prints `Caught signal or error, stopping OpenVPN, Transmission, and Nginx...`, sends SIGTERM to each process, waits for it, prints `All processes have been stopped. Exiting.` and exits with status 1. Transmission saves its state and `settings.json` as it shuts down. The exit status is 1 on a normal stop too, so a non-zero status alone does not mean something broke.

## Files the container writes

| Path | Written by | When |
| --- | --- | --- |
| `/etc/nginx/conf.d/auth.conf` | `run.sh` | Every start |
| `/etc/nginx/.htpasswd` | `htpasswd` | Every start with basic auth |
| `/config/*` | Transmission | First start, and whenever settings or torrents change |
| `/downloads/*`, `/downloads/_incomplete/*` | Transmission | While downloading |
| `/dev/net/tun` | `run.sh` | Start with OpenVPN, if missing |

Only the mounted directories survive a container recreate.
