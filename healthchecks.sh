#!/bin/sh

export PATH=${PATH}:/config/bin

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
	    LOGFILE="$2"
	    shift  # pass argument
	    shift  # pass value
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

# level: level of log entry
# text: message of log entry
# logpath: path to logfile. if set, the log entry will be saved in this file
function log() {
    local _level=$1
    local _text=$2
    local _logpath=$3

    local _current=`date '+%Y-%m-%d %H:%M:%S'`
    if [ ${_logpath} ];then
        echo "${_current}; ${_level}; ${_text}" >> "${_logpath}"
    else
        echo "${_current}; ${_level}; ${_text}"
    fi
}

if [ -n ${LOGFILE} ];then
    to_file=$LOGFILE  # set path to logfile
fi

if [ ! -n "${HEALTHCHECKS_URL}" ]; then
    HEALTHCHECKS_URL=$(printenv HC_URL)
    if [ ! -n "${HEALTHCHECKS_URL}" ]; then
        log "ERROR" "healthchecks url not found in script start parameter nor in environment (HC_URL)" $to_file
        exit 1
    then
fi

if [ ! -n "${TOKEN}" ]; then
    HEALTHCHECKS_URL=$(printenv HC_TOKEN)
    if [ ! -n "${TOKEN}" ]; then
        log "ERROR" "healthchecks token not found in script start parameter nor in environment (HC_TOKEN)" $to_file
        exit 1
    then
fi

RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )

if [[ " ${RESULTS[@]} " =~ " ${DUPLICATI_PARSED_RESULT} " ]] && [ "${DUPLICATI_OPERATIONNAME} " == "Backup" ]; then
    # get healthcheck entries
    HEALTHCHECKS_CHECKS=$(curl --header "X-Api-Key: ${TOKEN}" HEALTHCHECKS_URL/api/v1/checks/)

    PING_URL=$(HEALTHCHECKS_CHECKS | jq -r '.checks[] | select(.name == "${DUPLICATI__backup_name}").ping_url' )  # extract ping url

    if [ -z "${PING_URL}" ]; then
        log "WARNING" "cannot evaluate ping url for '${DUPLICATI__backup_name}'" $to_file
        exit 0
    fi

    if [ ${DUPLICATI_PARSED_RESULT} != "Success" ]; then
        URL="${URL}/fail"
    fi
    result=$(curl -fsS --retry 3 ${URL}> /dev/null)

    if [ ${result} != "ok" ]; then
        log "ERROR" "cannot update healthchecks! ${result}" $to_file
        exit 1
    fi
fi

exit 0