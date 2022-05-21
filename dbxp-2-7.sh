#!/usr/bin/env bash

grep b <<< 'banana da terra'
echo banana | grep b

read <<< "$BASHPID $$"
echo $REPLY

cat <<< "$BASHPID $$"
