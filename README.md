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
cat > /etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/3.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc
EOF
yum makecache
yum update -y
yum install -y epel-release
yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
yum install -y nodejs git gzip curl mongodb-org-tools postgresql96
git clone https://github.com/ruslantum/coyo4-backup
cd coyo4-backup
npm install elasticdump
```

## Usage

```bash
./backup.sh ENV
./restore.sh ENV BACKUP_DATE (YYYY-MM-DD)
```

## Config

Save config in the same folder as ${ENV}.properties file:
```bash
cp properties_example ${ENV}.properties
```
### Backup Folder
* BACKUP_FOLDER: Configure where to save Coyo backups

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

### Backend

* BACKEND_HOST: Coyo-Backend Host
* BACKEND_USER: Coyo-Backend Management User
* BACKEND_PASS: Coyo-Backend Management Password
