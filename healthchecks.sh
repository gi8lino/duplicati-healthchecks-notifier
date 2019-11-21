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
#https://unix.stackexchange.com/questions/459805/how-to-retrieve-values-from-json-object-using-awk-or-sed
#HEALTHCHECKS_URL="https://jsonplaceholder.typicode.com/todos"

#result=$(curl  -fsS --retry 3 $HEALTHCHECKS_URL)
#echo -e $result

#GROUP_ID_TEMP=$(grep -B1 -A1 '"title": "delectus aut autem"' <<< ${result})
#GROUP_ID=$(echo $GROUP_ID_TEMP | cut -d : -f3 ) #| aw

RESULTS=( "Error" "Warning" "Fatal" "Unknown" "Success" )
OPERATIONS=( "Backup" "Restore")

HEALTHCHECKS_URL="https://healthchecks.giottolino.ch"

# jq -r '.checks[] | select(.name == "${DUPLICATI__backup_name}").ping_url'
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