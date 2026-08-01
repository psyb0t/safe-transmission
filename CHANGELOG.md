# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.6 — 2026-08-01

CI infrastructure only. No image, runtime, or configuration changes.

- Split the pipeline so building and publishing stay in `pipeline.yml`, while
  everything that leaves the host lives beside it in `mirror-and-archive.yml`.
- Mirror every branch and tag push to Codeberg as well as GitLab.
- Archive the repo to the Wayback Machine, Software Heritage and archive.org,
  on the default branch, on tags, and on a monthly schedule.
- Pull issues opened on either mirror back into GitHub every six hours, and
  close them here when the original closes.
- Pull requests are switched off on the mirrors: they are force-pushed from
  GitHub, so anything merged there is destroyed by the next sync. Issues and
  forking stay enabled.

## v0.1.5 — 2026-07-27

- Added a GitHub Actions CI status badge to the README.

## v0.1.4 — 2026-07-27

- Added self-hosted version and license badges plus a Docker Hub pulls badge; wired a badges job into pipeline.yml.

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
