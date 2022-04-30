#!/usr/bin/env bash

Cad="Onça"

echo 'echo $Cad | wc -c'
echo $Cad | wc -c
# 6

echo 'echo $Cad | wc -m'
echo $Cad | wc -m
# 5

echo 'echo -n $Cad | wc -m'
echo -n $Cad | wc -m
#4


echo 'echo echo ${#Cad}'
echo ${#Cad}
#4

