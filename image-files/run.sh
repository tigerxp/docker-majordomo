#!/bin/sh

# Start Supervisor
/usr/bin/supervisord -n \
    -c /etc/supervisor/conf.d/majordomo.conf \
    -j /var/run/supervisord.pid \
    -l /var/log/supervisord.log

# Expose logs
tail -f /var/log/apache2/error.log /var/log/php/* /var/www/html/cms/debmes/*
