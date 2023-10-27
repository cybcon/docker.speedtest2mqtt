FROM alpine:3.18.4

LABEL maintainer="Michael Oberdorf IT-Consulting <info@oberdorf-itc.de>"
LABEL site.local.program.version="1.0.0"

ENV MQTT_SERVER=localhost \
    MQTT_PORT=1883 \
    MQTT_TLS_enabled=false \
    MQTT_TLS_no_hostname_validation=false

RUN apk upgrade --available --no-cache --update \
    && apk add --no-cache --update \
       speedtest-cli=2.1.3-r5 \
       mosquitto-clients=2.0.18-r0 \
       bash=5.2.15-r6

COPY --chown=root:root /src /

USER 2536:2536

# Start Process
ENTRYPOINT ["/entrypoint.sh"]
