FROM alpine:3.18.4

LABEL maintainer="Michael Oberdorf IT-Consulting <info@oberdorf-itc.de>"
LABEL site.local.program.version="1.0.0"

RUN apk upgrade --available --no-cache --update \
    && apk add --no-cache --update \
       speedtest-cli=2.1.3-r5 \
       mosquitto-clients=2.0.18-r0

COPY --chown=root:root /src /

USER 2536:2536

# Start Process
ENTRYPOINT ["/entrypoint.sh"]
