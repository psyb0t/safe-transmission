# safe-transmission

Welcome to **safe-transmission**, the ultimate fusion of security and torrenting, designed for the gritty streets of the cyberpunk future. This Docker image mashes together OpenVPN, Transmission, and Nginx, creating a fortified fortress for your torrent traffic. With built-in HTTP basic authentication, you can fend off those pesky netrunners, and optional VPN routing ensures your tracks are covered.

## Features

- **Transmission**: The sleek, shadowy BitTorrent client that gets the job done.
- **OpenVPN**: Encrypt your torrent traffic, because Big Brother is always watching.
- **Nginx**: Proxy your Transmission web interface with a layer of security that laughs in the face of script kiddies.
- **Alpine Linux**: Small, efficient, and secure, just like a well-oiled cyberarm.

## Getting Started

### Prerequisites

- Docker installed on your rig.
- A VPN configuration file (`config.ovpn`) and optionally an authentication file (`auth.txt`).

### Quick Start

Dive into the matrix with `psyb0t/safe-transmission`:

1. **Jack into the image from Docker Hub:**

   ```bash
   docker pull psyb0t/safe-transmission:latest
   ```

2. **Fire up the container:**

   ```bash
   docker run --cap-add=NET_ADMIN --rm \
     -e USERNAME=your_username \
     -e PASSWORD=your_password \
     -e WITH_OPENVPN=true \
     -e ENV_PUID=1000 \
     -e ENV_PGID=1000 \
     -e ENV_TZ=Etc/UTC \
     -v /path/to/config.ovpn:/config/vpn-config.ovpn \
     -v /path/to/auth.txt:/config/vpn-auth.txt \
     -v /path/to/downloads:/downloads \
     -v /path/to/watch:/watch \
     -p 8080:80 \
     psyb0t/safe-transmission:latest
   ```

Replace `/path/to/config.ovpn`, `/path/to/auth.txt`, `/path/to/downloads`, and `/path/to/watch` with your actual directories. Change `your_username` and `your_password` to your credentials. Keep those secrets close.

### Configuration

**Environment Variables**:

- `PUID`: User ID. Default: `1000`.
- `PGID`: Group ID. Default: `1000`.
- `TZ`: Time zone. Default: `Etc/UTC`.
- `USERNAME`: Your chosen handle for HTTP basic authentication. Leaving this empty will disable authentication.
- `PASSWORD`: Your password. Make it strong, netrunner. Leaving this empty will disable authentication.
- `WITH_OPENVPN`: Set to `true` to route traffic through a VPN. Default: `false`.

### Volumes

- `/config`: Where the settings.json and VPN config live.
- `/downloads`: Your download stash.
- `/watch`: Auto-add torrents from this directory.

### Exposed Ports

- `80`: Nginx proxy for the Transmission web interface.

### Example docker-compose.yml

Want to deploy like a pro? Check this out:

```yaml
version: "3.8"

services:
  safe-transmission:
    image: psyb0t/safe-transmission:latest
    cap_add:
      - NET_ADMIN
    environment:
      - ENV_PUID=1000
      - ENV_PGID=1000
      - ENV_TZ=Etc/UTC
      - WITH_OPENVPN=true
      - USERNAME=your_username
      - PASSWORD=your_password
    ports:
      - "8080:80"
    volumes:
      - ./openvpn/config.ovpn:/config/vpn-config.ovpn
      - ./openvpn/auth.txt:/config/vpn-auth.txt
      - ./downloads:/downloads
      - ./watch:/watch
    restart: always
```

### Security Notes

- Keep your `.ovpn` and `.txt` files secure. Think of them as your digital katana and trench coat.
- Strong passwords, always. We're not in Kansas anymore.

## Hack the Planet!

With **safe-transmission**, you're ready to take on the dystopian digital future. Torrent safely, securely, and always stay one step ahead of the corpos and their surveillance.

Remember, the internet is vast and infinite. Happy torrenting, console cowboy!

---

## License

This project is licensed under the [WTFPL](http://www.wtfpl.net/about/). Do what the fuck you want.

---

Don't forget to star this repo if you dig it. Welcome to the future, choom.
