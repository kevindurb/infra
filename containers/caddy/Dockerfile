FROM caddy:2.4.6-builder AS builder

RUN caddy-builder \
    github.com/caddy-dns/cloudflare

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
