# Tienda eSIM - imagen para Railway (PHP 8.3 + Apache)
FROM php:8.3-apache

RUN apt-get update \
 && apt-get install -y --no-install-recommends libpng-dev libjpeg62-turbo-dev libwebp-dev libfreetype6-dev \
 && docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
 && docker-php-ext-install -j"$(nproc)" pdo_mysql gd opcache \
 && rm -rf /var/lib/apt/lists/*
# (mbstring, curl, openssl, fileinfo, session, json y ctype ya vienen en la imagen oficial)

RUN a2enmod rewrite headers expires remoteip \
 && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker/php.ini "$PHP_INI_DIR/conf.d/zz-tienda.ini"
COPY docker/apache-tienda.conf /etc/apache2/sites-available/000-default.conf
COPY docker/entrypoint.sh /usr/local/bin/tienda-entrypoint
COPY . /var/www/html/
# Copias SIN punto de los .htaccess (GitHub/ZIP a veces omiten archivos ocultos). Se restauran aqui.
COPY docker/htaccess/ /opt/tienda-defaults/htaccess/

# Copia de los .htaccess de uploads para restaurarlos si se monta un Volume vacío encima
RUN set -e; H=/opt/tienda-defaults/htaccess; W=/var/www/html \
 && chmod +x /usr/local/bin/tienda-entrypoint \
 && mkdir -p $W/uploads/products $W/uploads/private/qr $W/api/_lib $W/config $W/cron $W/docs $W/sql \
 && cp $H/root.htaccess $W/.htaccess \
 && cp $H/api_lib.htaccess $W/api/_lib/.htaccess \
 && cp $H/config.htaccess $W/config/.htaccess \
 && cp $H/cron.htaccess $W/cron/.htaccess \
 && cp $H/docs.htaccess $W/docs/.htaccess \
 && cp $H/sql.htaccess $W/sql/.htaccess \
 && cp $H/uploads.htaccess $W/uploads/.htaccess \
 && cp $H/uploads_private.htaccess $W/uploads/private/.htaccess \
 && : > $W/uploads/private/qr/index.html \
 && rm -rf $W/docker $W/Dockerfile $W/.dockerignore $W/railway.json \
 && chown -R root:root $W \
 && chown -R www-data:www-data $W/uploads $W/config \
 && find $W -type d -exec chmod 755 {} + \
 && find $W -type f -exec chmod 644 {} +

ENV PORT=8080 APACHE_DOCUMENT_ROOT=/var/www/html
EXPOSE 8080
ENTRYPOINT ["tienda-entrypoint"]
CMD ["apache2-foreground"]
