#!/usr/bin/env sh

while IFS=',' read -r exitCode condition msg
do
  ./compver.sh "$condition" > /dev/null 2>&1

  if [ "$?" = "$exitCode" ]
  then
    echo "[ OK ] $condition"
  else
    echo "[FAIL] $condition: $msg"
    exit 1
  fi
done < datasets.csv
