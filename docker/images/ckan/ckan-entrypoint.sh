#!/bin/bash

set -u

check_port() {
    local host="$1"
    local port="$2"

    echo "Checking service availability at ${host}:${port}..."

    while true; do
        # Use nmap to scan the specified port on the given host
        nmap -p "${port}" "${host}" | grep -q "open"

        # If the port is open, exit the loop
        if [ $? -eq 0 ]; then
            echo "Server is available at ${host}:${port}"
            break
        else
            echo "Server at ${host}:${port} is not available. Retrying in 1 seconds..."
            sleep 1
        fi
    done
}

## Check DB up
check_port db 5432

## Check Solr up
check_port solr 8983

## Check Redis up
check_port redis 6379

## Initialize CKAN config, database and admin account
CKAN_CONFIG_FILE=/etc/ckan/default/ckan.ini
CKAN_UWSGI_CONFIG_FILE=/etc/ckan/default/ckan-uwsgi.ini
CKAN_INIT_STATUS_FILE=/etc/ckan/default/.ckan_initialized

if [ "$LEXCES_CATALOG_HOST_PORT" = "443" ]
then export CKAN_SITE_URL="https://$LEXCES_CATALOG_HOST"
else export CKAN_SITE_URL="https://$LEXCES_CATALOG_HOST:$LEXCES_CATALOG_HOST_PORT"
fi

if test -f "$CKAN_INIT_STATUS_FILE"
then echo "Configuration and database already initialized."
else echo "Initializing configuration ..."
     ## TODO replace this
     export SECRET_TOKEN_VALUE=$(openssl rand -base64 32)
     export APP_INSTANCE_UUID=$(uuidgen --name "$LEXCES_CATALOG_HOST" --namespace "@url" --sha1)
     perl -pi.bak -e '$secret_token=$ENV{SECRET_TOKEN_VALUE}; s/SECRET_TOKEN_VALUE/$secret_token/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$app_instance_uuid=$ENV{APP_INSTANCE_UUID}; s/APP_INSTANCE_UUID/$app_instance_uuid/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$ckan_database_password=$ENV{CKAN_DATABASE_PASSWORD}; s/CKAN_DATABASE_PASSWORD/$ckan_database_password/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$ckan_site_url=$ENV{CKAN_SITE_URL}; s/CKAN_SITE_URL/$ckan_site_url/ge' "$CKAN_CONFIG_FILE"

     echo "Initializing database ..."
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" db init
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" user add ckanadmin password="$CKAN_ADMIN_PASSWORD" email=ckanadmin@localhost name=ckanadmin
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" sysadmin add ckanadmin
     sudo chown -R www-data:www-data "$CKAN_STORAGE_PATH"
     touch "$CKAN_INIT_STATUS_FILE"
     echo "Configuration and database initialization finished."
fi

## Start CKAN
echo "Starting CKAN ..."
while true
do /usr/lib/ckan/default/bin/uwsgi -i /etc/ckan/default/ckan-uwsgi.ini
   sleep 1
   echo "CKAN process terminated; trying to restart ..."
done
