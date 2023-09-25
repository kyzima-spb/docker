#!/usr/bin/env sh


compare() {
  case "$3" in
    '!=')
      test "$1" != "$2"
      ;;
    '==')
      test "$1" = "$2"
      ;;
    '>')
      greatThan "$1" "$2"
      ;;
    '>=')
      greatThanOrEqual "$1" "$2"
      ;;
    '<')
      lessThan "$1" "$2"
      ;;
    '<=')
      lessThanOrEqual  "$1" "$2"
      ;;
    *)
      usage
      return 2
      ;;
  esac
}


greatThan() {
  lessThan "$2" "$1"
}


greatThanOrEqual() {
  test "$1" = "$2" || greatThan "$1" "$2"
}


lessThan() {
  min="$(printf '%s\n' "$1" "$2" | sort -V | head -n1)"
  test "$min" != "$2"
}


lessThanOrEqual() {
  test "$1" = "$2" || lessThan "$1" "$2"
}


# Выводит справочную информацию о программе.
usage() {
  program="$(basename "$0")"

  cat 1>&2 <<-ENDOFUSAGE
	Performs a semantic versioning comparison of two versions.

	Usage:
	  $program VERSION1 OPERATOR VERSION2

	Arguments:
	  VERSION1 Version as left operand.
	  VERSION2 Version as right operand.
	  OPERATOR Comparison operator.
	           Available values: == != > < >= <=

	Examples:
	  $program 0.9 >= 0.10
	  $program 1.0 == 2.0
	  $program 0.10 > 0.99.0.0

	URL (https://kyzima-spb.github.io/docker-useful/apps/compver/compver.sh)
	ENDOFUSAGE
}


argc="$(echo "$1" | wc -w)"

if [ "$argc" -lt 3 ]; then
  usage
  exit 2
fi

pattern='s/(\.0+)+$//g'
ver1="$(echo "$1" | cut -d' ' -f1 | sed -r "$pattern")"
op="$(echo "$1" | cut -d' ' -f2)"
ver2="$(echo "$1" | cut -d' ' -f3 | sed -r "$pattern")"

compare "$ver1" "$ver2" "$op"
