# Use the latest Alpine as the base image
FROM alpine:latest

# Install OpenVPN, Transmission, Nginx, and necessary dependencies
RUN apk update && \
    apk add --no-cache \
    openvpn \
    transmission-daemon \
    bash \
    nginx \
    apache2-utils \
    su-exec && \
    rm -rf /var/cache/apk/*

# Set environment variables for Transmission
ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC

# Create directories for Transmission and Nginx
RUN mkdir -p /config /downloads /watch /run/nginx /etc/nginx/conf.d

# Expose ports for Nginx
EXPOSE 80

# Add Nginx configuration files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/sites/default.conf

# Add a script to run OpenVPN, Transmission, and Nginx
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/run.sh"]
