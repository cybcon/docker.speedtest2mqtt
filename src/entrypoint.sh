#!/bin/bash
##############################################################################
# Speedtest2mqtt - entrypoint script
# Description: The script will trigger the speedtest-cli command. The result
#   will be send to a given MQTT topic
#-----------------------------------------------------------------------------
# Author: Michael Oberdorf
# Date:   2023-10-27
# Last changed by: Michael Oberdorf
# Last changed at: 2023-10-29
##############################################################################

#-----------------------------------------------------------------------------
# Global configuration
#-----------------------------------------------------------------------------
VERSION="1.1.1"
ERROR_SLEEP_SECONDS=60
CACERT_SYSTEM_PATH='/usr/share/ca-certificates'

# Set default values
if [ -z "${MQTT_SERVER}" ]; then
  MQTT_SERVER='localhost'
fi
if [ -z "${MQTT_PORT}" ]; then
  MQTT_PORT='1883'
fi
if [ -z "${MQTT_TLS_enabled}" ]; then
  MQTT_TLS_enabled='false'
fi
if [ -z "${MQTT_TLS_no_hostname_validation}" ]; then
  MQTT_TLS_no_hostname_validation='false'
fi
if [ -z "${MQTT_RETAIN}" ]; then
  MQTT_RETAIN='false'
fi
MQTT_PASSWORD=''

##############################################################################
# F U N C T I O N S
##############################################################################

