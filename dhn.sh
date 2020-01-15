#!/bin/bash
set -o errexit

VERSION="0.0.2"
RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )
ALLOWED_OPERATIONS=( "Backup" )

function ShowHelp {
    RESULTS=$(IFS=\| ; echo "${RESULTS[*]}")
    printf "%s\n" \
	        "Usage: dhn.sh [-u|--url URL]" \
			"              [-t|--token TOKEN]" \
			"              [-a|--allowed-operations \"TYPE ...\"]" \
			"              [-s|--send-start]" \
			"              [-jq|--jq-path PATH] " \
			"              [-l|--log-file PATH]" \
			"              [-d|--debug] | [-h|--help] | [-v|--version]" \
	        "" \
			"Script to add as 'run-script-before' and/or 'run-script-after' in Duplicati (https://www.duplicati.com)." \
			"To measuring the Duplicati job execution time use this script as 'run-script-before' in Duplicati and " \
			"start this script with the parameter '-s|--send-start'. The script will append " \
			"'/start' to the Healthchecks ping url." \
	        "To signal Healthchecks a Duplicati 'Success' event add this script as 'run-script-after' in Duplicati." \
	        "If the Duplicati job was not successfully, it pings Healthchecks with '/fail'." \
			"" \
	        "Requirements:" \
	        "- jq (https://stedolan.github.io/jq)" \
	        "You can install 'jq' or you can download it an pass the path to 'jq' with a parameter." \
	        "" \
	        "Parameters:" \
	        "-u, --url [URL]                            healthchecks url" \
	        "-t, --token [TOKEN]                        healthchecks API Access ('read-only' token does not work!)" \
	        "-a, --allowed-operations \"[Type] ...\"      only notify if types of operations match" \
	        "                                           list of strings, separatet by a space (not case sensitive)" \
	        "                                           default: Backup" \
	        "-s, --send-start                           notify healthchecks when operation starts" \
	        "-j, --jq-path [PATH]                       path to 'jq' if not in '\$PATH'" \
	        "-l, --log-file [PATH]                      log to file. if not set log to console" \
	        "-d, --debug                                set log level to 'debug'" \
	        "-h, --help                                 display this help and exit" \
	        "-v, --version                              output version information and exit" \
	        "" \
			"examples:" \
			"./dhn.sh -u https://healthchecks.example.com -t <TOKEN> -l dhn.log" \
			"./dhn.sh -u https://healthchecks.example.com -t <TOKEN> -a \"Backup Restore\" -s -l dhn.log" \
			"" \
	        "created by gi8lino (2020)" \
	        "https://github.com/gi8lino/duplicati-healthchecks-notifier"
	exit 0
}

# level: level of log entry
# text: message of log entry
function log() {
    local _level=$1
    local _text=$2

    local _current=$(date '+%Y-%m-%d %H:%M:%S')

    if [ ${_level} == "DEBUG" ] && [ -z "${DEBUG}" ]; then
        return
    fi

    if [ -n "${LOG_FILE}" ];then
        echo "${_current}; ${_level}; ${_text}" >> "${LOG_FILE}"
    else
        echo "${_current}; ${_level}; ${_text}"
    fi
}

shopt -s nocasematch  # set string compare to not case senstive

# read start parameter
while [[ $# -gt 0 ]];do
    key="$1"
    case $key in
	    -u|--url)
	    HEALTHCHECKS_URL="$2"
	    shift  # pass argument
	    shift  # pass value
	    ;;
	    -t|--token)
	    TOKEN="$2"
	    shift  # pass argument
	    shift  # pass value
	    ;;
	    -a|--allowed-operations)
	    ALLOWED_OPERATIONS="$2"
	    shift  # pass argument
	    shift  # pass value
	    ;;
	    -s|--send-sart)
	    SEND_START=true
	    shift  # pass argument
	    ;;
	    -l|--log-file)
	    LOG_FILE="$2"
	    shift  # pass argument
	    shift  # pass value
	    ;;
	    -j|--jq-path)
	    JQ_PATH="$2"
	    shift  # pass argument
	    shift  # pass value
	    ;;
	    -d|--debug)
	    DEBUG="true"
	    shift  # pass argument
	    ;;
	    -v|--version)
	    printf "duplicati-healthchecks-notifier version: %s\n" "${VERSION}"
	    exit 0
	    ;;
	    -h|--help)
	    ShowHelp
	    ;;
	    *)  # unknown option
	    printf "%s\n" \
	       "$(basename $BASH_SOURCE): invalid option -- '$1'" \
	       "Try '$(basename $BASH_SOURCE) --help' for more information."
	    exit 1
	    ;;
    esac  # end case
