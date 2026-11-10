# Security

This image fronts a BitTorrent client that can write to the host's download directory, so these hold for every change.

- nginx on port 80 is the only port the `Dockerfile` exposes. Transmission's RPC listens on `0.0.0.0:9091` inside the container but keeps its default address whitelist (`127.0.0.1,::1`), so only nginx in the same container can use it. Do not publish 9091, widen the whitelist, or turn the whitelist off.
- nginx sends `Host: 127.0.0.1` to Transmission (`nginx/default.conf`). That header is what gets past Transmission's host-name check: with the browser's own host name, the RPC endpoint answers 421 and the web interface cannot load any torrents.
- Basic authentication is on only when both `USERNAME` and `PASSWORD` are non-empty (`run.sh`). With either unset, the web interface is open to anyone who reaches the published port. The docs say so plainly; keep it that way.
- The rate limit, `limit_req_zone ... rate=1r/s` in `nginx/nginx.conf` and `limit_req zone=one burst=5` in `nginx/default.conf`, covers every request including the web interface's own polling. Requests past the burst get 503. Do not remove it to make the interface feel faster without saying so in the CHANGELOG and `docs/security.md`.
- There is no VPN kill switch and no firewall rule: Transmission starts after `sleep 10` whether or not the tunnel is up. Never call the image leak-proof. A change that adds a kill switch updates `docs/security.md` and `docs/how-it-works.md`.
- `server_tokens off` stays in `nginx/nginx.conf`.
- The `.ovpn` file, the VPN auth file, `USERNAME` and `PASSWORD` are user secrets. Examples use obvious placeholders (`your_username`, `/path/to/auth.txt`). `config/` and `openvpn/` in a checkout are gitignored and hold real data: never read, print or commit them.
