#!/usr/bin/env bash

echo 'Prog=/var/cache/fetch/script.sh'
Prog=/var/cache/fetch/script.sh

echo 'basename $Prog'
basename $Prog

echo 'echo ${Prog##*/}'
echo ${Prog##*/}
