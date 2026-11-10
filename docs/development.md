---
title: "Development"
description: "Change and test safe-transmission: repository layout, the Make targets for lint, smoke tests and docs, what CI runs on each push, and how releases ship."
nav_order: 8
---

# Development

You need Docker, Make and Bash. Every tool runs from a pinned container image, so nothing else gets installed on your machine.

## Layout

| Path | What it holds |
| --- | --- |
| [`Dockerfile`](https://github.com/psyb0t/safe-transmission/blob/master/Dockerfile) | The image: Alpine packages, directories, nginx configs, the entrypoint |
| [`run.sh`](https://github.com/psyb0t/safe-transmission/blob/master/run.sh) | The entrypoint and process supervisor |
| [`nginx/`](https://github.com/psyb0t/safe-transmission/tree/master/nginx) | `nginx.conf` (rate-limit zone, includes) and `default.conf` (the proxy server block) |
| [`docker-compose.yml`](https://github.com/psyb0t/safe-transmission/blob/master/docker-compose.yml) | The Compose quick start |
| [`Makefile`](https://github.com/psyb0t/safe-transmission/blob/master/Makefile) | Build, lint, test and docs targets |
| [`tests/test.sh`](https://github.com/psyb0t/safe-transmission/blob/master/tests/test.sh) | Container smoke tests |
| `docs/` | This site |
| [`.github/workflows/`](https://github.com/psyb0t/safe-transmission/tree/master/.github/workflows) | CI and repository housekeeping |

## Make targets

```bash
make help     # list the targets
make build    # build the image as psyb0t/safe-transmission:dev
make lint     # shellcheck and shfmt on the scripts, hadolint on the Dockerfile
make format   # rewrite the scripts with shfmt
make test     # build the image, then run tests/test.sh against it
make docs     # build this site with GitHub Pages' Jekyll image
make clean    # remove the dev image and the local build output
```

## Tests

`make test` starts containers from the dev image without a VPN and probes nginx from inside each one. It checks that:

- the web interface answers 200 without auth, the RPC endpoint answers Transmission's 409 through nginx, and `/` redirects;
- with `USERNAME` and `PASSWORD`, a missing or wrong login gets 401 and the right one gets 200;
- a quick volley of requests gets 503 answers from the rate limit;
- `PUID` and `PGID` set the owner of `/config`, `/downloads` and `/watch` and the user Transmission runs as;
- `WITH_OPENVPN=true` without a config file stops the container with status 1 and the `OpenVPN configuration file not found` message.

The tests need no credentials and no VPN server. VPN connections themselves are not tested in CI.

## CI

[`pipeline.yml`](https://github.com/psyb0t/safe-transmission/blob/master/.github/workflows/pipeline.yml) runs on every push:

- Every branch: `make lint` and `make test`.
- `master`, after those pass: builds the image for `linux/amd64` and `linux/arm64`, pushes `:latest` and `:sha-<commit>` to Docker Hub, scans it with Grype and updates the version and license badges.
- A `vX.Y.Z` tag: waits for the `master` run of the same commit to succeed, points `:vX.Y.Z` at that run's image without rebuilding, and creates the GitHub release.

The other workflows mirror the repository, pull issues back from the mirrors and close pull requests from outside contributors.

## Docs

The site is built from `docs/` by GitHub Pages with the Just the Docs theme. Every page needs front matter with a unique `title` and a `description` of 50 to 170 characters. Link to other pages with the relative `.md` path, and to files outside `docs/` with the full GitHub URL. Run `make docs` to build the site locally before pushing a docs change.
