#!/bin/bash

# Based on https://github.com/dimitrystd/docker-majordomo/blob/master/docker/files/configure-php.sh

mkdir -p /etc/php/7.0/conf-available

# set recommended PHP.ini settings
{ \
echo 'opcache.memory_consumption=128'; \
echo 'opcache.interned_strings_buffer=8'; \
echo 'opcache.max_accelerated_files=4000'; \
echo 'opcache.revalidate_freq=60'; \
echo 'opcache.fast_shutdown=1'; \
echo 'opcache.enable_cli=1'; \
} > /etc/php/7.0/conf-available/opcache-recommended.ini

# enable php logging
mkdir -p /var/log/php
touch /var/log/php/php_error.log
chown www-data:www-data /var/log/php/php_error.log
chmod +rw /var/log/php/php_error.log
{ \
echo 'error_log=/var/log/php/php_error.log'; \
echo 'log_errors=true'; \
echo 'log_errors_max_len=0'; \
echo 'error_reporting=E_ALL & ~E_NOTICE'; \
echo 'display_errors=stdout'; \
echo 'display_startup_errors=true'; \
} > /etc/php/7.0/conf-available/logging.ini

# majordomo recommended settings
{ \
echo 'short_open_tag=On'; \
echo 'max_execution_time=90'; \
echo 'max_input_time=180'; \
echo 'post_max_size=200M'; \
echo 'upload_max_filesize=50M'; \
echo 'max_file_uploads=150'; \
echo 'date.timezone=Europe/Kiev'; \
} > /etc/php/7.0/conf-available/majordomo.ini

ln -s /etc/php/7.0/conf-available/opcache-recommended.ini /etc/php/7.0/cli/conf.d/50-opcache-recommended.ini
ln -s /etc/php/7.0/conf-available/opcache-recommended.ini /etc/php/7.0/apache2/conf.d/50-opcache-recommended.ini
ln -s /etc/php/7.0/conf-available/logging.ini /etc/php/7.0/cli/conf.d/50-logging.ini
ln -s /etc/php/7.0/conf-available/logging.ini /etc/php/7.0/apache2/conf.d/50-logging.ini
ln -s /etc/php/7.0/conf-available/majordomo.ini /etc/php/7.0/cli/conf.d/50-majordomo.ini
ln -s /etc/php/7.0/conf-available/majordomo.ini /etc/php/7.0/apache2/conf.d/50-majordomo.ini
