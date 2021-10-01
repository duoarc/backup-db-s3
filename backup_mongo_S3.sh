#!/bin/sh

# Make sure to:
# 1) Name this file `backup.sh` and place it in /home/ubuntu
# 2) Run sudo apt-get install awscli to install the AWSCLI
# 3) Run aws configure (enter s3-authorized IAM user and specify region)
# 4) Fill in DB host + name and fill in correct linux user
# 5) Create S3 bucket for the backups and fill it in below (set a lifecycle rule to expire files older than X days in the bucket)
# 6) Run chmod +x backup.sh
# 7) Test it out via ./backup.sh
# 8) Set up a daily backup at midnight via `crontab -e`:
#    0 0 * * * /home/ubuntu/backup.sh > /home/ubuntu/backup.log

# DB host (secondary preferred as to avoid impacting primary performance)
HOST=api.zuri.chat

# DB name
DBNAME=zurichat

# S3 bucket name
BUCKET=zuri_mongo_backup

# Linux user account
USER=$USER

# Current time
TIME=`/bin/date +%d-%m-%Y-%T`

# Backup temporary directory
DEST=/home/$USER/tmp

# Local Backup directory
BACKUP=/var/local/mongodb/backup/

# Tar file of backup directory
TAR=$DEST/mongo_backup/$TIME.tar

# Create temp backup dir (-p to avoid warning if already exists)
sudo /bin/mkdir -p $DEST

# Create backup dir
sudo /bin/mkdir -p $BACKUP

# Log
echo "Backing up $HOST/$DBNAME to s3://$BUCKET/ on $TIME";

# Dump from mongodb host into backup directory
/usr/bin/mongodump -h $HOST -d $DBNAME -o $DEST

# Create tar of backup directory
/bin/tar cvf $TAR -C $DEST .

# Upload tar to s3
/usr/bin/aws s3 cp $TAR s3://$BUCKET/

# Move tar file to local backup
/bin/mv $TAR $BACKUP

# Remove tar file
/bin/rm -f $TAR

# Remove temporary backup directory
/bin/rm -rf $DEST

# All done
echo "Backup available at https://s3.amazonaws.com/$BUCKET/$TIME.tar"
