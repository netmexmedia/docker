#!/bin/sh

# Install required packages
apt-get update
apt-get install -y libpq-dev libzip-dev zip

# Install PHP extensions
docker-php-ext-install pdo pdo_mysql pdo_pgsql

# Install Composer dependencies if composer.json is present
if [ -f "composer.json" ]; then
  echo "Installing Composer dependencies..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Clear Symfony cache if bin/console is present
if [ -f "bin/console" ]; then
  echo "Clearing Symfony cache..."
  php bin/console cache:clear --no-warmup
fi

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm
