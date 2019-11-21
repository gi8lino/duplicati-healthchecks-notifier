#!/bin/sh
delcare -A RESULTS
delcare -A OPERATIONS


function jsonValue() {
    local KEY=$1
    local num=$2
    awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

if [ -z "$1" ]; then
    echo -e "no healthcheck ID passed to the script! exit"
    exit 1
fi

RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )
OPERATIONS=( "Backup" "Restore")

HEALTHCHECKS_URL="https://healthchecks.giottolino.ch"


if [[ " ${RESULTS[@]} " =~ " ${DUPLICATI_PARSED_RESULT} " ]] && [[ " $OPERATIONS[@]} " "${DUPLICATI_OPERATIONNAME} " ]]; then

    HEALTHCHECKS_CHECKS=$(curl --header "X-Api-Key: your-api-key" HEALTHCHECKS_URL/api/v1/checks/)

    PING_URL=$(${HEALTHCHECKS_CHECKS} | | jsonValue ${DUPLICATI__backup_name} 1 )

    if [ ${DUPLICATI_PARSED_RESULT} != "Success" ]; then
        URL="${URL}/fail"
    fi
    result=$(curl -fsS --retry 3 ${URL}> /dev/null)

    if [ ! ${result} == "ok" ]; then
        echo -e "cannot update healthchecks!"
    fi
fi

exit 0