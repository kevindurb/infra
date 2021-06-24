FROM grafana/grafana:8.0.3 as base

LABEL org.opencontainers.image.source='https://github.com/kevindurb/infra'

RUN mkdir -p /etc/grafana/provisioning

FROM base as development

FROM base as production

COPY ./provisioning/ /etc/grafana/provisioning/
COPY ./grafana.ini /etc/grafana/grafana.ini
