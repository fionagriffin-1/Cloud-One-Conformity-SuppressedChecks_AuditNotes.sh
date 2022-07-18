#!/bin/bash
# A simple script to get suppressed checks audit notes in Cloud Conformity
​
echo "Which region is your conformity environment hosted in?"
read -r region
​
echo "Enter your api key: "
read -r apikey
​
# select which Conformity accounts to run against
if [ "$#" -eq  "0" ]
then
    echo "No accountid arguments specified, generating report across all accounts loaded in conformity"
    export accountid=($(curl -L -X GET \
        "https://$region-api.cloudconformity.com/v1/accounts" \
        -H "Content-Type: application/vnd.api+json" \
        -H "Authorization: ApiKey $apikey" \
        | jq -r '.data | map(.id) | join(",")'))
	echo "Will generate report for the following accounts $accountid"
else #run against only specified accountids in argument
    export accountid=$1
fi
​
# run the csv script based on selection and for each account
TIMESTAMP=$(date +%Y-%m-%d_%H.%M.%S)
	curl -L -X GET "https://$region-api.cloudconformity.com/v1/events?accountIds=$accountid&filter[name]=account.check.note.added&cc=true&aws=false&page[size]=1000" \
        -H "Content-Type: application/vnd.api+json" \
        -H "Authorization: ApiKey $apikey" \
		| jq -r '.data[]? | select (.attributes["name"] == "account.check.note.added") | {"ruleId": .attributes.extra["rule-id"], "check-id": .attributes.extra["check-id"], "Audit Notes": .attributes.extra["note"], "timestamp": .attributes.time|(. / 1000 | strftime("%Y-%m-%d %H:%M UTC"))}| keys_unsorted, map(.) | @csv' | awk 'NR==1 || NR%2==0'  >> SuppressedChecksAuditNotes_"$TIMESTAMP".csv