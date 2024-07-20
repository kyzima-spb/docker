#!/usr/bin/env sh

. ./secrets.sh


echo -n 'Tests required variable value: '
(fileEnv 'TEST_VAR' 2>/dev/null) && echo 'Error' || echo 'OK'

echo -n 'Tests the existence of both variables: '
(
    TEST_VAR="secret" TEST_VAR_FILE="secret.txt" fileEnv "TEST_VAR" 2>/dev/null
) && echo 'Error' || echo 'OK'


echo -n 'Tests read secret from variable: '
(
    TEST_VAR='secret' fileEnv 'TEST_VAR';
    test "$TEST_VAR" = 'secret';
) && echo 'OK' || echo 'Error'


echo -n 'Tests empty variable value and use default: '
(
    TEST_VAR='' fileEnv 'TEST_VAR' 'default';
    test "$TEST_VAR" = 'default';
) && echo 'OK' || echo 'Error'


echo -n 'Tests read secret from file: '
(
    echo -n 'secret' > secret.txt;
    TEST_VAR_FILE='secret.txt' fileEnv 'TEST_VAR';
    rm secret.txt;
    test "$TEST_VAR" = 'secret'
) && echo 'OK' || echo 'Error'


echo -n 'Tests default value: '
(
    fileEnv 'TEST_VAR' 'default';
    test "$TEST_VAR" = 'default'
) && echo 'OK' || echo 'Error'


echo -n 'Tests empty default value: '
(
    fileEnv 'TEST_VAR' '';
    test "$TEST_VAR" = ''
) && echo 'OK' || echo 'Error'
