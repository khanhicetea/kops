#!/bin/bash

CWD=$(dirname $(readlink $0))
BACKUP_DIR="$1"
TODAY=`date +%Y-%m-%d`
RM_DAY=`date --date="14 days ago" +%Y-%m-%d`
HOSTNAME=`hostname`
FILENAME=$HOSTNAME.$TODAY.sql.gz
RM_FILENAME=$HOSTNAME.$RM_DAY.sql.gz

BACKUP_DBS=$(echo "show databases" | mysql | grep -Ev "^(Database|mysql|performance_schema|information_schema)$")

mysqldump --opt --routines --compact --force --databases ${BACKUP_DBS} | gzip > $BACKUP_DIR/$FILENAME

/bin/bash $CWD/dropbox_uploader.sh upload "/$BACKUP_DIR/${FILENAME}" "${FILENAME}"
/bin/bash $CWD/dropbox_uploader.sh delete "${RM_FILENAME}"

rm -f "/$BACKUP_DIR/${FILENAME}"