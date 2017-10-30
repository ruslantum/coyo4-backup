# Coyo4 Backup Bash Script

## Dependencies

* gzip
* npm
* curl
* git
* [pg_dump](https://www.postgresql.org/docs/9.6/static/app-pgdump.html)
* pg_restore
* [mongodump](https://docs.mongodb.com/manual/tutorial/backup-and-restore-tools/)
* mongorestore
* [elasticdump](https://github.com/taskrabbit/elasticsearch-dump#installing)

## Install dependencies on CentOS 7

```bash
yum install -y npm git gzip curl mongodb-org-tools.x86_64
yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
yum install -y postgresql96
git clone https://github.com/ruslantum/coyo4-backup
cd coyo4-backup
npm install elasticdump
```

## Usage

./backup.sh ENV
./restore.sh ENV BACKUP_FOLDER

## Config

Save config in the same folder as ${ENV}.properties file:
```bash
cp properties_example ${ENV}.properties
```

### Postgres

* PG_HOST: Postgres Host
* PG_USER: Postgres User
* PG_PASS: Postgres Password
* PG_DB: Postgres Database

### MongoDB

* MONGO_HOST: MongoDB Host
* MONGO_DB: MongoDB Database

### Elasticsearch

* ELASTIC_HOST: Elasticsearch Host
