# https://www.xoops.org/
FROM php:7.3-rc-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
		zlib1g-dev libicu-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
		intl \
	; \
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

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

# https://github.com/XOOPS/XoopsCore25/releases
# ENV XOOPS_VERSION v2.5.9
ENV XOOPS_VERSION mysql8

RUN apt-get update \
    && apt-get install -y git nano wget unzip libpng-dev libjpeg-progs libvpx-dev \
    && docker-php-ext-install mysqli gd exif \
    && apt-get clean all \
	&& git clone --branch ${XOOPS_VERSION} --depth 1 https://github.com/geekwright/XoopsCore25.git \
    && mv XoopsCore25/htdocs/* . \
    && rm -rf XoopsCore25 \
    && chown -R www-data:www-data . \
    && chmod -R 755 /var/www/html \
    && mv /var/www/html/xoops_lib /var/www/ \
    && mv /var/www/html/xoops_data /var/www/ \
    && chmod -R 755 /var/www/xoops_data

EXPOSE 80 443
CMD ["apache2-foreground"]