#-----------------------------------------------------------------------------
# trim
# @desc: remove leading and trailing whitespaces from a given string
# @param: string, the string to trim
# @return: string, the trimmed string
#-----------------------------------------------------------------------------
function trim {
  string=${@}
  trimmed_string=$(echo "${string}" | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*\$//g')
  echo ${trimmed_string}
}

#-----------------------------------------------------------------------------
# is_int
# @desc: Test if a given value is an integer
# @param: string, value to test
# @return: string: 'true' (it is an integer) or 'false' (it is no integer)
#-----------------------------------------------------------------------------
function is_int {
  value=${1}

  # if given value is empty, it is no INT
  if [ -z "${value}" ]; then
    echo "false"
  fi

  # test if we can add 1 to the given value
  value_test=$(expr ${value} + 1 2>/dev/null)
  # if the result is empty, the given vale was no number
  if [ -z "${value_test}" ]; then
    echo "false"
  else
    echo "true"
  fi
  return
}

#-----------------------------------------------------------------------------
# validate_boolean
# @desc: Normalize a given string and validate if the string is one of:
#   'true', 'false', 'yes', 'no', '1', '0'
# @param: string, boolean value to validate
# @return: normalized boolean 'true' or 'false' or NULL
#-----------------------------------------------------------------------------
function validate_boolean {
  string="${@}"
  normalized_boolean=$(echo ${string} | tr '[:upper:]' '[:lower:]')
  normalized_boolean=$(trim "${normalized_boolean}")
  if [ "${normalized_boolean}" == "yes" -o "${normalized_boolean}" == "1" ]; then
    normalized_boolean='true'
  elif [ "${normalized_boolean}" == "no" -o "${normalized_boolean}" == "0" ]; then
    normalized_boolean='false'
  fi

  if [ "${normalized_boolean}" == "true" -o "${normalized_boolean}" == "false" ]; then
    echo "${normalized_boolean}"
  fi
  return
}



#-----------------------------------------------------------------------------
# validate_input_parameters
# @desc: validate the given input parameters (environment variables)
#-----------------------------------------------------------------------------
function validate_input_parameters {
  if [ -z "$(validate_boolean ${MQTT_TLS_enabled})" ]; then
    echo "ERROR: Environment variable 'MQTT_TLS_enabled' needs to be 'true' or 'false' (but is ${MQTT_TLS_enabled})!" >&2
    exit 1
  else
    MQTT_TLS_enabled=$(validate_boolean ${MQTT_TLS_enabled})
  fi

  if [ -z "$(validate_boolean ${MQTT_TLS_no_hostname_validation})" ]; then
    echo "ERROR: Environment variable 'MQTT_TLS_no_hostname_validation' needs to be 'true' or 'false' (but is ${MQTT_TLS_no_hostname_validation})!" >&2
    exit 1
  else
    MQTT_TLS_no_hostname_validation=$(validate_boolean ${MQTT_TLS_no_hostname_validation})
  fi

  if [ -z "$(validate_boolean ${MQTT_RETAIN})" ]; then
    echo "ERROR: Environment variable 'MQTT_RETAIN' needs to be 'true' or 'false' (but is ${MQTT_RETAIN})!" >&2
    exit 1
  else
    MQTT_RETAIN=$(validate_boolean ${MQTT_RETAIN})
  fi

  if [ ! -z "${MQTT_PORT}" ]; then
    if [ "$(is_int ${MQTT_PORT})" == "false" ]; then
      echo "ERROR: Given MQTT Port (${MQTT_PORT}) is no integer!" >&2
      exit 1
    fi
    if [ ${MQTT_PORT} -le 0 -o ${MQTT_PORT} -gt 65535 ]; then
      echo "ERROR: Given MQTT Port (${MQTT_PORT}) is not in the valid TCP port range from 1-65535!" >&2
      exit 1
    fi
  fi

  if [ ! -z "${FREQUENCE}" ]; then
    if [ "$(is_int ${FREQUENCE})" == "false" ]; then
      echo "ERROR: Given FREQUENCE (${FREQUENCE}) is no integer!" >&2
      exit 1
    fi
  fi

  if [ ! -z "${MQTT_PASSWORD_FILE}" ]; then
    if [ ! -f "${MQTT_PASSWORD_FILE}" ]; then
      echo "ERROR: File not found exception for MQTT_PASSWORD_FILE=${MQTT_PASSWORD_FILE}!" >&2
      exit 1
    else
      MQTT_PASSWORD=$(cat ${MQTT_PASSWORD_FILE} | head -1)
      MQTT_PASSWORD=$(trim "${MQTT_PASSWORD}")
    fi
  fi

  if [ ! -z "${MQTT_CACERT_FILE}" ]; then
    if [ ! -f "${MQTT_CACERT_FILE}" -a ! -d "${MQTT_CACERT_FILE}" ]; then
      echo "ERROR: File not found exception for MQTT_CACERT_FILE=${MQTT_CACERT_FILE}!" >&2
      exit 1
    fi
  fi

  if [ -z "${MQTT_TOPIC}" ]; then
    echo "ERROR: MQTT_TOPIC not defined. This parameter is mandatory!" >&2
    exit 1
  fi
}

#-----------------------------------------------------------------------------
# do_speedtest
# @desc: execute speedtest-cli and grap the output
# @return: string, json output
#-----------------------------------------------------------------------------
function do_speedtest {
  speedtest-cli --json | jq 2>/dev/null
}

#-----------------------------------------------------------------------------
# publish_result
# @desc: connect to MQTT server and publish the given information
# @param: string, data to publish to MQTT
#-----------------------------------------------------------------------------
function publish_result {
  data="${@}"

  CREDENTIALS=''
  if [ ! -z "${MQTT_USER}" -a ! -z "${MQTT_PASSWORD}" ]; then
    CREDENTIALS="--username ${MQTT_USER} --pw ${MQTT_PASSWORD}"
  fi
  RETAIN=''
  if [ "${MQTT_RETAIN}" == "true" ]; then
    RETAIN='--retain'
  fi

  TLS=''
  if [ "${MQTT_TLS_enabled}" == "true" ]; then
    CACERT=''
    if [ ! -z "${MQTT_CACERT_FILE}" ]; then
      if [ -f "${MQTT_CACERT_FILE}" ]; then
        CACERT="--cafile ${MQTT_CACERT_FILE}"
      elif [ -d "${MQTT_CACERT_FILE}" ]; then
        CACERT="--capath ${MQTT_CACERT_FILE}"
      fi
    else
      CACERT="--capath ${CACERT_SYSTEM_PATH}"
    fi

    INSECURE=''
    if [ "${MQTT_TLS_no_hostname_validation}" == "true" ]; then
      CACERT=''
      INSECURE='--insecure'
    fi

    TLS="${INSECURE} ${CACERT} --tls-version tlsv1.2"
  fi

  echo "${data}" |  mosquitto_pub --host ${MQTT_SERVER} --port ${MQTT_PORT} ${CREDENTIALS} --topic ${MQTT_TOPIC} ${TLS} ${RETAIN} --stdin-file
}


##############################################################################
# M A I N
##############################################################################

echo "Speedtest2mqtt v${VERSION} started"

validate_input_parameters

while true
do
  echo "Trigger Speedtest"
  result=$(do_speedtest)
  if [ ! -z "${result}" ]; then
    echo "Speedtest result is:"
    echo "${result}"
    echo "Publish speedtest result via MQTT"
    publish_result "${result}"
  else
    echo "WARNING: Speedtest without correct json output. Sleep ${ERROR_SLEEP_SECONDS} and try again"
    sleep ${ERROR_SLEEP_SECONDS}
    continue
  fi

  if [ ! -z "${FREQUENCE}" ]; then
    echo "Sleeping ${FREQUENCE} seconds"
    sleep ${FREQUENCE}
  else
    break
  fi
done

echo "Speedtest2mqtt v${VERSION} stopped"
