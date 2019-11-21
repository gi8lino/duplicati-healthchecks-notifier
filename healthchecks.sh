#!/bin/bash
delcare -A RESULTS
delcare -A OPERATIONS
declare -A DUPLICATI

RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )
OPERATIONS=( "Backup" "Restore")

HEALTHCHECKS_URL="https://healthchecks.giottolino.ch/ping/"
SLACK_URL

BACKUP_JOBS= ( ["opt"]="id" )


slack() (
    local _text=$1
    result=(curl -fsS --retry 3 ${SLACK_URL}> /dev/null)
)

if [[ " ${RESULTS[@]} " =~ " ${DUPLICATI_PARSED_RESULT} " ]] && [[ " $OPERATIONS[@]} " "${DUPLICATI_OPERATIONNAME} " ]]; then

    ID=${BACKUP_JOBS[${DUPLICATI__backup_name}]}
    if [ ! -z "ID" ]; then
        echo "no id for backupjob '${DUPLICATI__backup_name}' found"
    fi
    URL=${HEALTHCHECKS_URL}${ID}

    if [ ${DUPLICATI_PARSED_RESULT} != "Success" ]; then
        URL=${URL}/fail
    fi

    result=(curl -fsS --retry 3 URL> /dev/null)

fi

exit 0