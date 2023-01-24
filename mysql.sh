#!/usr/bin/env bash

# Commands:
#
# dump
# dump-all
# restore - Restores database from the file.
# restore-all - Restores all databases from the file.
# shell
#
# MYSQL_USER='$MYSQL_USER' MYSQL_PASSWORD='$MYSQL_PASSWORD' ./mysql.sh shell


makeCredentials()
{
    local rootPasswordVar='MYSQL_ROOT_PASSWORD_FILE' # '%%ROOT_PASSWORD_VAR%%'
    local userPasswordVar='MYSQL_PASSWORD_FILE' # '%%USER_PASSWORD_VAR%%'
    local user="${MYSQL_USER:-\$MYSQL_USER}"
    
    if [[ "$user" == 'root' ]]; then
        local default="$(passwordValue "$rootPasswordVar")"
    else
        local default="$(passwordValue "$userPasswordVar")"
    fi
    
    local password="${MYSQL_PASSWORD:-$default}"

    echo "-u\"$user\" -p\"$password\""
}


passwordValue()
{
    if [[ "$1" == *_FILE ]]; then
        echo "\$(cat \$$1)"
    else
        echo "\$$1"
    fi
}


restore()
{
    local input="$1"
    local db="$2"
    local args="$CREDENTIALS"
    
    if [[ -z $input ]]; then
        echo "Usage $0 restore FILE" >&2
        echo "Usage $0 restore-db FILE [DB]" >&2
        exit 1
    fi
    
    if [[ ! -z $db ]]; then
        args+=" -D $db"
    fi
    
    docker compose exec -T "$SERVICE_NAME" \
        sh -c "exec mysql $args" < "$input"
}


# SERVICE_NAME='%%SERVICE_NAME%%'
# DATE_FORMAT='%%DATE_FORMAT%%'

SERVICE_NAME='mysql'
DATE_FORMAT='%F_%k%M%S'
CREDENTIALS="$(makeCredentials)"


case "$1" in
    'dump')
        databases=${@:3:$#}
        output="${2:-.}/$(date -u +$DATE_FORMAT)"
        args="$CREDENTIALS"
        
        if [[ -z $databases ]]; then
            output+="_full.sql"
            args+=' --all-databases'
        else
            output+="_(${databases// /,}).sql"
            args+=" --databases $databases"
        fi
        
        echo "Save the databases dump to an $output"

        docker compose exec "$SERVICE_NAME" \
            sh -c "exec mysqldump $args" > "$output"
        ;;
    'dump-db')
        db="${3:-\$MYSQL_DATABASE}"
        output="${2:-.}/$(date -u +$DATE_FORMAT)_(${3:-default}).sql"
        echo "Save the databases dump to an $output"
        docker compose exec "$SERVICE_NAME" \
            sh -c "exec mysqldump $CREDENTIALS \"$db\"" > "$output"
        ;;
    'restore-db')
        restore "$2" "${3:-\$MYSQL_DATABASE}" ;;
    'restore')
        restore "$2" ;;
    'shell')
        docker compose exec "$SERVICE_NAME" \
            sh -c "exec mysql $CREDENTIALS -D \"$MYSQL_DATABASE\""
        ;;
    *)
        echo "Usage: $0 {dump,dump-db,restore,restore-db,shell}" >&2
        exit 1
esac