done

if [ -n "${LOG_FILE}" ];then
    log "DEBUG" "log to file '${LOG_FILE}' enabled"
fi

if [ ! -n "${HEALTHCHECKS_URL}" ]; then
    log "ERROR" "healthchecks url not found in script start parameter (-u|--url)"
    exit 1
fi

if [ ! -n "${TOKEN}" ]; then
    log "ERROR" "healthchecks token not found in script start parameter (-t|--token)"
    exit 1      
fi

if [ -n "${JQ_PATH}" ]; then
    if [ ! -f "${JQ_PATH}" ]; then
	    log "ERROR" "path to jq '${JQ_PATH}' does not exists"
	    exit 1
    fi
    log "DEBUG" "use 'jq' from '${JQ_PATH}'"
else
    if [ ! -x "$(command -v jq)" ]; then
	    log "ERROR" "'jq' is not installed! please install 'jq' or download binary and add the path as start parameter (-j|--jq-path)"
	    exit 1
    fi
    JQ_PATH="jq"
    log "DEBUG" "use installed 'jq'"
fi

log "DEBUG" "duplicati parsed result is '${DUPLICATI__PARSED_RESULT}'"
log "DEBUG" "duplicati operation is '${DUPLICATI__OPERATIONNAME}'"
log "DEBUG" "duplicati backup name is '${DUPLICATI__backup_name}'"
log "DEBUG" "duplicati event name is '${DUPLICATI__EVENTNAME}'"

if [ -n "${DUPLICATI__PARSED_RESULT}" ]  &&  [[ ! " ${RESULTS[@]} " =~ " ${DUPLICATI__PARSED_RESULT} " ]]; then
    log "ERROR" "'${DUPLICATI__PARSED_RESULT}' is not a valid result (valid: $(IFS=\| ; echo "${RESULTS[*]}"))"
    exit 1
fi

# check if operation is allowed
if [[ ! " ${ALLOWED_OPERATIONS[@]} " =~ " ${DUPLICATI__OPERATIONNAME} " ]]; then
    log "WARNING" "'${DUPLICATI__OPERATIONNAME}' is not a wanted operation. exit"
    exit 0
fi

# get healthcheck entries
HEALTHCHECKS_CHECKS=$(curl -fsS --retry 3 --header "X-Api-Key: ${TOKEN}" "${HEALTHCHECKS_URL%/}/api/v1/checks/")

if [ ! -n "${HEALTHCHECKS_CHECKS}" ] || [ "${HEALTHCHECKS_CHECKS}" == "null" ]; then
    log "ERROR" "cannot receive list of existing checks"
    exit 1
fi

# extract ping url
PING_URL=$(echo "${HEALTHCHECKS_CHECKS}" | ${JQ_PATH} -r ".checks[] | select(.name == \"${DUPLICATI__backup_name}\").ping_url")

if [ -z "${PING_URL}" ] || [ "${PING_URL}" == "null" ]; then
    log "ERROR" "cannot evaluate ping url for '${DUPLICATI__backup_name}'"
    exit 1
fi

if [ $DUPLICATI__EVENTNAME == "BEFORE" ]; then
    PING_URL="${PING_URL}/start"
elif [ "${DUPLICATI__PARSED_RESULT}" != "Success" ]; then
    # update url if job was NOT successfull
    log "ERROR" "Duplicati job status is '${DUPLICATI__PARSED_RESULT}'"
    PING_URL="${PING_URL}/fail"
fi
log "DEBUG" "get 'ping_url' '${PING_URL}'"

result=$(curl -fsS --retry 3 "${PING_URL}")
log "DEBUG" "healthchecks retuned '${result}'"

if [ "${result}" != "OK" ]; then
    log "ERROR" "cannot update healthchecks! healthchecks returned '${result}'"
    exit 1
fi

log "INFO" "healthcheck for Duplicati job '${DUPLICATI__backup_name}' successfully updated"

exit 0
