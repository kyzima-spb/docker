#!/usr/bin/env bash


SERVICE_NAME='mongodb'


now()
{
    date +"%s"
}


case "$1" in
    'dump')
        db="${3:-\$MONGO_INITDB_DATABASE}"
        output="${2:-.}/${3:-default}_$(now).gz"
        echo "Save the '$db' database dump to an $output"
        docker compose exec "$SERVICE_NAME" \
            sh -c "exec mongodump \
                -u \"\$MONGO_INITDB_ROOT_USERNAME\" \
                -p \"\$MONGO_INITDB_ROOT_PASSWORD\" \
                --authenticationDatabase admin \
                -d \"$db\" \
                --dumpDbUsersAndRoles \
                --gzip \
                --archive \
            " > "$output"
        ;;
    'dump-all')
        output="${2:-.}/full_$(now).gz"
        echo "Save full dump to an $output"
        docker compose exec "$SERVICE_NAME" \
            sh -c 'exec mongodump \
                -u "$MONGO_INITDB_ROOT_USERNAME" \
                -p "$MONGO_INITDB_ROOT_PASSWORD" \
                --authenticationDatabase admin \
                --gzip \
                --archive \
            ' > "$output"
        ;;
    'restore')
        input="$2"
        db="${3:-\$MONGO_INITDB_DATABASE}"
        docker compose exec -T "$SERVICE_NAME" \
           sh -c "exec mongorestore \
               -u \"\$MONGO_INITDB_ROOT_USERNAME\" \
               -p \"\$MONGO_INITDB_ROOT_PASSWORD\" \
               --authenticationDatabase admin \
               -d \"$db\" \
               --restoreDbUsersAndRoles \
               --gzip \
               --archive \
           " < "$input"
        ;;
    'restore-all')
        input="$2"
        docker compose exec -T "$SERVICE_NAME" \
            sh -c 'exec mongorestore \
                -u "$MONGO_INITDB_ROOT_USERNAME" \
                -p "$MONGO_INITDB_ROOT_PASSWORD" \
                --authenticationDatabase admin \
                --gzip \
                --archive \
            ' < "$input"
        ;;
    'shell')
        docker compose exec "$SERVICE_NAME" \
            sh -c 'exec mongosh \
                -u "$MONGO_INITDB_ROOT_USERNAME" \
                -p "$MONGO_INITDB_ROOT_PASSWORD" \
                --authenticationDatabase admin \
                "$MONGO_INITDB_DATABASE"'
        ;;
    *)
        echo "Usage: $0 {dump,dump-all,restore,restore-all,shell}" >&2
        exit 1
esac
