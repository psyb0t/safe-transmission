---
title: "Troubleshooting"
description: "safe-transmission failures by their exact log line or HTTP status: missing VPN config, TUNSETIFF errors, 401, 502 and 503 answers, and UTC log times."
nav_order: 7
---

# Troubleshooting

Start with the log. Every message below is printed by [`run.sh`](https://github.com/psyb0t/safe-transmission/blob/master/run.sh), OpenVPN or nginx.

```bash
docker logs safe-transmission
```

## OpenVPN configuration file not found: /vpn-config.ovpn

`WITH_OPENVPN=true` is set, but nothing is mounted at `/vpn-config.ovpn`, or the mount is a directory. Docker creates an empty directory when the host path in `-v host:/vpn-config.ovpn` does not exist. Check the host path, mount the `.ovpn` file itself, and recreate the container. If you did not mean to use a VPN, remove `WITH_OPENVPN`.

## Cannot ioctl TUNSETIFF tun: Operation not permitted

OpenVPN cannot open the tunnel device because the container lacks `NET_ADMIN`. Add `--cap-add=NET_ADMIN` to `docker run`, or `cap_add: [NET_ADMIN]` in Compose. The log then shows `OpenVPN has terminated unexpectedly.` and the container exits.

## OpenVPN has terminated unexpectedly.

OpenVPN started and then exited. The lines just above come from OpenVPN and say why: a wrong login (`AUTH_FAILED`), a missing certificate file the `.ovpn` refers to, or a server it cannot reach. If the config asks for a login, mount the auth file at `/vpn-auth.txt`, user name on the first line and password on the second.

## Nginx has terminated unexpectedly. / Transmission has terminated unexpectedly.

The named process exited, so the container stopped the others and exited with status 1. The process's own error is a few lines above it.

## The container exits with status 1 after docker stop

That is expected. `run.sh` exits with status 1 on every stop, including a normal `docker stop`. See [How it works](how-it-works.md#stopping).

## 401 Unauthorized in the browser

Basic authentication is on and the browser sent a wrong or no login. The values are the `USERNAME` and `PASSWORD` the container was started with. Changing them needs the container recreated, because `run.sh` writes the password file only at start.

## 502 Bad Gateway

nginx is up and Transmission is not answering yet. Right after start this is normal: Transmission starts after the ownership fix, and with a VPN after a further 10 seconds. If it lasts, check the log for a Transmission error, or for a slow start on a large `/downloads` (see [Configuration](configuration.md#user-and-group)).

## 503 Service Temporarily Unavailable

You hit the rate limit: more than 1 request per second from one address, past a burst of 5. Wait a few seconds and reload. Scripts that call the RPC through nginx need to slow down. See [Security](security.md#rate-limit).

## Log times are in UTC

The image has no time zone database, so `TZ` set to a zone name, such as `TZ=Europe/Berlin`, has no effect and every clock in the container stays on UTC. Log timestamps and the alternative speed schedule in Transmission's settings both run on UTC, so set schedule times in UTC.

## Traffic does not go through the VPN

Run the check in [OpenVPN](openvpn.md#check-the-tunnel). If the container shows your own address, look for `Initialization Sequence Completed` in the log. Without it, OpenVPN is still connecting or retrying, and Transmission is running on your normal connection.

## Files in downloads changed owner or mode

The container runs `chown -R PUID:PGID` and `chmod -R 755` on `/config`, `/downloads` and `/watch` at every start. Set `PUID` and `PGID` to the host user that should own the files. See [Configuration](configuration.md#user-and-group).
