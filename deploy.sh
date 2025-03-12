#!/bin/bash

# App name and Discord webhook URL
APP_NAME="Pokedex API"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1335252458800156722/3G5WTGkmUYECTWLeE0lUVTCG9o8J3WwARwUZ5UexMmQBsMVtZvOigdFUb8A5R26jblHj"
LOCK_FILE="./deployment.lock"

# Find PHP CLI binary matching the CGI version
find_php_cli() {
    local cgi_version=$(/usr/bin/php -r 'echo PHP_VERSION;' 2>/dev/null)
    echo "CGI PHP version: $cgi_version"

    # Search for matching CLI PHP
    for path in /opt/cpanel/ea-php*/root/usr/bin/php /opt/alt/php*/usr/bin/php /usr/bin/php*; do
        if [ -f "$path" ] && $path -r 'echo php_sapi_name();' 2>/dev/null | grep -q "cli"; then
            if [ "$($path -r 'echo PHP_VERSION;' 2>/dev/null)" = "$cgi_version" ]; then
                echo "$path"
                return 0
            fi
        fi
    done

    # Fallback to any CLI PHP
    for path in /opt/cpanel/ea-php*/root/usr/bin/php /opt/alt/php*/usr/bin/php /usr/bin/php*; do
        if [ -f "$path" ] && $path -r 'echo php_sapi_name();' 2>/dev/null | grep -q "cli"; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Send Discord notification
send_discord_notification() {
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$1\"}" "$2"
}

# Main deployment function
deploy() {
    # Find PHP CLI binary
    PHP_BIN=$(find_php_cli)
    if [ -z "$PHP_BIN" ]; then
        echo "Error: Cannot find PHP CLI binary"
        return 1
    fi

    echo "Using PHP: $PHP_BIN ($(PHP_BIN -r 'echo php_sapi_name();'))"

    # Record start time
    start_time=$(date +%s)
    echo "$start_time" > "$LOCK_FILE"
    start_date=$(date '+%Y-%m-%d %H:%M:%S')
    send_discord_notification "**$APP_NAME** deployment started at $start_date" "$DISCORD_WEBHOOK_URL"

    # Deployment steps
    $PHP_BIN artisan down --render="errors::503" --retry=15 --refresh=15

    git checkout -- .
    git pull

    $PHP_BIN $(which composer) install --no-dev --optimize-autoloader
    npm ci
    npm run build

    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    chmod -R 775 storage bootstrap/cache

    $PHP_BIN artisan optimize:clear
    $PHP_BIN artisan config:cache
    $PHP_BIN artisan route:cache
    $PHP_BIN artisan view:cache
    $PHP_BIN artisan migrate --force
    $PHP_BIN artisan up
    $PHP_BIN artisan l5-swagger:generate

    # Clean up and notify
    rm "$LOCK_FILE"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    end_date=$(date '+%Y-%m-%d %H:%M:%S')
    send_discord_notification "**$APP_NAME** deployment finished at $end_date (duration: ${duration} seconds)" "$DISCORD_WEBHOOK_URL"

    return 0
}

# Check if we should deploy
if [ "$1" = "--force" ] || git fetch origin && [ -n "$(git log --oneline ..origin/master)" ]; then
    deploy
fi

exit 0