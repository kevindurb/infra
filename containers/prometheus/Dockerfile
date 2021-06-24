FROM prom/prometheus:v2.25.2 as base

LABEL org.opencontainers.image.source='https://github.com/kevindurb/infra'

RUN mkdir -p /etc/prometheus

CMD [ \
  "--config.file=/etc/prometheus/prometheus.yaml", \
  "--storage.tsdb.path=/prometheus", \
  "--web.console.libraries=/usr/share/prometheus/console_libraries", \
  "--web.console.templates=/usr/share/prometheus/consoles" \
]

FROM base as development

FROM base as production

COPY ./config/ /etc/prometheus/
