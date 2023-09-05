* [Commands](#commands)
* [Placeholders](#placeholders)
* [Environment variables](#environment-variables)
* [Get script](#get-script)
* [Examples](#examples)

## Get script

```shell
wget -qO- https://kyzima-spb.github.io/docker-useful/scripts/mongodb/mongodb.sh.tmpl | \
sed \
  -e 's/%%COMPOSE_COMMAND%%/docker compose/' \
  -e 's/%%SERVICE_NAME%%/mongo/' \
  -e 's/%%DATE_FORMAT%%/%F_%k%M%S/' \
  -e 's/%%USER_PASSWORD_VAR%%/MONGO_INITDB_ROOT_PASSWORD_FILE/' \
  > mongodb.sh \
&& chmod +x mongodb.sh
```

## Commands

* `dump` - Creates a GZ archive export of a database's contents.
* `restore` - Restores data from the GZ archive.
* `shell` - Access to the MongoDB server console.

## Placeholders

* `COMPOSE_COMMAND` - The name of the docker compose command.
* `SERVICE_NAME` - Service name in docker-compose.
* `DATE_FORMAT` - The date format used by the date command to generate filenames.
* `USER_PASSWORD_VAR` - The name of the environment variable with the user password.

## Environment variables

* `MONGO_USER` - Force the given username to be used.
* `MONGO_PASSWORD` - Force the given user password to be used.

## Examples

```shell

```
