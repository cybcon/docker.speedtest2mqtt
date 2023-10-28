# Quick reference

Maintained by: [Michael Oberdorf IT-Consulting](https://www.oberdorf-itc.de/)

Source code: [GitHub](https://github.com/cybcon/docker.speedtest2mqtt)

# Supported tags and respective `Dockerfile` links

* [`latest`, `1.0.1`](https://github.com/cybcon/docker.speedtest2mqtt/blob/v1.0.1/Dockerfile)

# Summary

The container image is based on Alpine Linux and combines the [speedtest-cli](https://github.com/sivel/speedtest-cli) and
the [mosquitto-client](https://mosquitto.org/) to trigger a simple internet speedtest and publish the json formatted output
to a MQTT server topic.

# Prerequisites to run the docker container
You need an MQTT server to send the data to it.

# Configuration
## Container configuration

The container grab the configuration via environment variables.

| Environment variable name | Description | Required | Default value |
|--|--|--|--|
| `MQTT_SERVER` | The MQTT server hostname or IP address | **OPTIONAL** | `localhost` |
| `MQTT_PORT` | The TCP port of the MQTT server | **OPTIONAL** | `1883` |
| `MQTT_TLS_enabled` | Should SSL communication be enabled (`true`) or not (`false`) | **OPTIONAL** | `false` |
| `MQTT_CACERT_FILE` | If TLS is enabled, the path to the CA certificate file to validate the MQTT server certificate | **OPTIONAL** | |
| `MQTT_TLS_no_hostname_validation` | If TLS is enabled, skip the hostname validation of the TLS certificate | `false` |
| `MQTT_USER` | The MQTT username for MQTT authentication | **OPTIONAL** | |
| `MQTT_PASSWORD_FILE` | The filepath where the MQTT password is stored for MQTT authentication | **OPTIONAL** | |
| `MQTT_TOPIC` | The MQTT topic to send the speedtest results to | **MANDATORY** | |
| `MQTT_RETAIN`| Set the retain flag when publishing the speedtest result to MQTT topic | **OPTIONAL** | `false` |
| `FREQUENCE` | Time in seconds between speedtests. If nothing is given, the container stops after 1 speedtest | **OPTIONAL** | |

# Docker compose configuration

```yaml
version: '3.8'

services:
  speedtest2mqtt:
    container_name: speedtest2mqtt
    restart: "no"
    read_only: true
    user: 2536:2536
    image: oitc/speedtest2mqtt
    environment:
      MQTT_SERVER: test.mosquitto.org
      MQTT_PORT: 1883
      MQTT_TOPIC: de/oberdorf-itc/speedtest2mqtt/results
      FREQUENCE: 300
   secrets:
      - speedtest2mqtt_mqtt_password
    tmpfs:
      - /tmp

secrets:
  speedtest2mqtt_mqtt_password:
    file: /srv/docker/speedtest2mqtt/secrets/mqtt_password
```

# License

Copyright (c) 2023 Michael Oberdorf IT-Consulting

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
