#!/bin/bash

#Initiate script with the next global environment variables
CONFIG_PATH=${CONFIG_PATH}
STANDALONE_XML_FILE=${STANDALONE_XML_FILE}
ENABLE_DEBUG=${ENABLE_DEBUG:-false}

readonly EXTENSION_PTRN="*.properties"
readonly PROP_REGEX="\${[A-Z_a-z0-9]*}"
echo "========================================================================="
echo "INFO: replacing placeholders with corresponding environment variables in application ${EXTENSION_PTRN} files"

if [[ ! -d "${CONFIG_PATH}" ]]; then
  echo "ERROR: directory not found: ${CONFIG_PATH}"
  echo "ERROR: JBoss application server is not started"
  exit 1
fi

CONF_FILES=$(find "${CONFIG_PATH}" -type f -name "${EXTENSION_PTRN}")
if [[ -z "${CONF_FILES}" ]]; then
  echo "ERROR: ${EXTENSION_PTRN} config files not found in ${CONFIG_PATH}"
  echo "ERROR: JBoss application server is not started"
  exit 1
fi

for FILE in ${CONF_FILES}; do
  PLACEHOLDERS=$(grep -o "${PROP_REGEX}" "${FILE}" | sort | uniq)
  if [[ ! -z "${PLACEHOLDERS}" ]]; then
    echo "INFO: replacing placeholders in ${FILE}"
    for PLACEHOLDER in ${PLACEHOLDERS}; do
      ENV_VAR=${PLACEHOLDER:2:-1}
      if [[ -n "${!ENV_VAR}" ]]; then
        SED_SCRIPT="s|${PLACEHOLDER}|${!ENV_VAR}|g"
        sed -i "${SED_SCRIPT}" "${FILE}"
        if (( $? != 0 )); then
          echo "ERROR: unable to replace placeholder '${PLACEHOLDER}' with '${!ENV_VAR}'"
          echo "ERROR: JBoss application server is not started"
          exit 1
        fi
        if [ "${ENABLE_DEBUG}" = "true" ]; then
          echo "DEBUG: placeholder '${PLACEHOLDER}' replaced with '${!ENV_VAR}'"
        fi
      else
        echo "WARNING: no environment variable required to replace placeholder ${PLACEHOLDER}"
        echo "WARNING: the application may not work properly, check setup of container's evrironment variables"
      fi
    done
  fi
done
echo "========================================================================="

echo "INFO: starting JBOSS server..."
"$JBOSS_HOME"/bin/standalone.sh -c "$STANDALONE_XML_FILE" -b 0.0.0.0