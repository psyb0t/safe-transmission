# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.3 — 2026-07-27

Base image refresh.

- Upgrade base image `alpine:3.20` → `alpine:3.22`, which pulls a current,
  security-patched `transmission-daemon` (4.0.6) plus updated `openvpn`,
  `nginx`, and `su-exec` from the Alpine repos.
- No changes to `run.sh`: the daemon is still launched with
  `--foreground --config-dir --download-dir --incomplete-dir --watch-dir`,
  all of which are unchanged in this Transmission line. No `settings.json`
  keys are written by the container, so the Transmission 4.1 setting renames
  do not apply here. Image builds clean and the daemon boots (RPC on 9091,
  nginx front) verified.

## v0.1.2 — 2024-05-24

- Fix.

## v0.1.1 — 2024-05-24

- Cleanup after install.

## v0.1.0 — 2024-05-22

Initial release.
