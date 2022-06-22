#!/usr/bin/env bash

#Extract the rightmost substring of a character expression
#Syntax
# right <cString> <nLen> --> cReturn
# right 'vcatafesta' 1
# right 'vcatafesta' 15
# right 'vcatafesta' -1
right()
{
	local cString=$1
	local -i nLen=$2
	local -i i
	local -i nMaxLen=${#cString}

	[[ $nLen -eq -1       ]] && nLen=nMaxLen
	[[ $nLen -gt $nMaxLen ]] && nLen=nMaxLen
	i=${#cString}-$nLen
	echo ${cString:$i:$nLen}
}

right 'vcatafesta' 1
right 'vcatafesta' 15
right 'vcatafesta' -1
