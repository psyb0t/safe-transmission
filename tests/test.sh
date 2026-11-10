#!/usr/bin/env bash
# Smoke tests for the built image. Each case starts a container without a
# VPN, probes nginx from inside it with busybox wget, and checks what a user
# would see. Needs only Docker on the host.
set -euo pipefail

readonly IMAGE="${IMAGE:-psyb0t/safe-transmission:dev}"
readonly NAME_PREFIX="safe-transmission-test-$$"
readonly READY_TIMEOUT_SECONDS=60
readonly EXIT_TIMEOUT_SECONDS=30
readonly AUTH_USER="tester"
readonly AUTH_PASSWORD="not-a-real-password"
readonly CUSTOM_ID=1234
readonly BURST_REQUESTS=15

failures=0
containers=()

cleanup() {
    local name
    for name in "${containers[@]}"; do
        docker rm -f "$name" >/dev/null 2>&1 || true # already gone is fine
    done
}
trap cleanup EXIT

log() {
    printf '%s\n' "$*" >&2
}

pass() {
    log "PASS: $1"
}

fail() {
    log "FAIL: $1"
    failures=$((failures + 1))
}

# start_container NAME [docker run args...] starts a detached container.
start_container() {
    local name="$1"
    shift
    containers+=("$name")
    docker run -d --name "$name" "$@" "$IMAGE" >/dev/null
}

# http_status NAME URL prints the last HTTP status nginx returned for URL,
# or 000 when there was no answer.
http_status() {
    local name="$1" url="$2" status
    status="$(docker exec "$name" sh -c "wget -S -O /dev/null '$url' 2>&1" |
        awk '/^  HTTP\// { code = $2 } END { print code }')" || true
    printf '%s\n' "${status:-000}"
}

# wait_ready NAME URL waits until URL answers with anything but 000 or 502.
wait_ready() {
    local name="$1" url="$2" deadline status
    deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
    while ((SECONDS < deadline)); do
        status="$(http_status "$name" "$url")"
        if [[ "$status" != "000" && "$status" != "502" ]]; then
            return 0
        fi
        sleep 1
    done
    log "container $name not ready after ${READY_TIMEOUT_SECONDS}s, logs:"
    docker logs "$name" >&2 || true
    return 1
}

expect_status() {
    local desc="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        pass "$desc ($got)"
    else
        fail "$desc: want $want, got $got"
    fi
}

test_no_auth() {
    local name="${NAME_PREFIX}-open"
    start_container "$name"
    wait_ready "$name" "http://127.0.0.1/transmission/web/" || {
        fail "open container never became ready"
        return
    }
    expect_status "web interface without auth" 200 \
        "$(http_status "$name" "http://127.0.0.1/transmission/web/")"
    # 409 is Transmission asking for its session id: the request reached
    # the RPC endpoint through nginx.
    expect_status "RPC reaches Transmission" 409 \
        "$(http_status "$name" "http://127.0.0.1/transmission/rpc")"
    expect_status "root redirects to the web interface" 301 \
        "$(wget_no_follow "$name" "http://127.0.0.1/")"
}

# wget_no_follow NAME URL prints the first status of a redirect chain.
wget_no_follow() {
    local name="$1" url="$2"
    docker exec "$name" sh -c "wget -S -O /dev/null '$url' 2>&1" |
        awk '/^  HTTP\// { print $2; exit }' || true
}

test_auth() {
    local name="${NAME_PREFIX}-auth"
    local url="127.0.0.1/transmission/web/"
    start_container "$name" -e USERNAME="$AUTH_USER" -e PASSWORD="$AUTH_PASSWORD"
    wait_ready "$name" "http://$url" || {
        fail "auth container never became ready"
        return
    }
    expect_status "no credentials" 401 "$(http_status "$name" "http://$url")"
    expect_status "wrong password" 401 \
        "$(http_status "$name" "http://$AUTH_USER:wrong@$url")"
    expect_status "right credentials" 200 \
        "$(http_status "$name" "http://$AUTH_USER:$AUTH_PASSWORD@$url")"

    # nginx allows 1 request per second per client with a burst of 5, so a
    # quick volley must get some 503 answers.
    local statuses
    statuses="$(docker exec "$name" sh -c "
        i=0
        while [ \$i -lt $BURST_REQUESTS ]; do
            wget -S -O /dev/null 'http://$AUTH_USER:$AUTH_PASSWORD@$url' 2>&1 | grep '^  HTTP/' &
            i=\$((i + 1))
        done
        wait
    ")" || true
    if grep -q ' 503 ' <<<"$statuses"; then
        pass "rate limit answers 503 past the burst"
    else
        fail "rate limit: no 503 in $BURST_REQUESTS parallel requests"
    fi
}

test_puid_pgid() {
    local name="${NAME_PREFIX}-ids"
    start_container "$name" -e PUID="$CUSTOM_ID" -e PGID="$CUSTOM_ID"
    wait_ready "$name" "http://127.0.0.1/transmission/web/" || {
        fail "PUID/PGID container never became ready"
        return
    }
    local owner dir
    for dir in /config /downloads /watch; do
        owner="$(docker exec "$name" stat -c '%u:%g' "$dir")"
        expect_status "owner of $dir" "$CUSTOM_ID:$CUSTOM_ID" "$owner"
    done
    local daemon_uid
    daemon_uid="$(docker exec "$name" sh -c \
        'stat -c %u "/proc/$(pidof transmission-daemon)"')"
    expect_status "transmission-daemon user" "$CUSTOM_ID" "$daemon_uid"
}

test_missing_vpn_config() {
    local name="${NAME_PREFIX}-vpn"
    start_container "$name" -e WITH_OPENVPN=true
    local code
    if ! code="$(timeout "$EXIT_TIMEOUT_SECONDS" docker wait "$name")"; then
        fail "WITH_OPENVPN=true without a config did not exit"
        return
    fi
    expect_status "exit code without a VPN config" 1 "$code"
    if docker logs "$name" 2>&1 | grep -q 'OpenVPN configuration file not found: /vpn-config.ovpn'; then
        pass "missing VPN config is reported"
    else
        fail "missing VPN config message not in the logs"
    fi
}

test_no_auth
test_auth
test_puid_pgid
test_missing_vpn_config

if ((failures > 0)); then
    log "$failures check(s) failed"
    exit 1
fi
log "all checks passed"
