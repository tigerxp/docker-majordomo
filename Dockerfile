FROM debian:stretch-slim

ENV HOST_NAME majordomo.localhost

RUN set -eux; \
	apt-get update; \
	apt-get install --no-install-recommends --no-install-suggests -y \
    curl libcurl3 libcurl3-dev \
    php php-cgi php-cli php-pear php-mysql php-mbstring php-xml php-curl php-opcache php-readline \
    apache2 apache2-utils libapache2-mod-php \
    mysql-client \
    git ca-certificates inetutils-ping supervisor; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./files/vhost.conf /etc/apache2/sites-available/000-default.conf
RUN set -eux; \
    echo "ServerName $HOST_NAME" >> /etc/apache2/apache2.conf; \
    a2enmod rewrite

# Configure PHP and Supervisor
COPY ./files/configure-php.sh /
RUN set -eux; \
    chmod +x /configure-php.sh; \
    /configure-php.sh; \
    rm -f /configure-php.sh
COPY ./files/supervisor.conf /etc/supervisor/conf.d/majordomo.conf

# Docker stuff
COPY ./files/docker-entrypoint.sh /
COPY ./files/run.sh /
RUN chmod +x /docker-entrypoint.sh /run.sh
EXPOSE 80
VOLUME ["/var/www/html"]
WORKDIR /var/www/html
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/run.sh"]
