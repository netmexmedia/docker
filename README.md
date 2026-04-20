# docker
Plug and play Docker environment for Laravel & Symfony development

---

## Overview

This repository provides a small, developer-focused Docker environment tailored for Laravel and Symfony applications. It includes a PHP-FPM container (custom PHP image), Nginx, MySQL (5.7), phpMyAdmin, MailHog, and Redis. The stack is designed to be opinionated but lightweight: PHP runs in a dedicated container, your application code is bind-mounted from `./backend`, and Nginx proxies requests to PHP-FPM.

Use this repository as a starting point for local development, experimentation, or CI-friendly workflows.

## Features

- PHP 8.4 FPM (Alpine-based) with common extensions preinstalled (gd, pdo_mysql, intl, mbstring, opcache, redis via PECL)
- Nginx (1.19.2-alpine) as the HTTP reverse-proxy
- MySQL 5.7 with a persisted volume
- phpMyAdmin for quick DB access
- MailHog for catching outgoing mail during development
- Redis (7-alpine)
- Customizable PHP configuration: `docker/php/php.ini` and `docker/php/www.conf`
- Entrypoint script that installs Composer deps and clears Symfony cache when appropriate

## Quickstart (tested with Docker 24.x & Docker Compose v2)

Prerequisites:

- Docker (recommend latest stable; tested with Docker 24.x)
- Docker Compose (v2 or `docker compose` built into Docker)

Bringing the stack up:

```bash
# Build images and start containers in the background
docker compose up -d --build

# View logs
docker compose logs -f
```

Common tasks (run these from the repo root):

```bash
# Install Composer dependencies inside the php container
docker compose exec php composer install --no-interaction

# For Laravel: run artisan migrations
docker compose exec php php artisan migrate --force

# For Symfony: run doctrine migrations (if using migrations)
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction

# Run tests inside container (example)
docker compose exec php ./vendor/bin/phpunit
```

If you change PHP extensions or the PHP Dockerfile, rebuild the image:

```bash
docker compose build php
```

## Services & Access

The docker-compose configuration maps the container ports to the host as follows (defaults):

- App (Nginx): http://localhost:80
- phpMyAdmin: http://localhost:81 (connect to host `mysql`, root password `root`)
- MailHog UI: http://localhost:85
- MySQL: host `localhost:3306` (or use `mysql:3306` within containers)
- Redis: host `localhost:6379` (or `redis:6379` within containers)

Notes:
- Your application code is mounted at `./backend` -> `/var/www/backend` inside the `php` and `nginx` containers. The Nginx root is configured to `/var/www/backend/public` (Laravel) or `/var/www/backend/public` (Symfony Flex default).
- The `php` container exposes FPM on port 9000 internally and Nginx forwards to `php:9000`.

## PHP configuration & custom files

- `docker/php/Dockerfile`: custom PHP build (Alpine) with common extensions and Composer installed globally.
- `docker/php/php.ini`: custom PHP settings loaded into the container.
- `docker/php/www.conf`: custom PHP-FPM pool configuration used by the container.
- `entrypoint.sh`: runs on container start to install Composer deps (if `composer.json` exists), clear Symfony cache (if `bin/console` exists), and start PHP-FPM.

If you need to tweak php.ini or www.conf, edit the files in `docker/php/` and rebuild the `php` image:

```bash
docker compose build php
```

## Environment variables (example)

Inside your application `.env` (examples for Laravel):

```
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=db_backend
DB_USERNAME=db_user
DB_PASSWORD=db_password

MAIL_MAILER=smtp
MAIL_HOST=mail
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

REDIS_HOST=redis
REDIS_PORT=6379
```

For Symfony (example parameters):

```
DATABASE_URL=mysql://db_user:db_password@mysql:3306/db_backend
MAILER_DSN=smtp://mail:1025
```

Notes: When working from your host (outside containers) you can connect to MySQL at `localhost:3306` and phpMyAdmin at `http://localhost:81`.

## Volumes & persisted data

- `mysql_data` holds MySQL data and is declared in `docker-compose.yml`.
- Application files are bind-mounted from `./backend` so code changes are immediate.
- There's a `mercure_data` volume declared but no mercure service is present by default; see "Mercure / Caddy" below.

## Mercure / Caddy

This repo includes a sample `docker/mercure/Caddyfile` that demonstrates a Caddy reverse-proxy with permissive CORS headers for a Mercure hub running on `localhost:86`. The `docker-compose.yml` does not currently include a Mercure service by default — if you need Mercure, add an appropriate service and mount/use the Caddyfile provided.

## Common gotchas & troubleshooting

- 502 Bad Gateway from Nginx: Usually means PHP-FPM not reachable. Check `docker compose logs php` and `docker compose ps`. Ensure the `php` container is healthy and listening on 9000.

- File permissions / storage: If your framework cannot write to `storage`/`var` directories, ensure the container user has ownership. The Dockerfile sets ownership to `www-data:www-data` for `/var/www/backend`. You can fix host permissions with:

```bash
sudo chown -R $UID:$GID backend
```

- Rebuild after Dockerfile changes: `docker compose build php` then `docker compose up -d`.

- Composer memory issues: Run composer inside the php container rather than on the host to use the container's PHP config: `docker compose exec php composer install`.

- DB connection refused: From the host use `localhost:3306`. From containers use `mysql:3306` as DB host.

- phpMyAdmin login: use host `mysql` (or `localhost` if you configure it that way), root password `root` (from compose env).

## How to add or change services

- Nginx: edit `docker/nginx/default.conf` and reload the container (or restart): `docker compose restart nginx`.
- PHP: edit `docker/php/Dockerfile`, `docker/php/php.ini`, or `docker/php/www.conf`, then rebuild: `docker compose build php`.
- MySQL: to persist different DB data, change/create a new named volume and update `docker-compose.yml`.

If you add services that applications depend on, update your app `.env` to point to the service name (Docker Compose DNS): e.g., `DB_HOST=mysql`, `REDIS_HOST=redis`.

## Development tips

- Use `docker compose exec php sh` or `docker compose exec php bash` to open a shell inside the PHP container (Alpine uses `sh` by default).
- Use `docker compose logs -f <service>` to tail logs during development.
- When running front-end tooling (npm/yarn), either run it on the host or add a `node` service in the Compose stack.

## Suggested next steps / improvements

A few small improvements you might consider:

- Add a `Makefile` or `composer` scripts to simplify common commands (up, down, rebuild, shell, etc.).
- Add healthchecks to services in `docker-compose.yml` to improve startup ordering and reliability.
- Provide an `.env.example` at the repo root with the environment variables shown above.
- Add a CI workflow that builds the `php` image and runs your test suite.
- Consider migrating to Docker Compose v2+ file format and using Compose profiles if you need optional services.
- Secure secrets using Docker secrets or environment variable management for non-dev use.

## Contributing

Contributions are welcome. Please open issues or PRs for fixes or improvements. Keep changes small and focused. If adding services, update this README and add examples for `.env` values.

## License

This repository does not include a license file. If you want to open source it, consider adding an MIT `LICENSE`.

---

If you'd like, I can:

- Switch the README tone to be Laravel-first or Symfony-first and add specific commands and examples for one framework.
- Add an `.env.example` file with the variables shown above.
- Add a small `Makefile` with common convenience targets.

Tell me which you'd like next and I'll add it.
