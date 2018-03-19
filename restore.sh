#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [[ $# -eq 0 ]] ; then
    echo 'No arguments supplied!'
    exit 1
fi
ENV=${1}
BACKUP_FOLDER=${2}
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
if ! [ -x "$(command -v node_modules/elasticdump/bin/elasticdump)" ]; then
  echo 'Error: elasticdump is not installed. Install with npm install elasticdump' >&2
  exit 1
fi

# load config
if [ -f ${ENV}.properties ]; then
  . ${ENV}.properties
else
  echo "No such enviroment: ${ENV}"
  exit 1
fi

# define coyo index types and names
declare -a types=("data")
declare -a indexes=("comment" "event" "event-membership" "form-entry" "forum-thread" "forum-thread-answer" \
 "fulltext-content" "list-entry" "message" "message-channel" "message-channel-status" \
 "notification" "page" "search" "search-values-v2" "sender" "sender-role-principle" \
 "timeline-item" "user" "workspace")

# create pgpass for passwordless llogin
echo "*:*:${PG_DB}:${PG_USER}:${PG_PASS}" > ~/.pgpass
chmod 600 ~/.pgpass

psql -w -h ${PG_HOST} -U ${PG_USER} coyo -f drop_all.sql > logs/pg_restore.log 2>&1
gunzip -c ${BACKUP_FOLDER}/pg_dump.sql.gz | psql -w -h ${PG_HOST} -U ${PG_USER} ${PG_DB} > logs/pg_restore.log 2>&1
mongorestore --drop --host ${MONGO_HOST} --gzip --archive=${BACKUP_FOLDER}/mongo_dump.gz > logs/mongo_restore.log 2>&1
curl -u ${BACKEND_USER}:${BACKEND_PASS} -k -X POST -H "Content-Type: application/json" -d '{"indexNames" : ["comment", "fulltext-content", "list-entry", "message-channel-status", "message-channel", "message", "notification", "page", "search", "sender", "timeline-item", "user", "workspace"] }' "https://${BACKEND_HOST}/manage/index/recreate"
for type in "${types[@]}"; do
  for index in "${indexes[@]}"; do
    if [[ -f "${BACKUP_FOLDER}/es/_${index}_${type}.json" ]]; then
      ./node_modules/elasticdump/bin/elasticdump --input=${BACKUP_FOLDER}/es/_${index}_${type}.json --output=http://${ELASTIC_HOST}:9200/${index} --type=${type} --limit=${LIMIT} > logs/elastic_restore_${index}_${type}.log 2>&1
    fi
  done
done

exit 0
