FROM nodered/node-red:1.3.5 as base

LABEL org.opencontainers.image.source='https://github.com/kevindurb/infra'

FROM base as development

FROM base as production

COPY ./settings.js /data/settings.js
