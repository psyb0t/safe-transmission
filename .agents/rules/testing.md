# Testing

- `make test` builds `psyb0t/safe-transmission:dev` and runs `tests/test.sh` against it. CI runs the same target, so it needs only Docker: no VPN, no credentials, no host tools beyond Bash and `timeout`.
- Each case starts its own container with a name from `NAME_PREFIX` and registers it in `containers`, so the `EXIT` trap removes it. Probe from inside the container with busybox `wget` through `docker exec`; the host has no guaranteed `curl`.
- Wait with `wait_ready` instead of a fixed sleep. Time limits are `readonly` constants at the top of the script.
- A behavior change in `run.sh` or `nginx/` adds or updates a case: an HTTP status, a file owner, an exit code, or a log line copied exactly from `run.sh`.
- Make sure a new case can fail. Break the behavior on purpose once (a throwaway image `FROM psyb0t/safe-transmission:dev` with a `sed` over the file is enough) and watch the case report `FAIL`.
- Anything that needs a real VPN server stays out of CI. Test it by hand and say so in the CHANGELOG.
