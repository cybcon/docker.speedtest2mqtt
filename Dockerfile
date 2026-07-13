FROM alpine:3.24.1

LABEL maintainer="Michael Oberdorf IT-Consulting <info@oberdorf-itc.de>"
LABEL site.local.program.version="1.3.0"

ENV MQTT_SERVER=localhost \
    MQTT_PORT=1883 \
    MQTT_TLS_enabled=false \
    MQTT_TLS_no_hostname_validation=false \
    MQTT_RETAIN=false

RUN apk upgrade --available --no-cache --update \
    && apk add --no-cache --update \
       speedtest-cli=2.1.3-r8 \
       mosquitto-clients=2.1.2-r1 \
       bash=5.3.9-r1 \
       jq=1.8.1-r0 \
       ca-certificates=20260611-r0

COPY --chown=root:root /src /

USER 2536:2536

# Start Process
ENTRYPOINT ["/entrypoint.sh"]
