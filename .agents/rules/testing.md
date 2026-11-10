# Testing

- `make test` builds `psyb0t/safe-transmission:dev` and runs `tests/test.sh` against it. CI runs the same target, so it needs only Docker: no VPN, no credentials, no host tools beyond Bash and `timeout`.
- Each case starts its own container with a name from `NAME_PREFIX` and registers it in `containers`, so the `EXIT` trap removes it. Probe from inside the container with busybox `wget` through `docker exec`; the host has no guaranteed `curl`.
- Wait with `wait_ready` instead of a fixed sleep. Time limits are `readonly` constants at the top of the script.
- A case asserts an HTTP status, a file owner, an exit code, or a log line copied exactly from `run.sh`.
- To see a new case fail, build a throwaway image `FROM psyb0t/safe-transmission:dev` with a `sed` over the file and watch the case report `FAIL`.
- Anything that needs a real VPN server stays out of CI. Test it by hand and say so in the CHANGELOG.
