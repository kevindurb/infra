FROM traefik:2.4 as base

LABEL org.opencontainers.image.source='https://github.com/kevindurb/infra'

FROM base as development

FROM base as production

COPY ./traefik.yaml /etc/traefik/traefik.yaml
COPY ./config /etc/traefik/config
