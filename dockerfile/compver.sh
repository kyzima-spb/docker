#!/usr/bin/env bash


# Дополняет строку версии нулями до указанной длины.
zeroFill() {
  local n=$1
  shift 1

  echo -n "$@"

  for (( i=$#; i < n; i++ )); do
    echo -n ' 0'
  done
}


# Возвращает наибольшее кол-во сигментов из двух версий.
max() {
  a=$(echo "$1" | wc -w)
  b=$(echo "$2" | wc -w)
  echo $(( $a > $b ? $a : $b ))
}


# Выводит справочную информацию о программе.
usage() {
  local program
  program="$(basename "$0")"

  cat 1>&2 <<-ENDOFUSAGE
	Performs a semantic versioning comparison of two versions.

	Usage:
	  $program VERSION1 VERSION2 OPERATOR

	Arguments:
	  VERSION1 Version as left operand.
	  VERSION2 Version as right operand.
	  OPERATOR Comparison operator.
	           Available values: == != > < >= <=

	Examples:
	  $program
	  $program
	  $program

	URL (https://kyzima-spb.github.io/docker-useful/dockerfile/compver.sh)
	ENDOFUSAGE
}


if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

ver1=${1//./ }
ver2=${2//./ }
op="$3"

maxLength=$(max "$ver1" "$ver2")
ver1=$(zeroFill "$maxLength" $ver1)
ver2=$(zeroFill "$maxLength" $ver2)

case "$op" in
  !=)
    test "$ver1" != "$ver2"
    exit $?
    ;;
  ==)
    test "$ver1" = "$ver2"
    exit $?
    ;;
  *=)
    if [[ "$ver1" = "$ver2" ]]; then
      exit 0
    fi
    ;;
esac

ver1=($ver1)
ver2=($ver2)

for (( i=0; i < maxLength; i++ )); do
  if (( ver1[i] != ver2[i] )); then
    expr="${ver1[$i]} $op ${ver2[$i]}"
    exit $(( expr ? 0 : 1 ))
  fi
done

exit 1
