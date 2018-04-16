#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [[ $# -eq 0 ]] ; then
    echo 'No arguments supplied!'
    exit 1
fi
ENV=${1}
DATE=${2}
LIMIT=1000
# ensure dump utils are installed
if ! [ -x "$(command -v pg_restore)" ]; then
  echo 'Error: pg_restore is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v mongodump)" ]; then
  echo 'Error: mongodump is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v elasticdump)" ]; then
  echo 'Error: elasticdump is not installed. Install with npm install -g elasticdump' >&2
  exit 1
fi

# load config
if [ -f ./conf/${ENV}.properties ]; then
  . ./conf/${ENV}.properties
else
  echo "No such enviroment: ./conf/${ENV}"
  exit 1
fi
BACKUP_FOLDER="${BACKUP_FOLDER}/${DATE}_${ENV}"


# define coyo index types and names
declare -a types=("data")
declare -a indexes=("comment" "event" "event-membership" "form-entry" "forum-thread" "forum-thread-answer" \
 "fulltext-content" "list-entry" "message" "message-channel" "message-channel-status" \
 "notification" "page" "search" "search-values-v2" "sender" "sender-role-principle" \
 "timeline-item" "timeline-item-v2" "user" "workspace")

# create pgpass for passwordless llogin
echo "*:*:${PG_DB}:${PG_USER}:${PG_PASS}" > ~/.pgpass
chmod 600 ~/.pgpass

psql -w -h ${PG_HOST} -U ${PG_USER} coyo -f ./bin/drop_all.sql > logs/pg_restore.log 2>&1
psql -w -h ${PG_HOST} -U ${PG_USER} ${PG_DB} -f ${BACKUP_FOLDER}/pg_dump.sql > logs/pg_restore.log 2>&1
mongorestore --drop --host ${MONGO_HOST} --archive=${BACKUP_FOLDER}/mongo_dump > logs/mongo_restore.log 2>&1
curl -u ${BACKEND_USER}:${BACKEND_PASS} -k -X POST -H "Content-Type: application/json" -d '{"indexNames" : ["comment", "fulltext-content", "list-entry", "message-channel-status", "message-channel", "message", "notification", "page", "search", "sender", "timeline-item", "user", "workspace"] }' "${BACKEND_URL}/manage/index/recreate"
for type in "${types[@]}"; do
  for index in "${indexes[@]}"; do
    if [[ -f "${BACKUP_FOLDER}/es/_${index}_${type}.json" ]]; then
      elasticdump --input=${BACKUP_FOLDER}/es/_${index}_${type}.json --output=${ELASTIC_URL}/${index} --type=${type} --limit=${LIMIT} > logs/elastic_restore_${index}_${type}.log 2>&1
    fi
  done
done

exit 0
