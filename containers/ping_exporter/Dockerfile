FROM prom/blackbox-exporter as base

CMD ["--config.file=/config/ping.yaml"]

RUN mkdir -p /config

FROM base as development

FROM base as production

COPY ./config/ /config/
