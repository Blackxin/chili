#!/usr/bin/env bash
source /chili/core.sh

IFS=$' \t\n'
SAVEIFS=$IFS
IFS=$'\n'

re='[0-9]{2}[ ]?'
aResult=($(awk -F'-' '{ print $3 }' resultadosena.txt))
#aJogos=($(awk -F "$re" 'lista[$1]++' jogos.txt))
aJogos=($(awk '{print " "$0}' jogos.txt))

#info "${aJogos[*]}"
#echo
#echo "${aJogos[0]}"
#echo "${aJogos[1]}"

for value in ${aJogos[*]}
do
	#info "$value"
	if [[ ! "${aResult[*]}" =~ "${value}" ]]; then
		echo "$value - ${green}OK ↑ não encontrado no BD"${reset}
	else
		echo "$value - ${red}FALHA ↓ Já existe no BD"${reset}
	fi
done
IFS=$SAVEIFS
