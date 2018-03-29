#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [[ $# -eq 0 ]] ; then
    echo 'No arguments supplied!'
    exit 1
fi
ENV=${1}
LIMIT=1000
# ensure dump utils are installed
if ! [ -x "$(command -v pg_dump)" ]; then
  echo 'Error: pg_dump is not installed.' >&2
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
BACKUP_FOLDER="${BACKUP_FOLDER}/$(date +%F)_${ENV}"

# define coyo index types and names
declare -a types=("data")
declare -a indexes=("comment" "event" "event-membership" "form-entry" "forum-thread" "forum-thread-answer" \
 "fulltext-content" "list-entry" "message" "message-channel" "message-channel-status" \
 "notification" "page" "search" "search-values-v2" "sender" "sender-role-principle" \
 "timeline-item" "user" "workspace")


# create backup folder
mkdir -p $BACKUP_FOLDER/es

# create pgpass for passwordless llogin
echo "*:*:${PG_DB}:${PG_USER}:${PG_PASS}" > ~/.pgpass
chmod 600 ~/.pgpass

pg_dump -w -h ${PG_HOST} -U ${PG_USER} ${PG_DB} | grep -vw "idle_in_transaction_session_timeout" | gzip > ${BACKUP_FOLDER}/pg_dump.sql.gz &
mongodump --host ${MONGO_HOST} --db ${MONGO_DB} --gzip --archive=${BACKUP_FOLDER}/mongo_dump.gz > logs/mongo_dump.log 2>&1 &
for type in "${types[@]}"; do
  for index in "${indexes[@]}"; do
    ./node_modules/elasticdump/bin/elasticdump --input=http://${ELASTIC_HOST}:9200/${index} --output=${BACKUP_FOLDER}/es/_${index}_${type}.json --type=${type} --limit=${LIMIT} > logs/elastic_dump.log 2>&1 &
  done
done

exit 0
