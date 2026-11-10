# safe-transmission

Instructions for coding agents (Codex, Claude Code and others) and for people changing this repository. Users of the image want the documentation site, https://psyb0t.github.io/safe-transmission/, not this file.

## Agent setup

`CLAUDE.md` is a committed symlink to `AGENTS.md`, and `.claude` is a committed symlink to `.agents`, so Claude Code reads the same instructions, rules and skills as Codex. Claude's Edit and Write tools refuse to write through a symlink, so edit `AGENTS.md` and `.agents/rules/*.md` directly.

## What it is

One Docker image, `psyb0t/safe-transmission`, published to Docker Hub for `linux/amd64` and `linux/arm64`. It runs the Transmission BitTorrent daemon behind an nginx reverse proxy, with optional HTTP basic authentication in nginx and an optional OpenVPN client started before Transmission. There is no application code: the image is Alpine packages, two nginx config files and one Bash entrypoint.

## Architecture

- `run.sh` is the entrypoint and the process supervisor. In order it: writes `/etc/nginx/conf.d/auth.conf` (empty, or `auth_basic` lines plus a fresh `/etc/nginx/.htpasswd` when both `USERNAME` and `PASSWORD` are set); starts nginx; when `WITH_OPENVPN` is exactly `true`, creates `/dev/net/tun` if missing, refuses to go on without `/vpn-config.ovpn`, starts `openvpn --config /vpn-config.ovpn` (plus `--auth-user-pass /vpn-auth.txt` when that file exists) and sleeps 10 seconds; runs `chown -R PUID:PGID` and `chmod -R 755` on `/config`, `/downloads` and `/watch`; starts `transmission-daemon` in the foreground through `su-exec PUID:PGID` with `/downloads/_incomplete` as the incomplete directory and `/watch` as the watch directory.
- A background loop checks every second that nginx, Transmission and OpenVPN (when started) are alive. When one dies, or the container gets SIGINT or SIGTERM, `cleanup` sends SIGTERM to all of them and exits 1.
- `nginx/nginx.conf` defines the `one` rate-limit zone (1 request per second per client address), turns off `server_tokens` and includes `/etc/nginx/sites/*.conf`. `nginx/default.conf` listens on port 80, proxies everything to Transmission at `localhost:9091` with `Host: 127.0.0.1` (Transmission's RPC answers 421 to any other host name), applies `limit_req zone=one burst=5` and includes `auth.conf`.
- Transmission keeps its own defaults: RPC on `0.0.0.0:9091` inside the container with the address whitelist `127.0.0.1,::1`, no RPC authentication, peers on 51413. The container writes no `settings.json` keys; Transmission creates the file in `/config` on first start.

Request path: browser -> host port (8080 in the examples) -> nginx on 80 (rate limit, optional basic auth) -> Transmission RPC and web interface on `localhost:9091`.

## Stack

- Base image: `alpine:3.22` (`Dockerfile`), with `openvpn`, `transmission-daemon`, `nginx`, `apache2-utils` (for `htpasswd`), `su-exec` and `bash` from the Alpine repositories. Package versions are not pinned; the Alpine tag fixes them.
- Shell: Bash with `set -euo pipefail`, linted by shellcheck and formatted by shfmt (`-i 4 -ci`).
- CI: `.github/workflows/pipeline.yml` calling `psyb0t/reusable-github-workflows`.
- Docs: GitHub Pages from `docs/` on `master`, Jekyll with the Just the Docs theme.

## Layout

| Path | What it holds |
| --- | --- |
| `Dockerfile` | The image: packages, directories, nginx configs, `run.sh` as `ENTRYPOINT`, `EXPOSE 80` |
| `run.sh` | Entrypoint: auth setup, process start order, ownership fix, supervision, shutdown |
| `nginx/nginx.conf` | Main nginx config, copied to `/etc/nginx/nginx.conf` |
| `nginx/default.conf` | The proxy server block, copied to `/etc/nginx/sites/default.conf` |
| `docker-compose.yml` | Compose quick start; bind-mounts `./openvpn/`, `./config`, `./downloads`, `./watch` |
| `Makefile` | `build`, `lint`, `format`, `test`, `docs`, `clean` |
| `tests/test.sh` | Container smoke tests against the built image |
| `docs/` | The documentation site |
| `.github/workflows/` | `pipeline.yml` plus the mirror, issue-pull and collaborators-only workflows |
| `.agents/rules/` | Rules for changing this repository |
| `CHANGELOG.md` | Release notes, one section per tag |

`config/`, `openvpn/`, `downloads/` and `watch/` are the compose bind mounts. They are gitignored and hold real VPN credentials and Transmission state on a working checkout. Never read, print or commit them.

## Commands

Docker, Make and Bash are enough. Every tool runs from a pinned image.

```bash
make help     # every target
make build    # image as psyb0t/safe-transmission:dev
make lint     # shellcheck + shfmt on run.sh and tests/test.sh, hadolint on Dockerfile
make format   # rewrite the scripts with shfmt
make test     # build, then tests/test.sh (no VPN, no credentials needed)
make docs     # build the site into .testing/docs-site
make clean    # remove the dev image and .testing/
```

CI runs `make lint` and `make test` on every push.

## Project-specific landmines

- There is no VPN kill switch. Transmission starts after a fixed `sleep 10`, whether or not the tunnel is up, and nothing blocks traffic outside the tunnel. Do not describe the image as leak-proof anywhere.
- `TZ` is set in the `Dockerfile`, but the image has no `tzdata`, so a zone name such as `Europe/Berlin` falls back to UTC.
- `chown -R` and `chmod -R 755` run over all of `/config`, `/downloads` and `/watch` on every start. A change there touches every file a user has downloaded.
- `docker stop` makes the container exit with status 1, because `cleanup` always exits 1.
- `/etc/nginx/http.d/default.conf` from the Alpine package is unused: `nginx.conf` includes only `/etc/nginx/sites/*.conf`.
- The `.dockerignore` does not exclude `config/` or `openvpn/`. The `Dockerfile` copies only named files, so they stay out of the image. Never add `COPY .` or a wildcard copy.

## Rules

Rules for every change live in `.agents/rules/`, one file per topic. Read the ones that match what you are touching before editing.
