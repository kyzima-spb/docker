#!/usr/bin/env sh

. ./secrets.sh


(fileEnv "TEST_VAR") && echo "Error" || echo "OK"
(TEST_VAR="secret" TEST_VAR_FILE="secret.txt" fileEnv "TEST_VAR") && echo "Error" || echo "OK"

(TEST_VAR="secret" fileEnv "TEST_VAR") && echo "OK" || echo "Error"
(TEST_VAR_FILE="secret.txt" fileEnv "TEST_VAR") && echo "OK" || echo "Error"
(fileEnv "TEST_VAR" 'default value') && echo "OK" || echo "Error"
(fileEnv "TEST_VAR" '') && echo "OK" || echo "Error"
