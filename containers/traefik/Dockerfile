FROM traefik:2.4 as base

RUN mkdir -p /etc/traefik/config
RUN mkdir -p /etc/traefik/acme

LABEL org.opencontainers.image.source='https://github.com/kevindurb/infra'

FROM base as development

FROM base as production

COPY ./traefik.yaml /etc/traefik/traefik.yaml
COPY ./services.yaml /etc/traefik/config/services.yaml
COPY ./routers.yaml /etc/traefik/config/routers.yaml

RUN touch /etc/traefik/acme/acme.json
RUN chmod 600 /etc/traefik/acme/acme.json
