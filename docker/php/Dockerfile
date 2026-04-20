FROM php:8.4-fpm-alpine

# Install system dependencies for PHP extensions and build tools for PECL extensions
RUN apk --no-cache add \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libzip-dev \
    zlib-dev \
    curl-dev \
    bash \
    git \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    inotify-tools \
    $PHPIZE_DEPS

# Install Redis extension via PECL and enable it
RUN pecl install redis \
    && docker-php-ext-enable redis

# Remove build dependencies to keep image small
RUN apk del $PHPIZE_DEPS

# Install required PHP extensions
RUN docker-php-ext-configure gd --with-jpeg --with-webp && \
    docker-php-ext-install gd mysqli pdo pdo_mysql zip intl opcache mbstring xml

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable OPCache
RUN docker-php-ext-enable opcache

# Set working directory
WORKDIR /var/www/backend

# Copy the backend directory into the container
COPY ./backend /var/www/backend

# Ensure the permissions are set correctly
RUN chown -R www-data:www-data /var/www/backend

# Copy in custom php.ini and www.conf
COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/
COPY ./docker/php/www.conf /usr/local/etc/php-fpm.d/

# Ensure the PHP session directory exists
RUN mkdir -p /var/lib/php/sessions && chown -R www-data:www-data /var/lib/php/sessions

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
