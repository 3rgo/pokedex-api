#!/bin/bash

# App name
APP_NAME="Pokedex API"
# Discord webhook URL (REPLACE WITH YOUR ACTUAL WEBHOOK URL)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1335252458800156722/3G5WTGkmUYECTWLeE0lUVTCG9o8J3WwARwUZ5UexMmQBsMVtZvOigdFUb8A5R26jblHj"
# Lock file path
LOCK_FILE="./deployment.lock"

send_discord_notification() {
    # Check if arguments are provided
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: $0 <message> <discord_webhook_url>" >&2
        exit 1
    fi

    local message="$1"
    local url="$2"

    local payload=$(cat <<EOF
{
    "content": "$message"
}
EOF
)
    curl -H "Content-Type: application/json" -X POST -d "$payload" "$url"
    if [[ $? -ne 0 ]]; then
        echo "Error sending Discord notification: $message" >&2
    fi
}

# Check for --force flag
force_deploy=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            force_deploy=true
            shift
            ;;
        *)
            break  # Break out of the loop if no more flags
            ;;
    esac
done

# Check for available commits on origin (unless --force is used)
if ! $force_deploy; then  # Only check if force_deploy is false
    if ! git fetch origin &>/dev/null || [[ -z "$(git log --oneline ..origin/master)" ]]; then
        echo "No new commits available. Exiting."
        exit 0
    fi
fi

# Deployment start time
start_time=$(date +%s)

# Create lock file with timestamp
echo "$start_time" > "$LOCK_FILE"

# Check if the function exists in .bashrc
if declare -f send_discord_notification &>/dev/null; then
    # Send Discord notification (deployment started)
    start_date=$(date '+%Y-%m-%d %H:%M:%S') # Portable date format
    send_discord_notification "**$APP_NAME** deployment started at $start_date" "$DISCORD_WEBHOOK_URL"
fi

# Deployment commands

# Enable maintenance mode
php artisan down

# Update code
git checkout -- .
git pull

# Install dependencies
composer install --no-dev --optimize-autoloader

# Reset file permissions
# sudo chown -R ubuntu:www-data .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R 775 storage bootstrap/cache

# Clear cache
php artisan optimize:clear

# Warm cache
php artisan config:cache
php artisan icons:cache
php artisan route:cache
php artisan view:cache

# Run migrations
php artisan migrate --force

# Disable maintenance mode
php artisan up

# Generate API doc
php artisan l5-swagger:generate

# Remove lock file
rm "$LOCK_FILE"

# Deployment end time
end_time=$(date +%s)

# Calculate duration
duration=$((end_time - start_time))

# Check if the function exists in .bashrc
if declare -f send_discord_notification &>/dev/null; then
    # Send Discord notification (deployment finished)
    end_date=$(date '+%Y-%m-%d %H:%M:%S') # Portable date format
    send_discord_notification "**$APP_NAME** deployment finished at $end_date (duration: ${duration} seconds)." "$DISCORD_WEBHOOK_URL"
fi

exit 0