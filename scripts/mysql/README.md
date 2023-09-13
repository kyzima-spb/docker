* [Commands](#commands)
* [Placeholders](#placeholders)
* [Environment variables](#environment-variables)
* [Get script](#get-script)
* [Examples](#examples)

## Get script

```shell
wget -qO- https://kyzima-spb.github.io/docker-useful/scripts/mysql/mysql.sh.tmpl | \
sed \
  -e 's/%%COMPOSE_COMMAND%%/docker compose/' \
  -e 's/%%SERVICE_NAME%%/db/' \
  -e 's/%%IMAGE%%/mysql/' \
  -e 's/%%DATE_FORMAT%%/%F_%k%M%S/' \
  -e 's/%%ROOT_PASSWORD_VAR%%/MYSQL_ROOT_PASSWORD_FILE/' \
  -e 's/%%USER_PASSWORD_VAR%%/MYSQL_PASSWORD_FILE/' \
  > mysql.sh \
&& chmod +x mysql.sh
```

## Commands

* `dump` - Saves the given or all databases to a file.
* `dump-db` - Saves the given database to a file.
* `restore` - Restores all databases from a backup file.
* `restore-db` - Restores database from a backup file.
* `shell` - Access to the MySQL server console.

## Placeholders

* `COMPOSE_COMMAND` - The name of the docker compose command.
* `SERVICE_NAME` - Service name in docker-compose.
* `IMAGE` - Image name without tag.
* `DATE_FORMAT` - The date format used by the date command to generate filenames.
* `ROOT_PASSWORD_VAR` - The name of the environment variable with the root password.
* `USER_PASSWORD_VAR` - The name of the environment variable with the user password.

## Environment variables

* `MYSQL_USER` - Force the given username to be used.
* `MYSQL_PASSWORD` - Force the given user password to be used.

## Examples

```shell
# 1. Login to console as root user:
$ MYSQL_USER=root ./mysql.sh shell

# 2. Login to console with a custom password:
$ MYSQL_PASSWORD=123 ./mysql.sh shell

# 3. Docker compose command arguments:
$ COMPOSE_FILE=/home/user/project/docker-compose.yml \
  /home/user/project/bin/mysql.sh dump /media/backups/project
```
