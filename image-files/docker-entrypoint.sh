#!/bin/bash

# Update MySQL credentials (prevent MySQL warnings about CLI password usage)
CREDS=/root/mysql-credentials.cnf
echo "[client]" > $CREDS
echo "user=$DB_USER" >> $CREDS
echo "password=$DB_PASS" >> $CREDS
chmod 600 $CREDS

DOC_ROOT=/var/www/html

# Check and install majordomo, if necessary (only in cycles service)
if [[ $@ == "php cycle.php" ]] && [ ! -f "$DOC_ROOT/index.php" ]; then
	echo "MajorDoMo not found, installing from github..."
	cd /tmp
	git clone --depth=1 https://github.com/sergejey/majordomo.git
	cp -rfp /tmp/majordomo/* $DOC_ROOT/
	cp -fp /tmp/majordomo/.htaccess $DOC_ROOT/
	cp -fp /tmp/majordomo/config.php.sample $DOC_ROOT/config.php
	rm -rf /tmp/majordomo

	# Replace config values
	sed -i "/DB_HOST/s/'[^']*'/getenv('DB_HOST')/2" $DOC_ROOT/config.php
	sed -i "/DB_NAME/s/'[^']*'/getenv('DB_NAME')/2" $DOC_ROOT/config.php
	sed -i "/DB_USER/s/'[^']*'/getenv('DB_USER')/2" $DOC_ROOT/config.php
	sed -i "/DB_PASS/s/'[^']*'/getenv('DB_PASS')/2" $DOC_ROOT/config.php
	sed -i "s#/var/www#$DOC_ROOT#g" $DOC_ROOT/config.php

	# Create required folders for running scripts
	mkdir -p $DOC_ROOT/cached/voice
	mkdir -p $DOC_ROOT/cached/urls
	echo "cloned successfully."
	# Restore directory
	cd - > /dev/null

	# Check database tables
	if [ "$DB_HOST" != "" ] && [ "$DB_NAME" != "" ] && [ $DB_USER != "" ]; then
		max_tries=10;
		res=1;
		while [ $max_tries -gt 0 ] && [ $res -ne 0 ]; do
			tables=($(mysql --defaults-extra-file=$CREDS -h"${DB_HOST}" ${DB_NAME} -sse "show tables;"))
			res=$?
			if [ $res -eq 0 ]; then
				break
			fi
			echo "MySQL connection error, retrying... "
			(($max_tries--))
			sleep 1
		done

		if [ $max_tries -eq 0 ]; then
			echo "ERROR: Can't establish database connection"
		else
			if [ ${#tables[@]} -eq 0 ]; then
				echo -n "Database is empty, importing from db_terminal.sql..."
				# Fix database collation
				mysql --defaults-extra-file=$CREDS -h"${DB_HOST}" ${DB_NAME} -e \
					"ALTER DATABASE ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
				# Import DB dump
				mysql --defaults-extra-file=$CREDS -h"${DB_HOST}" ${DB_NAME} < $DOC_ROOT/db_terminal.sql
				# Some fixes on the imported data
				mysql --defaults-extra-file=$CREDS -h"${DB_HOST}" ${DB_NAME} -e \
					"DELETE FROM system_errors;"
				echo " done."
			else
				echo "Database is not empty - skipping db import"
			fi
		fi
	fi
fi

# Update server name on apache run
if [[ $@ == "apache2-foreground" ]]; then
	sed "s/ServerName.*/ServerName ${HOST_NAME}/g" -i /etc/apache2/apache2.conf
fi

# Fix permissions on each run
chown -R www-data:www-data $DOC_ROOT
chmod +x $DOC_ROOT/*.sh

# Execute the commands passed to this script
exec "$@"
