#!/bin/bash

# App name and Discord webhook URL
APP_NAME="3rgo.tech"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1335252458800156722/3G5WTGkmUYECTWLeE0lUVTCG9o8J3WwARwUZ5UexMmQBsMVtZvOigdFUb8A5R26jblHj"
LOCK_FILE="./deployment.lock"
BRANCH="master"

# Find a matching CLI PHP binary
PHP_BIN=""
CGI_PHP_VERSION=$(/usr/bin/php -r 'echo PHP_VERSION;' 2>/dev/null)

# Search for matching CLI PHP binary
for path in /opt/cpanel/ea-php*/root/usr/bin/php /opt/alt/php*/usr/bin/php /usr/local/bin/php* /usr/bin/php*; do
    if [ -f "$path" ] && $path -r 'echo php_sapi_name();' 2>/dev/null | grep -q "cli"; then
        VERSION=$($path -r 'echo PHP_VERSION;' 2>/dev/null)
        if [ "$VERSION" = "$CGI_PHP_VERSION" ]; then
            PHP_BIN="$path"
            break
        fi
    fi
done

# Fallback to any PHP CLI binary
if [ -z "$PHP_BIN" ]; then
    for path in /opt/cpanel/ea-php*/root/usr/bin/php /opt/alt/php*/usr/bin/php /usr/local/bin/php* /usr/bin/php*; do
        if [ -f "$path" ] && $path -r 'echo php_sapi_name();' 2>/dev/null | grep -q "cli"; then
            PHP_BIN="$path"
            break
        fi
    done
fi

# Exit if no PHP CLI binary found
if [ -z "$PHP_BIN" ]; then
    echo "Error: Cannot find PHP CLI binary" >&2
    exit 1
fi

# Use full path to other executables
COMPOSER_BIN=$(which composer)
NPM_BIN=$(which npm)
GIT_BIN=$(which git)

# Send Discord notification
send_discord_notification() {
    curl -s -H "Content-Type: application/json" -X POST -d "{\"content\": \"$1\"}" "$2" > /dev/null
}

# Main deployment function
deploy() {
    # Record start time
    start_time=$(date +%s)
    echo "$start_time" > "$LOCK_FILE"
    send_discord_notification "**$APP_NAME** deployment started" "$DISCORD_WEBHOOK_URL"

    # Deployment steps
    $PHP_BIN artisan down --render="errors::503" --retry=15 --refresh=15

    $GIT_BIN checkout -- .
    $GIT_BIN pull

    $PHP_BIN $COMPOSER_BIN install --no-dev --optimize-autoloader
    $NPM_BIN ci
    $NPM_BIN run build --silent

    find . -type d -exec chmod 755 {} \; 2>/dev/null
    find . -type f -exec chmod 644 {} \; 2>/dev/null
    chmod -R 775 storage bootstrap/cache 2>/dev/null

    $PHP_BIN artisan optimize:clear
    $PHP_BIN artisan config:cache
    # $PHP_BIN artisan icons:cache
    $PHP_BIN artisan route:cache
    $PHP_BIN artisan view:cache
    $PHP_BIN artisan migrate --force
    $PHP_BIN artisan up
    # $PHP_BIN artisan sitemap:generate
    $PHP_BIN artisan l5-swagger:generate

    # Clean up and notify
    rm "$LOCK_FILE"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    send_discord_notification "**$APP_NAME** deployment finished (duration: ${duration} seconds)" "$DISCORD_WEBHOOK_URL"
}

# Check if we should deploy
if [ "$1" = "--force" ] || { $GIT_BIN fetch -q origin && [ -n "$($GIT_BIN log --oneline ..origin/$BRANCH)" ]; }; then
    deploy
fi

exit 0