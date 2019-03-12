#!/bin/sh

# Start Supervisor
/usr/bin/supervisord -n -c /etc/supervisor/conf.d/majordomo.conf

# Expose logs
tail -f /var/log/apache2/error.log /var/log/php/* /var/www/html/cms/debmes/*
