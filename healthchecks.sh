#!/bin/bash
set -o errexit

VERSION="0.0.1"
RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )

function ShowHelp {
    RESULTS=$(IFS=\| ; echo "${RESULTS[*]}")
	printf "%s\n" \
		   "Usage: $(basename $BASH_SOURCE) [-u|--url URL] [-t|--token TOKEN] [-jq|--jq-path PATH] [-l|--log-file PATH] [-d|--debug] | [-h|--help] | [-v|--version]" \
		   "" \
               "Checks if Duplicati backup was successfully and ping healhchecks." \
           "If the backup was not successfully, it pings to '\fail'" \
		   "" \
		   "Parameters:" \
		   "-u, --url [URL]                     healthchecks url" \
		   "-t, --token [TOKEN]                 healthchecks API Access ('read-only' token does not work!)" \
		   "-j, --jq-path [PATH]                path to jq if not in 'PATH' or not set as environment variable (HC_JQ)" \
		   "-l, --log-file [PATH]               log to file. if not set log to console" \
		   "-d, --debug                         set log level to 'debug'" \
		   "-h, --help                          display this help and exit" \
		   "-v, --version                       output version information and exit" \
           "" \
           "Environment variables:" \
           "You can also use environment variables to set the healthchecks url and token." \
           "HC_URL                             healthchecks url" \
           "HC_TOKEN                           healthchecks API Access ('read-only' token does not work!)" \
           "HC_JQ                              path to jq if not in 'PATH' or not set with start argument (-j|--jq-path)" \
		   "" \
		   "created by gi8lino (2019)"
	exit 0
}

# level: level of log entry
# text: message of log entry
# logpath: path to logfile. if set, the log entry will be saved in this file
function log() {
    local _level=$1
    local _text=$2
    local _logpath=$3

    local _current=`date '+%Y-%m-%d %H:%M:%S'`

    if [ ${_level} == "DEBUG" ] && [ ! -n "${DEBUG}" ]; then
        return
    fi

    if [ ${_logpath} ];then
        echo "${_current}; ${_level}; ${_text}" >> "${_logpath}"
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
	    printf "$(basename $BASH_SOURCE) version: %s\n" "${VERSION}"
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
    to_file=$LOG_FILE  # set path to logfile
    log "DEBUG" "log to file ('${to_file}') enabled" $to_file
fi

if [ ! -n "${HEALTHCHECKS_URL}" ]; then
    HEALTHCHECKS_URL=$(printenv HC_URL)
    if [ ! -n "${HEALTHCHECKS_URL}" ]; then
        log "ERROR" "healthchecks url not found in script start parameter (-u|--url) nor in environment (HC_URL)" $to_file
        exit 1
    fi
    log "DEUBG" "get healthchecks url '${HEALTHCHECKS_URL}' from environmentvariable 'HC_URL'" $to_file
else
    log "DEUBG" "get healthchecks url '${HEALTHCHECKS_URL}' from start argument" $to_file
fi

if [ ! -n "${TOKEN}" ]; then
    TOKEN=$(printenv HC_TOKEN)
    if [ ! -n "${TOKEN}" ]; then
        log "ERROR" "healthchecks token not found in script start parameter nor in environment (HC_TOKEN)" $to_file
        exit 1
    fi
    log "DEUBG" "get healthchecks token '${TOKEN}' from environmentvariable 'HC_TOKEN'" $to_file
else
    log "DEUBG" "get healthchecks token '${TOKEN}' from start argument" $to_file
fi

if [ -n "${JQ_PATH}" ]; then
    if [ -f "${JQ_PATH}" ]; then
        log "ERROR" "path to jq '${JQ_PATH}' does not exists" $to_file
        exit 1
    fi
else
    if [ ! $(which jq) ]; then
        log "ERROR" "jq is not installed! please install jq or download binary and add path to jq to start parameter (-j|--jq-path)" $to_file
        exit 1
    fi
    JQ_PATH="jq"
    log "DEBUG" "use 'jq' from '$(which jq)'" $to_file
fi
log "DEBUG" "using '${JQ_PATH}'" $to_file

log "DEBUG" "duplicati result is '${DUPLICATI__PARSED_RESULT}'" $to_file
log "DEBUG" "duplicati operation is '${DUPLICATI__OPERATIONNAME}'" $to_file
log "DEBUG" "duplicati backup name is '${DUPLICATI__backup_name}'" $to_file

if [[ " ${RESULTS[@]} " =~ " ${DUPLICATI__PARSED_RESULT} " ]] && [[ "${DUPLICATI__OPERATIONNAME}" == "Backup" ]]; then
    # get healthcheck entries
    HEALTHCHECKS_CHECKS=$(curl -fsS --retry 3 --header "X-Api-Key: ${TOKEN}" "${HEALTHCHECKS_URL}/api/v1/checks/")
    
    if [ ! -n "${HEALTHCHECKS_CHECKS}" ] || [ "${PING_URL}" == "null" ]; then
        log "ERROR" "cannot receive list of existing checks" $to_file
        exit 1
    fi

    # extract ping url
    PING_URL=$(echo "${HEALTHCHECKS_CHECKS}" | ${JQ_PATH} -r ".checks[] | select(.name == \"${DUPLICATI__backup_name}\").ping_url")

    if [ -z "${PING_URL}" ] || [ "${PING_URL}" == "null" ]; then
        log "ERROR" "cannot evaluate ping url for '${DUPLICATI__backup_name}'" $to_file
        exit 1
    fi

    if [ ${DUPLICATI__PARSED_RESULT} != "Success" ]; then
        PING_URL="${PING_URL}/fail"
    fi
    
    log "DEBUG" "get 'ping_url' '${PING_URL}'" $to_file
    
    result=$(curl -fsS --retry 3 "${PING_URL}")
    log "DEBUG" "healthchecks retuned '${result}'" $to_file

    if [ "${result}" != "OK" ]; then
        log "ERROR" "cannot update healthchecks! healthchecks returned: '${result}''" $to_file
        exit 1
    fi
fi

exit 0