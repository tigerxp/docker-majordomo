FROM php:7.1-apache

ENV HOST_NAME majordomo.localhost

# Configure Apache
RUN set -ex; \
	echo "ServerName $HOST_NAME" >> /etc/apache2/apache2.conf; \
	a2enmod rewrite

# Install necessary packages and PHP extensions
RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends --no-install-suggests \
		git mysql-client ca-certificates inetutils-ping \
	; \
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get install -y --no-install-recommends --no-install-suggests \
		libedit-dev \
	; \
	\
	docker-php-ext-install mysqli opcache sockets readline; \
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
	apt-get clean ; \
	rm -rf /var/lib/apt/lists/*

# Docker stuff
COPY ./image-files/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

WORKDIR /var/www/html

EXPOSE 80
VOLUME ["/var/www/html"]
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
