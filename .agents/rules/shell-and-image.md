# Shell and image

Applies to `run.sh`, `tests/test.sh`, `Dockerfile` and `nginx/*.conf`.

- `make lint` runs shellcheck and `shfmt -d -i 4 -ci` over every script in `SHELL_SCRIPTS` in the `Makefile`. A new script goes into that list.
- `make lint` also runs hadolint on the `Dockerfile`. The one ignore, `DL3018` (unpinned `apk add`), carries its reason above the `RUN` line.
- Every long-running process `run.sh` starts goes in the background with its PID kept in a variable, gets a `kill -0` check right after start, a `check_process` line in the monitor loop, and a SIGTERM and `wait` in `cleanup`. A process the supervisor does not know about keeps running after the others stop.
- Paths the entrypoint uses are named once in the variable block at the top of `run.sh` (`AUTH_CONF_FILE`, `VPN_CONFIG_FILE` and the rest). Reuse them; do not repeat literal paths in the body.
- A new environment variable gets a default in the `Dockerfile` `ENV` block when it has one, a `${NAME-}` read in `run.sh` (the script runs under `set -u`), and a row in `docs/configuration.md` in the same change.
- The `Dockerfile` copies named files only. Never `COPY .` or a wildcard: the build context can hold `openvpn/` and `config/` with real credentials.
- nginx config lives in `nginx/`. `nginx/nginx.conf` replaces the package's main config and includes only `/etc/nginx/sites/*.conf`, so a new server block goes in `nginx/` and gets its own `COPY` to `/etc/nginx/sites/`.
