#!/usr/bin/env bash


commandExists()
{
  command -v "$1" > /dev/null 2>&1
}


# Возвращает нулевой код, если группа существует.
groupExists()
{
  getent group "$1" > /dev/null 2>&1
}


# Перезапускает указанную команду от указанного пользователя и группы.
switch() {
  if commandExists 'gosu'; then
    exec gosu "$@"
  elif commandExists 'su-exec'; then
    exec su-exec "$@"
  else
    echo 'You must install one of the packages: gosu or su-exec.' 1>&2
    return 1
  fi
}


# Парсит аргумент командной строки, отвечающий за группу
# и возвращает целочисленный идентификатор.
parseGroupArg() {
  local group=${1#*:}

  if ! [[ $group =~ ^[0-9]+$ ]]; then
    if ! groupExists "$group"; then
      echo "Group '$group' does not exists. Use a numerical ID." 1>&2
      return 1
    fi
    group=$(getent group "$group" | cut -d: -f 3)
  fi

  echo "$group"
}


# Парсит аргумент командной строки, отвечающий за пользователя
# и возвращает целочисленный идентификатор.
parseUserArg() {
  local user=${1%:*}

  if [[ -z $user ]]; then
    user=$(id -u)
  fi

  if ! [[ $user =~ ^[0-9]+$ ]]; then
    if ! userExists "$user"; then
      echo "User '$user' does not exists. Use a numerical ID." 1>&2
      return 1
    fi
    user=$(id -u "$user")
  fi

  echo "$user"
}


# Патчит созданного в Dockerfile пользователя.
#
# Изменяет идентификатор пользователя или группы на указанные,
# если пользоатель или группа не существует.
#
# Изменяет владельца домашней директории и всех указанных директорий.
patchUser() {
  local username="$1"
  local uid="$2"
  local gid="$3"
  shift 3

  if ! userExists "$USERNAME"; then
    echo "User '$username' does not exist. Use the -u option or create a user." 1>&2
    return 1
  fi

  if ! userExists "$uid"; then
    usermod -u "$uid" "$username"
  fi

  if ! groupExists "$gid"; then
    groupmod -g "$gid" "$username"
  fi

  local homeDir
  homeDir="$(getent passwd "$username" | cut -d: -f6)"

  if [[ -d "$homeDir" ]]; then
    chown -R "$uid:$gid" "$homeDir"
  fi

  if [[ $# -gt 0 ]]; then
    chown -R "$uid:$gid" "$@"
  fi
}


# Выводит справочную информацию о программе.
usage() {
  local program
  program="$(basename "$0")"

  cat 1>&2 <<-ENDOFUSAGE
	Usage:
	  $program [-d PATH] [-e ENTRYPOINT] UID[:GID] COMMAND_STRING

	Options:
	  -d The directory or file to change ownership.
	  -e The path to the Docker entry point.
	  -u Username to be patched.
	  -v Detailed mode.
	  -h Show help.

	Arguments:
	  UID[:GID] User and group.
	  COMMAND_STRING A command with arguments as a single line.

	Examples:
	  $program 1001 id
	  $program www-data id
	  $program -v -d /app -e "\$BASH_SOURCE" "\$USER_UID:\$USER_GID" "\$*"
	ENDOFUSAGE
}


# Возвращает нулевой код, если пользователь существует.
userExists()
{
  getent passwd "$1" > /dev/null 2>&1
}


USERNAME='user'
ENTRYPOINT=''
USER_FILES=()
VERBOSE=false

while getopts 'd:e:u:vh' opt
do
  case "$opt" in
    d)
      USER_FILES+=("$OPTARG")
      ;;
    e)
      ENTRYPOINT="$OPTARG"
      ;;
    v)
      VERBOSE=true
      ;;
    u)
      USERNAME="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))


if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi


if ! USER_ID=$(parseUserArg "$1"); then
  exit 1
fi

if ! GROUP_ID=$(parseGroupArg "$1"); then
  exit 1
fi

if ! patchUser "$USERNAME" "$USER_ID" "$GROUP_ID" "${USER_FILES[@]}"
then
  exit 1
fi


COMMAND="$2"

if $VERBOSE; then
  printf ' * %s:\t%s\n' \
    'User'      "$USER_ID ($(getent passwd "$USER_ID" | cut -d: -f1))" \
    'Group'     "$GROUP_ID ($(getent group "$GROUP_ID" | cut -d: -f1))" \
    'Entry'     "$ENTRYPOINT" \
    'Command'   "$COMMAND" \
    'User dirs' "$(IFS=';' ; echo "${USER_FILES[*]}")"
fi

# then restart script as user
if ! switch "$USER_ID:$GROUP_ID" $ENTRYPOINT $COMMAND
then
  exit 1
fi
