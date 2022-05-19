#!/usr/bin/env bash

set -- {a..z}
echo $@
echo ${@:0:1}
echo ${@:1:1}
echo ${@: -2:5}
echo ${@: -5:2}
echo ${@: -5:-3} #fail serve somente em string, not array ou parametros


