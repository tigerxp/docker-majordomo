FROM php:7.1-apache

RUN a2enmod rewrite

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends --no-install-suggests \
        git mysql-client ca-certificates inetutils-ping \
		libedit-dev \
	; \
	\
	docker-php-ext-install mysqli opcache readline; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# ENV HOST_NAME majordomo.localhost

# RUN set -eux; \
# 	apt-get update; \
# 	apt-get install --no-install-recommends --no-install-suggests -y \
#     curl libcurl3 libcurl3-dev \
#     php php-cgi php-cli php-pear php-mysql php-mbstring php-xml php-curl php-opcache php-readline \
#     apache2 apache2-utils libapache2-mod-php \
#     mysql-client \
#     git ca-certificates inetutils-ping supervisor; \
#     apt-get clean; \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# COPY ./files/vhost.conf /etc/apache2/sites-available/000-default.conf
# RUN set -eux; \
#     echo "ServerName $HOST_NAME" >> /etc/apache2/apache2.conf; \
#     a2enmod rewrite

# # Configure PHP and Supervisor
# COPY ./files/configure-php.sh /
# RUN set -eux; \
#     chmod +x /configure-php.sh; \
#     /configure-php.sh; \
#     rm -f /configure-php.sh
# COPY ./files/supervisor.conf /etc/supervisor/conf.d/majordomo.conf

# # Docker stuff
COPY ./files/docker-entrypoint.sh /
# COPY ./files/run.sh /
RUN chmod +x /docker-entrypoint.sh 
# /run.sh
EXPOSE 80
VOLUME ["/var/www/html"]
WORKDIR /var/www/html
ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD ["/run.sh"]

COPY app/ /var/www/html/
CMD ["apache2-foreground"]
