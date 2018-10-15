#!/bin/bash

if [ -z "$1" ]
then
    echo "Please input backup dir : [backup_dir]"
    exit 1
fi

if [ -z "$3" ]
then
    BACKUP_DBS=$(echo "show databases" | mysql | grep -Ev "^(Database|mysql|performance_schema|information_schema|sys)$")
else
    BACKUP_DBS="$3"
fi

UPLOAD_DIR="$2"
KEEP_DAYS="$4"
CWD=$(dirname $0)
BACKUP_DIR="$1"
TODAY=`date +%Y-%m-%d`
BKTIME=`date +%H_%M`
RM_DAY=`date --date="$KEEP_DAYS days ago" +%Y-%m-%d`
FILENAME=$BKTIME.sql.gz

echo "Backup database in $TODAY ...."
mysqldump --opt --routines --compact --force --databases ${BACKUP_DBS} | gzip > $BACKUP_DIR/$FILENAME

echo "Uploading to Dropbox ...."
/bin/bash $CWD/dropbox_uploader.sh upload "/${BACKUP_DIR}/${FILENAME}" "${UPLOAD_DIR}${TODAY}/${FILENAME}"
/bin/bash $CWD/dropbox_uploader.sh delete "${UPLOAD_DIR}${RM_DAY}"

echo "Cleaning ..."
rm -f "/$BACKUP_DIR/${FILENAME}"
