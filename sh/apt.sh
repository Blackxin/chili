#!/usr/bin/env bash

 # fetch - search, install, create, remove, upgrade packages compatible with:
 # ChiliOS GNU/Linux - https://github.com/vcatafesta/ChiliOS
 # ChiliOS GNU/Linux - https://chilios.com.br
 # MazonOS GNU/Linux - http://mazonos.com
 #
 # Created: 2019/04/05
 # Altered: 2022/03/17
 #
 # Copyright (c) 2019 - 2022, Vilmar Catafesta <vcatafesta@gmail.com>
 # All rights reserved.
 #
 # contains portion of software https://bananapkg.github.io/
 #
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions
 # are met:
 # 1. Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 2. Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 3. The name of the copyright holders or contributors may not be used to
 #    endorse or promote products derived from this software without
 #    specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 # ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 # LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 # PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 # HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 # SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 # LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 # DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 # THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 # OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#########################################################################
function configure()
{
	export LC_ALL=C
	export LANG=C
	readonly _VERSION_="2.05.55.20220317"
	readonly DEPENDENCIES=(which gpg find tar zstd curl sed grep cat awk tput dialog stat)

	# Import lib
	LIBRARY=${LIBRARY:-'/usr/share/fetch'}
	SYSCONFDIR=${SYSCONFDIR:-'/etc/fetch'}
	source "${LIBRARY}"/core.sh
	[[ -e  "${SYSCONFDIR}"/fetch.conf ]] || sh_touchconf
	source "${SYSCONFDIR}"/fetch.conf

	# default
	SEP=','
	BAIXA=${MENSAGEM}
	ALTA=${MENSAGEM}
	cmdopts=()
	PRG="${PKG_EXT:=chi.zst}"
	SITE="${PKG_SITE:=https://chilios.com.br}"
	GITSITE="${GITSITE:=0}"
	RAW="${PKG_RAW:=https://raw.githubusercontent.com/vcatafesta/ChiliOS/master}"
	AUTO_YES="${AUTO_YES:=1}"
	APP="fetch"
	VARCACHE="/var/cache/fetch"
	VARCACHE_ARCHIVES="/var/cache/${APP}/archives"
	VARCACHE_INSTALLED="/var/cache/${APP}/installed"
	VARCACHE_SEARCH="/var/cache/${APP}/search"
	LIBRARY=${LIBRARY:-'/usr/share/${APP}'}
	USE_COLOR='y'
	TMP_DIR_ROOT="$(mktemp -d -u)"
	TMP_DIR_BACKUP="${TMP_DIR_ROOT}/${APP}/${VARCACHE_SEARCH}"
	TMP_DIR_FOLDERS="${TMP_DIR_ROOT}/${APP}/${VARCACHE}/folders"
	export descme='info/desc'
	export PKG_EXT="${PKG_EXT:='chi.zst'}"
	export LFS_VARCACHE="${LFS_VARCACHE:='fetch'}"
	export VARLIB_LIST="/var/cache/${APP}/list"
	export VARLIB_DESC="/var/cache/${APP}/desc"
	export VARLIB_REMO="/var/cache/${APP}/remove"
	#PKG_RE='^([a-z-]+)(-)([0-9\\.]+)(-)([0-9])(-)(.*)(.chi.zst)$'
	#PKG_RE='([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*)-(([0-9]+(\.[0-9]+)*)(-([0-9]+))?)-([^.]+).*'
	if [[ "$PKG_EXT" = "chi.zst" ]]; then
		PKG_RE='(.+)-(([^-]+)-([0-9]+))-([^.]+)\.chi\.zst' 	#SOEN
		GREP_RE='.chi\.zst\"'
	else
		PKG_RE='(.+)-(([^-]+)-([0-9]+))\.mz' 						#SOEN
		GREP_RE='.mz\"'
	fi
}

function sh_touchconf(){
	[[ -d "${SYSCONFDIR}" ]] || mkdir -p $SYSCONFDIR &> /dev/null
	cat > $SYSCONFDIR/fetch.conf << '_EOF_'
######################################################################
# fetch.conf
######################################################################
# extension of packages: chilios=chi.zst, mazonos=mz
#PKG_EXT='mz'			# http://mazonos.com
PKG_EXT='chi.zst'		# https://github.com/vcatafesta/ChiliOS

# packages hosted on GITHUB repository: yes='1', not='0'
GITSITE='0'

# distro hosting website/packages
#PKG_SITE='https://github.com/vcatafesta/ChiliOS/tree/master'		# for use set GITSITE=1
PKG_SITE='https://chilios.com.br'											# for use set GITSITE=0
#PKG_SITE='http://localhost'													# for use set GITSITE=0
#PKG_SITE='http://201.7.66.107'												# for use set GITSITE=0
#PKG_SITE='http://mazonos.com'												# for use set GITSITE=0

#not needed change
PKG_RAW='https://raw.githubusercontent.com/vcatafesta/ChiliOS/master'
PKG_RAW_FETCH='https://raw.githubusercontent.com/vcatafesta/ChiliOS/master/updater/src/fetch'
PKG_RAW_FILE='https://raw.githubusercontent.com/vcatafesta/ChiliOS/master/packages/t/tree-1.8.0-2.chi.zst'

# configuration for generation new packages
AUTO_YES='1'
MAINTAINER='Vilmar Catafesta <vcatafesta@gmail.com>'
GPG_SIGN='0'
CREATE_SHA256='0'
DESC_BUILD='2'
REWRITE_SIG='1'
URL='http://www.linuxfromscratch.org/lfs/view/systemd/'
LICENSE='GPL2'
LFS_VERSION='11.0'
LFS_INIT='SYSTEMD'
ARCH='x86_64'
DISTRO='chili'
LFS_VARCACHE='fetch'
GITDIR='/github/ChiliOS'
PKGCORE="$GITDIR/packages/core"
PKGDIR="$PKGCORE"
CACHEDIR='/var/cache/fetch'
ALIEN_CACHE_DIR='/var/cache/pacman/pkg'
IGNOREPKG=('glibc' 'file')

#end
_EOF_
}

function sh_arraypkgfull()
{
	public_len_count_main=0
	public_len_count_pkg=0

	if (( verbose >= 2 )); then
		log_msg "Checking packages"
	fi
	public_pkg_base=($(awk -F$SEP '{ print $1 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_version=($(awk -F$SEP '{ print $2 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_build=($(awk -F$SEP '{ print $3 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_fullname=($(awk -F$SEP '{ print $4 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_dirfullname=($(awk -F$SEP '{ print $5 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_base_version=($(awk -F$SEP '{ print $6 }' $VARCACHE_SEARCH/packages-split))
	public_pkg_size=($(awk -F$SEP '{ print $7 }' $VARCACHE_SEARCH/packages-split))

	public_pkg_main=(
		public_pkg_base[@]
		public_pkg_version[@]
		public_pkg_build[@]
		public_pkg_fullname[@]
		public_pkg_dirfullname[@]
		public_pkg_base_version[@]
		public_pkg_size[@]
	)
	public_len_count_main=${#public_pkg_main[*]}
	public_len_count_pkg=${#public_pkg_base[*]}

#	for ((i=0; i<=$public_len_count_pkg; i++))
#	do
#		for ((x=0; x<=$public_len_count_main; x++))
#		do
#			printf ":${!public_pkg_main[x]:$i:1}"
#		done
#		echo
#	done
	return $public_len_count_pkg
}

function sh_ascanpkg()
{
	local pkgsearch="$1"
	local pkgfile="$2"
	local indice=0
	aPKGARRAY=()

	case $pkgfile in
		0)	indice=$( printf "%s\n" "${public_pkg_base[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		1)	indice=$( printf "%s\n" "${public_pkg_version[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		2)	indice=$( printf "%s\n" "${public_pkg_build[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		3)	indice=$( printf "%s\n" "${public_pkg_fullname[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		4)	indice=$( printf "%s\n" "${public_pkg_dirfullname[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		5)	indice=$( printf "%s\n" "${public_pkg_base_version[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
		6)	indice=$( printf "%s\n" "${public_pkg_size[@]}" | grep -n -m 1 "^${pkgsearch}$" | cut -d ":" -f1 );;
	esac

	if [[ -z $indice ]]; then
		return $false
	fi

	(( indice-- ))
	aPKGARRAY=(	"${public_pkg_base[$indice]}"
					"${public_pkg_version[$indice]}"
					"${public_pkg_build[$indice]}"
					"${public_pkg_fullname[$indice]}"
					"${public_pkg_dirfullname[$indice]}"
					"${public_pkg_base_version[$indice]}"
					"${public_pkg_size[$indice]}"
					)
	return $true
}

function sh_cabec()
{
	local nfiles=$1
#	printf "${reset}%5s(${pink}%04d${reset})${green} Package%37sversion%8s%11ssize fullname\n" "" "${nfiles}"
	printf "${reset}%5s(${pink}%04d${reset})${green} Tip Package%37sversion%8s%11ssize fullbasename\n" "" "${nfiles}"
	echo -n
}

function sh_write()
{
	local pkgsearch="$1"
	local pkgfile="$2"
	local pkgCheckNumber="$3"
#	sh_splitpkg $1
#  printf "${green}%s(%04d) ${orange}%-43s ${reset}%-15s%s\n" "     " "$pkgCheckNumber" "${aPKGSPLIT[$PKG_BASE]}" "${aPKGSPLIT[$PKG_VERSION]}" "${aPKGSPLIT[$PKG_FOLDER_DIR]}/${aPKGSPLIT[$PKG_FULLNAME]}"
	sh_ascanpkg "$pkgsearch" "$pkgfile"
#	printf "${green}%s(%04d) ${orange}%-43s ${reset}%-15s%15s %s\n" "     " "$pkgCheckNumber" "${aPKGARRAY[0]}" "${aPKGARRAY[1]}" "$(size_to_human ${aPKGARRAY[6]})" "${SITE}/packages/${aPKGARRAY[4]}"
	printf "${green}%s(%04d) ${yellow}    ${orange}%-43s ${reset}%-15s%15s %s\n" "     " "$pkgCheckNumber" "${aPKGARRAY[0]}" "${aPKGARRAY[1]}" "$(size_to_human ${aPKGARRAY[6]})" "${SITE}/packages/${aPKGARRAY[4]}"

}

function sh_write_dep()
{
	local pkgsearch="$1"
	local pkgfile="$2"
	local pkgCheckNumber="$3"
#	sh_splitpkg $1
#  printf "${green}%s(%04d) ${orange}%-43s ${reset}%-15s%s\n" "     " "$pkgCheckNumber" "${aPKGSPLIT[$PKG_BASE]}" "${aPKGSPLIT[$PKG_VERSION]}" "${aPKGSPLIT[$PKG_FOLDER_DIR]}/${aPKGSPLIT[$PKG_FULLNAME]}"
	sh_ascanpkg "$pkgsearch" "$pkgfile"
#	printf "${green}%s(%04d) ${orange}%-43s ${reset}%-15s%15s %s\n" "     " "$pkgCheckNumber" "${aPKGARRAY[0]}" "${aPKGARRAY[1]}" "$(size_to_human ${aPKGARRAY[6]})" "${SITE}/packages/${aPKGARRAY[4]}"
	printf "${green}%s(%04d) ${yellow}dep ${orange}%-43s ${reset}%-15s%15s %s\n" "     " "$pkgCheckNumber" "${aPKGARRAY[0]}" "${aPKGARRAY[1]}" "$(size_to_human ${aPKGARRAY[6]})" "${SITE}/packages/${aPKGARRAY[4]}"

}

function sh_footer()
{
	local pkgCheckNumber=$1
	log_msg "${green}($pkgCheckNumber)${reset} package(s) found."
}

function sh_list()
{
	local param=$@
	local nfiles
	local arr
	local s
	local x
	pkg=

	sh_checkdir "OFF"
	LLIST=$true

	if (( $LLIST )); then
		if (( verbose >= 2 )); then
			log_msg "Reading package lists in the repository"
		fi
	fi

	for s in ${param[@]}; do
#		[[ $(toupper "${s}") = "--NODEPS" ]] && { LDEPS=$false; continue; }
#		[[ $(toupper "${s}") = "-Y" ]]       && { LAUTO=$true; continue; }
#    	[[ $(toupper "${s}") = "-F" ]]       && { LFORCE=$true; continue; }
#    	[[ $(toupper "${s}") = "OFF" ]]      && { LLIST=$false; continue; }
#		[[ $(toupper "${s}") = "EXACT" ]]    && { LEXACT=$true; continue; }
#		[[ $(toupper "${s}") = "ALL" ]]      && { LALL=$true; continue; }
		cListSearch="$cListSearch $(echo ${s})"
	done

	if (( $LALL )) || [[ "$cListSearch" == "" ]]; then
		if (( $LALL )); then
			pkg=$(cat $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)
		else
			log_failure_msg2 "${red}error${reset}: nenhum alvo definido (use -h para obter ajuda)"
			exit 1
		fi
	else
		for x in ${cListSearch}; do
			if (( $LEXACT )); then
				pkg="$pkg $(grep ^$x$SEP $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)"
			else
				pkg="$pkg $(grep $x $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)"
			fi
		done
	fi

	arr=(${pkg[*]})
	nfiles=${#arr[*]}
	param="$@"

	if (( $LLIST )); then
		pkgCheckNumber=0
		if [[ $nfiles -gt 0 ]]; then
			if (( verbose )); then
				sh_cabec $nfiles
			fi
			for i in $pkg; do
				((pkgCheckNumber++))
				if (( verbose )); then
					[[ $LLIST = $true ]] && sh_write $i "0" $pkgCheckNumber
				fi
			done
		fi
	fi
	sh_cdroot
}

function sh_listpkgdisp()
{
	local file_list_package="$1"
	shift
	local file_list_installed=$VARCACHE_SEARCH/packages-installed-split
	local param=$@
	local s
	local SEARCH_CUT='-f5'

#	local LLIST=$true
#	local LEXACT=$false
#	local LALL=$false
#	local LDEPS=$true

	local ncontapkg=0
	local arr
	public_ListSearch=
	public_pkg_not_found=()

	[[ -e ${file_list_installed} ]] || printf '' > "${file_list_installed}"
	public_ntotal_pkg_installed=$(grep ^ ${file_list_installed} | wc -l)
	public_ntotal_pkg_listed=$public_ntotal_pkg_installed
	public_pkg=
	public_pkg_deps=
	public_size=()

#	for s in ${param[@]}; do
#		[[ $(toupper "${s}") = "--NODEPS" ]] && { LDEPS=$false; continue; }
#		[[ $(toupper "${s}") = "-Y"       ]] && { LAUTO=$true; continue; }
#   	[[ $(toupper "${s}") = "-F"       ]] && { LFORCE=$true; continue; }
#    	[[ $(toupper "${s}") = "-OFF"     ]] && { LLIST=$false; continue; }
#    	[[ $(toupper "${s}") = "-ON"      ]] && { LLIST=$true; continue; }
#		[[ $(toupper "${s}") = "--EXACT"  ]] && { LEXACT=$true; continue; }
#		[[ $(toupper "${s}") = "--ALL"    ]] && { LALL=$true; continue; }
#		public_ListSearch="$public_ListSearch $(echo ${s})"
	public_ListSearch=$param
#	done

	if [[ "$SPLITPOS" == "" ]]; then
		SPLITPOS='4'
		SEARCH_CUT='-f5'
	fi

	if [[ "$SPLITPOS" == "0" ]]; then
		SEARCH_CUT='-f1'
	fi

	if (( $LALL )) || [[ "$public_ListSearch" == "" ]]; then
		if (( $LALL )); then
			public_pkg=$(grep ^ $file_list_package | cut -d$SEP $SEARCH_CUT)
		else
			log_failure_msg2 "${red}error${reset}: nenhum alvo definido (use -h para obter ajuda)"
			exit 1
		fi
	else
		for x in ${public_ListSearch}; do
			if (( $LEXACT )); then
#				public_pkg="$public_pkg $(grep ^$x$SEP $file_list_package | cut -d$SEP -f5)"
				pkg_grep=$(grep ^$x$SEP $file_list_package | cut -d$SEP $SEARCH_CUT)
			else
#				public_pkg="$public_pkg $(grep $x $file_list_package | cut -d$SEP -f5)"
				pkg_grep=$(grep $x $file_list_package | cut -d$SEP $SEARCH_CUT)
			fi
			if [[ -n "$pkg_grep" ]]; then
				public_pkg="$public_pkg $(echo $pkg_grep)"
			else
				log_failure_msg "${red}error${reset}: ${orange}${x} ${reset}target was ${red}NOT ${reset}found."
				public_pkg_not_found+=("$x")
			fi
			if !(( $LSEARCHONLY )); then
				pkginstalled=$(grep ^$x$SEP $VARCACHE_SEARCH/packages-installed-split | cut -d$SEP $SEARCH_CUT)
				sh_splitpkg ${pkginstalled}
				if [[ -n "$pkginstalled" && "$pkg_grep" = "$pkginstalled" ]]; then
					log_failure_msg "${yellow}attention${reset}: ${orange}${aPKGSPLIT[$PKG_BASE_VERSION]} ${reset}está atualizado -- reinstalando."
	  			fi
  			fi
		done
	fi

  	arr=(${public_pkg[*]})
  	ncontapkg=${#arr[*]}
	public_ntotal_pkg_listed=$ncontapkg

	if [[ "${#public_pkg}" -gt 0 ]]; then # pacote?
		if (( $LDEPS )); then
			sh_getdeps $LDEPS
		fi
      arr=(${public_pkg[*]})
      ncontapkg=${#arr[*]}
		public_ntotal_pkg_listed=$ncontapkg

		if (( ncontapkg )); then
			if (( verbose )); then
				sh_cabec $ncontapkg
			fi
		fi

		if (( verbose )); then
			pkgNumber=0
			for i in ${public_pkg[*]}
			do
		  		((pkgNumber++))
				sh_write $i "$SPLITPOS" $pkgNumber
  			done
			for i in ${public_pkg_deps[*]}
			do
		  		((pkgNumber++))
				sh_write_dep $i "$SPLITPOS" $pkgNumber
  			done
		fi
	#else
	#	log_msg "($ncontapkg) package(s) found."
	fi
	sh_cdroot
	return $public_ntotal_pkg_listed
}

function sh_checknet()
{
	# have internet?
	log_info_msg "${cyan}Testing internet"
	curl --insecure $SITE >/dev/null 2>&1 ||
	{
		evaluate_retval
		log_failure_msg2 "No route to server ($SITE) - ABORTED."
		return 1
	}
	evaluate_retval
	return $?
}

function sh_selfupdate()
{
	local param=$@

#	sh_checkparametros ${param}
	if !(( $LAUTO )) || !(( $LFORCE)); then
		echo
		conf "Update ${0##*/} from internet?"
		LAUTO=$?
	fi

	if (( $LAUTO )) || (( $LFORCE )); then
		local link="$PKG_RAW_FETCH"
		local tmp_dir_full="/tmp/${APP}"
		local tmp_dir="/tmp/${APP}/src"

		#internet?
		sh_checknet; [[ $? = $false ]] || { return 1;}
		log_msg "Ok, let's do it..."
		#Ok, Puxe o arquivo do repositorio agora!
		[[ -d "${tmp_dir_full}" ]] && rm -r "${tmp_dir_full}"
		[[ -d "${tmp_dir}" ]] || mkdir -p "${tmp_dir}"
		pushd "${tmp_dir}" &>/dev/null
		log_info_msg "${cyan}Clonando $link"
		curl --insecure --silent --remote-name "${link}"
		evaluate_retval

		log_info_msg "${cyan}Permission and Copy archives"
		chmod +x ${tmp_dir}/fetch
		evaluate_retval

		log_info_msg "${cyan}Copying file ${yellow}fetch ${red}to ${yellow}${0}"
		cp -f ${tmp_dir}/fetch ${0}
		evaluate_retval

		log_info_msg "${cyan}Removing temporary files"
		[[ -d "${tmp_dir_full}" ]] && rm -r "${tmp_dir_full}"
		evaluate_retval
		log_info_msg "${violet}${0##*/} updated successfully, enjoy!"
		evaluate_retval
		exit 0
	fi
	return 1
	sh_cdroot
}

function sh_clean()
{
	local param=$@
	local lRetval=$false
	local nfiles=0

	if !(( $LAUTO )); then
		printf "Pacotes a serem mantidos:\n"
      printf "      Todos os pacotes instalados localmente\n"
		printf "\n"
		printf "Cache directory: $VARCACHE_ARCHIVES\n"
		conf "${blue}:: ${reset}Do you want to remove all packages from the cache?"
		LAUTO=$?
	fi

	if (( $LAUTO )); then
		log_info_msg "Deleting downloaded package files"
		[[ -d $VARCACHE_ARCHIVES ]] || mkdir -p $VARCACHE_ARCHIVES
		nfiles=$(find $VARCACHE_ARCHIVES -iname "*" -type f  | wc -l)
		rm -f $VARCACHE_ARCHIVES/*
		evaluate_retval
		lRetval=$true
		printf '' >| "$VARCACHE_SEARCH/packages-in-cache"
		log_success_msg2 "${yellow}($nfiles) ${cyan}files deleted"
	fi
	sh_cdroot
	return $lRetval
}

function sh_checkdir()
{
	if (( verbose >= 2 )); then
		log_msg "Checking job directories"
	fi

	if [ $# -lt 1 ]; then
		log_info_msg "$VARCACHE_ARCHIVES" ; [[ -d $VARCACHE_ARCHIVES  ]] && evaluate_retval || { mkdir -p $VARCACHE_ARCHIVES  >/dev/null 2>&1; evaluate_retval; }
		log_info_msg "$VARCACHE_INSTALLED"; [[ -d $VARCACHE_INSTALLED ]] && evaluate_retval || { mkdir -p $VARCACHE_INSTALLED >/dev/null 2>&1; evaluate_retval; }
		log_info_msg "$VARCACHE_SEARCH"   ; [[ -d $VARCACHE_SEARCH    ]] && evaluate_retval || { mkdir -p $VARCACHE_SEARCH    >/dev/null 2>&1; evaluate_retval; }
		log_info_msg "$VARLIB_LIST"       ; [[ -d $VARLIB_LIST        ]] && evaluate_retval || { mkdir -p $VARLIB_LIST        >/dev/null 2>&1; evaluate_retval; }
		log_info_msg "$VARLIB_DESC"       ; [[ -d $VARLIB_DESC        ]] && evaluate_retval || { mkdir -p $VARLIB_DESC        >/dev/null 2>&1; evaluate_retval; }
		log_info_msg "$VARLIB_REMO"       ; [[ -d $VARLIB_REMO        ]] && evaluate_retval || { mkdir -p $VARLIB_REMO        >/dev/null 2>&1; evaluate_retval; }
	else
		[[ -d $VARCACHE_ARCHIVES  ]] || mkdir -p $VARCACHE_ARCHIVES  >/dev/null 2>&1
		[[ -d $VARCACHE_INSTALLED ]] || mkdir -p $VARCACHE_INSTALLED >/dev/null 2>&1
		[[ -d $VARCACHE_SEARCH    ]] || mkdir -p $VARCACHE_SEARCH    >/dev/null 2>&1
		[[ -d $VARLIB_LIST        ]] || mkdir -p $VARLIB_LIST        >/dev/null 2>&1
		[[ -d $VARLIB_DESC        ]] || mkdir -p $VARLIB_DESC        >/dev/null 2>&1
		[[ -d $VARLIB_REMO        ]] || mkdir -p $VARLIB_REMO        >/dev/null 2>&1
	fi
	[[ -e $VARCACHE_SEARCH/packages-split           ]] || printf '' > "$VARCACHE_SEARCH/packages-split"
	[[ -e $VARCACHE_SEARCH/packages-installed-split ]] || printf '' > "$VARCACHE_SEARCH/packages-installed-split"

	return $?
}

function sh_updaterepo()
{
	if (( $LSELF )); then
		sh_selfupdate "$@"
		return $?
	fi
	local dw=("folders"
		 		 "folders_metapackages"
		 		 "metapackages"
		 		 "packages-split"
		 		)
	#internet?
	sh_checknet; [[ $? = $false ]] || { return 1;}

	pushd $VARCACHE_SEARCH/ &>/dev/null
	sh_backup

	log_info_msg "Cleaning up $VARCACHE_SEARCH/"
	for i in "${dw[@]}"; do
		rm -f $VARCACHE_SEARCH/${i}
	done
	evaluate_retval

	log_info_msg "Updating file packages from ${SITE}/repo/"
	curl --silent --insecure -O ${SITE}/repo/${dw[0]} -O ${SITE}/repo/${dw[1]} -O ${SITE}/repo/${dw[2]} -O ${SITE}/repo/${dw[3]}
	evaluate_retval

	sh_cleaning
	unset FOLDER_TEMP

	local nfilesInReposit=$(cat $VARCACHE_SEARCH/packages-split | wc -l)
	local nfilesInstalled=$(cat $VARCACHE_SEARCH/packages-installed-split | wc -l)
	log_msg "${cyan}All list packages updated!${reset}"
	log_msg "${blue}($(strzero $nfilesInReposit 5)) packages in repository${reset}"
	log_msg "${green}($(strzero $nfilesInstalled 5)) packages installed${reset}"
	echo
	log_msg "${reset}Use: # ${0##*/} --help for helping${reset}"
	popd &>/dev/null
}

function sh_update()
{
	if (( $LSELF )); then
		sh_selfupdate "$@"
		return $?
	fi

	#internet?
	sh_checknet; [[ $? = $false ]] || { return 1;}

	pushd $VARCACHE_SEARCH/ &>/dev/null
	sh_backup

	log_info_msg "Cleaning up $VARCACHE_SEARCH/"
	printf '' > "$VARCACHE_SEARCH/folders"
	printf '' > "$VARCACHE_SEARCH/packages-split"
	printf '' > "$VARCACHE_SEARCH/folders_metapackages"
	printf '' > "$VARCACHE_SEARCH/metapackages"
	evaluate_retval

	local HTTP_SERVER="$(string_alltrim $(curl -s -k --insecure --head --url "${SITE}" | grep '^[Ss]erver' | awk '{print $2}') | cut -d/ -f1)"

#debug "${HTTP_SERVER}"
#debug "$(string_len "${HTTP_SERVER}")"
	log_info_msg "Updating Folders from ${SITE}"
	case ${HTTP_SERVER} in
		Apache|nginx)
			#curl --insecure --silent --url "${SITE}/packages/"|grep "/</a" |grep '[a-z]'|sed 's/<[^>]*>//g'|cut -d/ -f1|sed 's/^[ \t]*//;s/[ \t]*$//'|sed 's/Index of//g' > ${VARCACHE_SEARCH}/folders
			#curl --insecure --silent --url "${SITE}/packages/"|sed 's/<[^>]*>//g'|cut -d/ -f1|sed 's/^[ \t]*//;s/[ \t]*$//'|sed 's/Index of//g' > ${VARCACHE_SEARCH}/folders
			#curl --insecure --silent --url "${SITE}/packages/"|grep href|sed 's/[*<>]//g'|sed 's/[*=/"]/:/g'|cut -d: -sf3 > ${VARCACHE_SEARCH}/folders
			curl --insecure --silent --url "${SITE}/packages/"|grep -E -o '>[[:alnum:]]*/'|sed 's/>//g;s/\///g' > ${VARCACHE_SEARCH}/folders
			;;
		LiteSpeed)
			curl --insecure --silent --url "${SITE}/packages/"|grep -o 'packages/[a-z]'|sed 's/packages\///g' > ${VARCACHE_SEARCH}/folders
			;;
		GitHub.com)
			curl --insecure --silent --url "${SITE}/packages/"|grep /packages/ |sed 's/<[^>]*>//g;s/ //g' > ${VARCACHE_SEARCH}/folders
			;;
	esac

#	FoldersInRepo='arch base dev extra games lib meta net sec theme x xapp'
#	echo "${FoldersInRepo[@]}" > ${VARCACHE_SEARCH}/folders

	evaluate_retval
	log_msg "${pink}Updating packages lists from ${SITE}...${reset}"
	FoldersInRepo=$(cat $VARCACHE_SEARCH/folders)
	#spinner & SPINNERPID=$!
	local Folders

#debug "${FoldersInRepo}"

	for Folders in ${FoldersInRepo}; do
		FOLDER_TEMP="$TMP_DIR_FOLDERS/$Folders"
		case ${HTTP_SERVER} in
			Apache|nginx)
				#site normal
	#			PackagesInFolders=$(curl -k --silent --url "${SITE}/packages/${Folders}/"|sed 's/^.*href="//' | sed 's/".*$//' | grep ".${PRG}$" | awk '{print $1}')
	#			MetaPkgInFolders=$(curl -k --silent --url "${SITE}/packages/${Folders}/"|sed 's/^.*href="//' | sed 's/".*$//' | grep ".meta$" | awk '{print $1}')
				response=$(curl -s -w "%{http_code}\n" -k --url "${SITE}/packages/${Folders}/" --output $FOLDER_TEMP)
			   PackagesInFolders=($(grep -E -o '>'$PKG_RE'<' $FOLDER_TEMP | sed 's/>//g; s/<//g'))
	#		   PackagesInFolders=($(grep -E -o '>[^"]*.'${PKG_EXT} $FOLDER_TEMP| sed 's/>//g'| sort -u))
	#		   PackagesInFolders=($(grep -oP '>\K.*\.chi.zst(?=<)' $FOLDER_TEMP))
	#		   PackagesInFolders=($(sed 's/<[^>]*>//g;s/ .*//;/.desc/d' $FOLDER_TEMP))
				MetaPkgInFolders=($(grep '.meta\"' $FOLDER_TEMP | cut -d'"' -f2 ))
				SizePkgInFolders=($(grep $GREP_RE $FOLDER_TEMP | awk '{print $5}' ))
				;;
			LiteSpeed)
				PackagesInFolders=$(curl --insecure --silent --url "${SITE}/packages/${Folders}/"|sed 's/^.*href="//' | sed 's/".*$//' | sed 's/\// /g' | grep ".${PRG}$"| awk '{print $NF}')
				MetaPkgInFolders=$(curl --insecure --silent --url "${SITE}/packages/${Folders}/" |sed 's/^.*href="//' | sed 's/".*$//' | sed 's/\// /g' | grep ".meta$" | awk '{print $NF}')
				;;
			GitHub.com)
				#repositorio github
				PackagesInFolders=$(curl --insecure --silent --url "${SITE}/packages/${Folders}/"|sed 's/^.*href="//' | sed 's/".*$//' | sed 's/\// /g' | grep ".${PRG}$"| awk '{print $NF}')
				MetaPkgInFolders=$(curl --insecure --silent --url "${SITE}/packages/${Folders}/" |sed 's/^.*href="//' | sed 's/".*$//' | sed 's/\// /g' | grep ".meta$" | awk '{print $NF}')
				;;
		esac

		local count=0
		for pkgInFolder in ${PackagesInFolders[@]}; do
#			sh_splitpkgre ${pkgInFolder}
			sh_splitpkg ${pkgInFolder}
			pkg_size=${SizePkgInFolders[$count]}
			echo "${aPKGSPLIT[$PKG_BASE]}$SEP${aPKGSPLIT[$PKG_VERSION]}$SEP${aPKGSPLIT[$PKG_BUILD]}$SEP${aPKGSPLIT[$PKG_FULLNAME]}$SEP${Folders}/${pkgInFolder}$SEP${aPKGSPLIT[$PKG_BASE_VERSION]}$SEP${pkg_size}" >> $VARCACHE_SEARCH/packages-split
			((count++))
		done
		for MetaInFolder in ${MetaPkgInFolders[@]}; do
			echo "${Folders}/${MetaInFolder}" >> folders_metapackages
			echo "${MetaInFolder}"            >> metapackages
			((count++))
		done

		cstrvalue=$(strzero ${count} 5)
		#[[ ${count} =  0 ]] || log_success_msg2 "  Updating... (${blue}${cstrvalue}${reset}) packages in ${Folders}"
		#[[ ${count} != 0 ]] || log_failure_msg2 "  Updating... (${blue}${cstrvalue}${reset}) packages in ${Folders}"
		log_success_msg2 "  Updating... (${blue}${cstrvalue}${reset}) packages in ${Folders}"
	done
#	{ kill $SPINNERPID; wait $SPINNERPID 2>/dev/null; echo ;}

	sh_recreatefilepackagesinstalled
	sh_cleaning
	unset FOLDER_TEMP

	local nfilesInReposit=$(cat $VARCACHE_SEARCH/packages-split | wc -l)
	local nfilesInstalled=$(cat $VARCACHE_SEARCH/packages-installed-split | wc -l)
	log_msg "${cyan}All list packages updated!${reset}"
	log_msg "${blue}($(strzero $nfilesInReposit 5)) packages in repository${reset}"
	log_msg "${green}($(strzero $nfilesInstalled 5)) packages installed${reset}"
	echo
	log_msg "${reset}Use: # ${0##*/} --help for helping${reset}"
	popd &>/dev/null
}

function sh_FilesInCache()
{
	local nfilesincache=0
	local index=1

	pushd $VARCACHE_ARCHIVES/ &>/dev/null
	aCache=($(echo *.${PRG}))
	[ ${aCache[0]} = "*.${PRG}" ] && aCache=()
	[[ -e $VARCACHE_SEARCH/packages-in-cache ]] || rm -f $VARCACHE_SEARCH/packages-in-cache
	printf '' > "$VARCACHE_SEARCH/packages-in-cache"
	for item in ${aCache[*]}; do
    	echo $item >> $VARCACHE_SEARCH/packages-in-cache
	done
	popd  &>/dev/null
	nfilesincache=${#aCache[*]}

    if [[ "$1" != "OFF" ]]; then
        [ $nfilesincache <> 0 ] || maxcol; replicate "=" $?
        index=1
        for y in ${aCache[*]}
        do
            log_success_msg2 "IN CACHE: [$index]${orange}$y${reset}"
            ((index++))
        done
        [ $nfilesincache <> 0 ] || maxcol; replicate "=" $?
        echo -e "${yellow}($nfilesincache)  ${cyan}packages in cache"
    fi
	return $nfilesincache
}

function sh_pkgoutcache()
{
	log_wait_msg "Ok, let's do it..."
	log_info_msg "Wait, doing some calculations..."

	sh_FilesInCache "OFF"
	local nfilesincache=${?}
	evaluate_retval

	local aPkgOut=()
	local aRepository=$(_CAT $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)
	local x
	local y
	local index=0
	local lfind=$false

	for x in ${aRepository[*]};do
		lfind=$false
		for y in ${aCache[*]};do
			if [ $x = $y ]; then
				lfind=$true
				break
			fi
		done
		if [ $lfind = $false ]; then
			aPkgOut[$index]=$x
			((index++))
		fi
	done
	local nfilesoutcache=${#aPkgOut[*]}
	[ $nfilesoutcache <> 0 ] || maxcol; replicate "=" $?
   index=1
	for y in ${aPkgOut[*]}
	do
		sh_write "$y" "0" "$index"
		#log_msg "NOT IN CACHE: [$index]${orange}$y${reset}"
		((index++))
	done
	[ $nfilesoutcache <> 0 ] || maxcol; replicate "=" $?
	echo -e "${yellow}($nfilesincache)  ${cyan}packages in cache"
	echo -e "${yellow}($nfilesoutcache) ${cyan}packages in repository e out cache"
	return 0
}

function sh_CatAndSizePkg()
{
	local cpacote=$1
	local LSHOW=$2
	local retval=0

	source "$cpacote"
	if (( $LSHOW )); then
		printf "${cyan}BaseName     : ${yellow}${aPKGSPLIT[$PKG_FOLDER_DIR]}/${aPKGSPLIT[$PKG_FULLNAME]}\n"
		printf "${cyan}Name         : ${yellow}${pkgname}\n"
		printf "${cyan}Version      : ${yellow}${version}\n"
		printf "${cyan}Build        : ${yellow}${build}\n"
		printf "${cyan}Description  : ${yellow}${desc}\n"
		printf "${cyan}Architecture : ${yellow}${arch}\n"
		printf "${cyan}URL          : ${yellow}${url}\n"
		printf "${cyan}Licenses     : ${yellow}${license}\n"
		printf "${cyan}Dependencies : ${yellow}${depend}\n"
		printf "${cyan}Dependencies : ${yellow}${dep}\n"
		printf "${cyan}Size         : ${yellow}$(size_to_human ${size})\n"
		printf "${cyan}Packer       : ${yellow}${maintainer}\n"
		printf "${cyan}Distro       : ${yellow}${distro}\n"
		printf "${cyan}Init         : ${yellow}${lfs_init}\n"
		printf "${cyan}LSB          : ${yellow}${lfs_version}\n"
    	printf "${reset}\n"
	fi
	retval=${size}
	unset pkgname version build desc arch url license depend dep size mainteiner distro lfs_init lfs_version
	return $retval
}

function sh_ShortCatPkg()
{
	local cpacote=$1
	local LSHOW=$2
	local retval=0
	local cpackage="${aPKGSPLIT[$PKG_BASE]}"
	local SEARCH_CUT='-f5'
	local pkginstalled=

  	source "$cpacote"
	if (( $LSHOW )); then
		pkginstalled=$(grep ^$cpackage$SEP $VARCACHE_SEARCH/packages-installed-split | cut -d$SEP $SEARCH_CUT)
		if [[ -z $pkginstalled ]]; then
			printf "%s  %s %s\n" "${pink}${aPKGSPLIT[$PKG_FOLDER_DIR]}/${yellow}${aPKGSPLIT[$PKG_BASE]}" "${green}${aPKGSPLIT[$PKG_VERSION]}-${build}" "${white}${desc}"
		else
		printf "%s  %s %s\n" "${pink}${aPKGSPLIT[$PKG_FOLDER_DIR]}/${yellow}${aPKGSPLIT[$PKG_BASE]}" "${green}${aPKGSPLIT[$PKG_VERSION]}-${build}" "${cyan}[installed] ${white}${desc}"
		fi
    	printf "${reset}"
	fi
	retval=${size}
	unset pkgname version desc arch url license depend dep size mainteiner distro lfs_init lfs_version
	return $retval
}

function sh_show()
{
	local param=$@
	local error_value=0

	if (( verbose >= 2  )); then
		log_msg "Reading package lists..."
	fi

	LDEPS=$false; LEXACT=$true; sh_listpkgdisp "$VARCACHE_SEARCH/packages-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	if [[ $public_pkg != "" ]]; then
		for i in $public_pkg; do
			sh_splitpkg ${i}
			local cfullname=${aPKGSPLIT[1]}.desc
			local cBase=${aPKGSPLIT[$PKG_BASE]}
			local cBaseVersion=${aPKGSPLIT[$PKG_BASE_VERSION]}
			local cpacote=${aPKGSPLIT[$PKG_BASE_VERSION]}.desc
			local cVersion=${aPKGSPLIT[$PKG_VERSION]}
			local cBuild=${aPKGSPLIT[$PKG_BUILD]}
	    	local error_value=0

			cpacote=$VARCACHE_ARCHIVES/$cfullname
			if [[ $LFORCE = $true ]] || ! [[ -e ${cpacote} ]]; then
				sh_wgetdesc
	    		error_value="${?}"
			fi

    		if [ ${error_value} = 0 ]; then
				sh_CatAndSizePkg "$cpacote" $true
    		else
    			log_failure_msg2 "ERROR Downloading ${red}$cfullname${reset}"
    		fi

		done
	fi
	sh_cdroot
}

function _PRE_REMOVE()
{
	(
	local packname="$1"
	local ntam=${#packname}
	local pkgsearch="${packname:0:$((ntam-2))}"
	local re="\b${pkgsearch}\b"
	local inc=0
	local count_occurrences=0
	local search_pack

	pushd $VARLIB_DESC 1>/dev/null
	local alldesc=$packname.desc

	for search_pack in $alldesc; do
		if [[ "$search_pack" =~ ^${re}.* ]]; then
			for q in *; do
				if [[ "$q" =~ ^${re}.* ]]; then
					((count_occurrences++))
				fi
			done

			[[ -e $VARLIB_DESC/${search_pack} ]] && source $VARLIB_DESC/${search_pack}
			local name_version_build="${packname}"
			AUTO_YES=$true
			pushd "${VARLIB_LIST}" 1>/dev/null
			search_pack="${search_pack/%.desc/.list}" # se terminar com .desc substitua por .list
			[[ -e "${search_pack}" ]] && { _REMOVE_NOW "$name_version_build"; return 0 ;} || { log_failure_msg2 "ERROR: FILE NOT FOUND ${VARLIB_LIST}/${search_pack}"; return 1;}
			continue
		else
			((inc++))
		fi
	done

	[[ "$inc" -gt '0' ]] && { log_failure_msg2 "NOT FOUND ${packname}"; return 1 ;}
	)
	_SUBSHELL_STATUS
}

function sh_remove()
{
	local param=$@
	local x

	LDEPS=$false; LEXACT=$true; sh_listpkgdisp "$VARCACHE_SEARCH/packages-installed-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	if (( $ntotal_pkg_listed )); then
		if !(( $LAUTO )); then
			echo
			confno "${blue}::${reset} Remove package(s)?"
			LAUTO=$?
		fi

		if (( $LAUTO )); then
			for i in $public_pkg
			do
				sh_splitpkg ${i}
				local cfullname=${aPKGSPLIT[1]}
				local cbase=${aPKGSPLIT[$PKG_BASE]}
				local cbaseversion=${aPKGSPLIT[$PKG_BASE_VERSION]}
				local cpacote=${aPKGSPLIT[$PKG_BASE_VERSION]}
				local cversion=${aPKGSPLIT[$PKG_VERSION]}
				local cbuild=${aPKGSPLIT[$PKG_BUILD]}
				sh_doremove $cpacote $i
			done
		fi
	else
		echo
		#log_failure_msg2 "${red}error${reset}:${orange}${public_ListSearch} ${reset}not installed."
	fi
	return 0
}

function sh_removepkg()
{
	shift
	while [[ -n "$1" ]]; do
		_PRE_REMOVE "$1" || return 1
		retval=${?}
		sh_splitpkg "$1"
		_pkginstalled=($(echo $VARCACHE_INSTALLED/${1}*| sed 's|/| |g'|awk '{print $5}'|sed 's/.'${PRG}'//g'))
		[[ $retval = 0 ]] && _pkg=($(echo $VARCACHE_INSTALLED/${1}*| sed 's|/| |g'|awk '{print $5}'))
		[[ $retval = 0 ]] && rm -f $VARCACHE_INSTALLED/${_pkg}
		[[ $retval = 0 ]] && sed -i  '/'${_pkginstalled}'/d' $VARCACHE_SEARCH/packages-installed-split
		shift
	done
	return 0
}

function sh_doremove()
{
	local param=$@

	log_wait_msg "Wait, Removing package ${orange}${i}"
#	ERROR=$(sh_removepkg -r $1 2>&1)
	sh_removepkg -r $1
	local error_value="${?}"
	if [ ${error_value} = 0 ]; then
		if (( $LLIST )); then
			log_success_msg2 "${green}${2}${reset} Done. Removal of the package successfully completed"
		fi
	fi
	return $error_value
}

function sh_download()
{
	local param=$@
	local error_value=0
	local nFilesDownloaded=0

	LDEPS=$false; LEXACT=$true; sh_listpkgdisp "$VARCACHE_SEARCH/packages-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	if [[ $public_pkg != "" ]]; then
		pushd $VARCACHE_ARCHIVES/ &>/dev/null

		#internet?
		sh_checknet; [[ $? = $false ]] || { return 1;}

		if (( verbose )); then
			log_msg "Downloading package..."
		fi

		for i in $public_pkg; do
			local nTotalFiles=$ntotal_pkg_listed
			local cspace=$(printf "%20s" ' ')
			sh_splitpkg ${i}
			local cfullname="${aPKGSPLIT[$PKG_FULLNAME]}"

    		if (( $LFORCE )); then
				sh_wgetdesc ${i}
				sh_wgetfull ${i}
				[[ $? -eq 0 ]] && (( nFilesDownloaded++ ))
			else
			 	if test -e $VARCACHE_ARCHIVES/$cfullname; then
 					log_failure_msg2 "${orange}${i##*/} ${reset}Package is already downloaded. Use the -f option to force download."
				else
					sh_wgetdesc ${i}
					sh_wgetfull ${i}
					[[ $? -eq 0 ]] && (( nFilesDownloaded++ ))
				fi
			fi
		done
		log_msg "${cyan}($nFilesDownloaded) packages(s) downloaded."
		popd &>/dev/null
	fi
}

function sh_getdeps()
{
	local ncontadep=0
	local ncontapkgdep=0
	local	arr=()
	local pkgNumber=0
   local cfullfilename
   local x
   local LDEPS=${1}
	deps=
  	GETDEPS=

	if (( verbose >= 2 )); then
		log_msg "${cyan}solving dependencies..."
	fi

   for i in $public_pkg
	do
		sh_splitpkg "${i}"
		cbase=${aPKGSPLIT[PKG_BASE]}
		cfullfilename=${aPKGSPLIT[PKG_FULLNAME]}
	   test -e $VARCACHE_ARCHIVES/$cfullfilename.desc || sh_wgetdesc
		if test -e $VARCACHE_ARCHIVES/$cfullfilename.desc; then
	   	source $VARCACHE_ARCHIVES/$cfullfilename.desc
#	   	deps="$deps ${cbase}"
			if (( $LDEPS )); then
	   	  	deps="$deps ${dep[*]}"
      		deps="$deps $(cat $VARCACHE_ARCHIVES/${cfullfilename}.desc | grep ^depend | awk -F"'" '{print $2}')"
      	fi
		fi
   done

  	sh_adel "$deps"
  	arr=(${deps[*]})
  	ncontapkgdep=${#arr[*]}
  	for i in ${deps[*]}
  	do
  		((ncontadep++))
  		pkgdep=$(cat $VARCACHE_SEARCH/packages-split | grep ^${i}$SEP | awk -F$SEP '{print $5}')
  		if [[ $pkgdep = "" ]]; then
			if (( verbose )); then
  				printf "${red}%s(%04d) ${orange}%-40s ${reset}%-40s\n" "     " "$ncontadep" "${i}" "WARNING! Dependency not found in the database. ${reset}Use: # fetch -Sy to update with the repository${reset}"
			fi
  		else
  			pkginstalled=$(cat $VARCACHE_SEARCH/packages-installed-split | grep ^${i}$SEP | awk -F$SEP '{print $5}')
	  		if [[ $pkginstalled = "" ]]; then
	  			GETDEPS="$GETDEPS $(echo $pkgdep)"
	  		fi
  		fi
  	done
#  public_pkg=$GETDEPS
  	public_pkg_deps=$GETDEPS
   return $?
}

function sh_wgetresponse()
{
	local i="$1"
	local response
	local cfile=$(echo ${i##*/})
	local cfullfilename=$VARCACHE_ARCHIVES/$cfile

	if (( verbose >= 2 )); then
		log_info_msg "${cyan}Fetching package ${cRaw}/packages/${orange}${i}"
		response=$(curl -w "%{http_code}\n" -k -O "${cRaw}/packages/$i")
	else
		response=$(curl -s -w "%{http_code}\n" -k -O "${cRaw}/packages/$i")
	fi

	if [[ $response -eq 404 ]]; then
		if (( verbose >= 2 )); then
			evaluate_retval $NEG
		fi
		rm -f $cfullfilename &> /dev/null
		if (( verbose >= 2 )); then
			log_failure_msg2 "${red}error${reset}: NOT FOUND file ${orange}${cfile} ${reset}at $SITE"
		fi
		return 1
	fi

	if (( verbose >= 2 )); then
		evaluate_retval
	fi
	return 0
}

function sh_wgetdesc()
{
	local cfullfilename=$1
	local cRaw
   local nretval

	if !(( $GITSITE )); then
		cRaw=$SITE 	#site normal
	else
		cRaw=$RAW	#github
	fi
	pushd $VARCACHE_ARCHIVES/ &>/dev/null
	sh_wgetresponse "${i}.desc"
	nretval=$?
	popd &>/dev/null
	return $nretval
}

function sh_wgetfull()
{
	local cfullfilename=$1
	local cRaw
   local nretval

	if !(( $GITSITE )); then
		cRaw=$SITE	#site normal
	else
		cRaw=$RAW	#github
	fi
	sh_wgetresponse "${i}"
	nretval=$?
	return $nretval
}

function sh_wgetpartial()
{
	local cfullfilename=$1
	local cRaw

	if !(( $GITSITE )); then
		cRaw=$SITE	#site normal
	else
		cRaw=$RAW	#github
	fi

	if ! test -e $VARCACHE_ARCHIVES/$cpacote; then
		sh_wgetresponse "${i}"
	fi

	if ! test -e $VARCACHE_ARCHIVES/$cpacote.desc; then
		sh_wgetresponse "${i}.desc"
	fi
	return $?
}

function sh_checksha256sum()
{
	log_info_msg "Checking sha256sum..."
	ERROR=$(sha256sum -c ${cpacote}.sha256 2>&1>/dev/null)
	evaluate_retval
	return $?
}

function sh_oldsplitpkg()
{
	local file=${1}
	local pkg_folder_dir
	local pkg_fullname
	local pkg_arch
	local pkg_base
	local pkg_base_version
	local pkg_version
	local pkg_build

	aPKGSPLIT=()
	pkg_folder_dir=$(echo ${file%/*})							#remove arquivo deixando somente o diretorio/repo
	pkg_fullname=$(echo ${file##*/})    						#remove diretorio deixando somente nome do pacote
	pkg_arch=$(echo ${pkg_fullname%%.${PRG}})   				#remove extensao pacote (chi.zst/mz)
	pkg_base=$(echo ${pkg_arch%.*})         					# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
	pkg_base=$(echo ${pkg_base%-*})   				  			# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash

	pkg_base_version=$(echo ${pkg_arch%-any*})      		# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
	pkg_base_version=$(echo ${pkg_base_version%-x86_64*})	# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
	pkg_version=$(echo ${pkg_base_version#*-})				# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
	pkg_version=$(echo ${pkg_version#*-})						# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
	pkg_build=$(echo ${pkg_version#*-})							# https://elmord.org/blog/?entry=20121227-manipulando-strings-bash

	pkg_arch="${file%.*}"
	pkg_base_version="${file%-*}"
	pkg_build="${pkg_base_version##*-}"
	pkg_version="${file%-*}"
	pkg_version="${pkg_version%-*}"
	pkg_base="${pkg_version%-*}"
	pkg_version="${pkg_version##*-}-$pkg_build"

	aPKGSPLIT=($pkg_folder_dir $pkg_fullname $pkg_arch $pkg_base $pkg_base_version $pkg_version $pkg_build )
	aPKGLIST=${aPKGSPLIT[*]}
	return $?
}

function sh_splitpkgawk()
{
	file=${1}
	aPKGSPLIT=()

	pkg_folder_dir=$(echo ${file%/*})							#remove arquivo deixando somente o diretorio/repo
	pkg_fullname=$(echo ${file##*/})    						#remove diretorio deixando somente nome do pacote

	arr=($(echo $pkg_fullname | awk 'match($0, /(.+)-(([^-]+)-([0-9]+))-([^.]+)\.chi\.zst/, array) {
			print array[0]
			print array[1]
			print array[2]
		   print array[3]
		   print array[4]
    		print array[5]
    		print array[6]
			}'))

	pkg_fullname="${arr[0]}"
	pkg_base="${arr[1]}"
	pkg_version_build="${arr[2]}"
	pkg_version="${arr[3]}"
	pkg_build="${arr[4]}"
	pkg_arch="${arr[5]}"
	pkg_base_version="${arr[0]}-${arr[4]}"

	aPKGSPLIT=(	$pkg_folder_dir
					$pkg_fullname
					$pkg_arch
					$pkg_base
					$pkg_base_version
					$pkg_version-$pkg_build
					$pkg_build
				)
	return $?
}

function sh_splitpkgre()
{
	file=${1}
	aPKGSPLIT=()

	pkg_folder_dir=$(echo ${file%/*})							#remove arquivo deixando somente o diretorio/repo
	pkg_fullname=$(echo ${file##*/})    						#remove diretorio deixando somente nome do pacote

	[[ $pkg_fullname =~ $PKG_RE ]] &&
		pkg_fullname="${BASH_REMATCH[0]}"
		pkg_base="${BASH_REMATCH[1]}"
		pkg_version_build="${BASH_REMATCH[2]}"
		pkg_version="${BASH_REMATCH[3]}"
		pkg_build="${BASH_REMATCH[4]}"
		pkg_arch="${BASH_REMATCH[5]}"
		pkg_base_version="${pkg_base}-${pkg_version_build}"
: '
  debug " file            : $file\n" \
        "pkg_folder_dir  : $pkg_folder_dir\n" \
	 	  "pkg_fullname    : $pkg_fullname\n" \
	 	  "pkg_arch        : $pkg_arch\n" \
	 	  "pkg_base        : $pkg_base\n" \
		  "pkg_base_version: $pkg_base_version\n" \
		  "pkg_version     : $pkg_version\n" \
		  "pkg_build       : $pkg_build"
'
	aPKGSPLIT=(	"$pkg_folder_dir"
				  	"$pkg_fullname"
					"$pkg_arch"
					"$pkg_base"
					"$pkg_base_version"
					"$pkg_version-$pkg_build"
					"$pkg_build"
					)
	return $?
}

function sh_splitpkg()
{
	local file=${1}
	local pkg_folder_dir
	local pkg_fullname
	local pkg_arch
	local pkg_base
	local pkg_base_version
	local pkg_version
	local pkg_build
	local pkg_str
	local nconta=0
	local char="-"
	local var
	local ra
	local re

	aPKGSPLIT=()
	pkg_folder_dir=$(echo ${file%/*})							#remove arquivo deixando somente o diretorio/repo
	pkg_fullname=$(echo ${file##*/})    						#remove diretorio deixando somente nome do pacote
	pkg_arch=$(echo ${pkg_fullname%.${PRG}*}) 				#remove extensao pacote (chi.zst/mz)
	pkg_arch=$(echo ${pkg_arch%.arch1*}) 						#remove extensao pacote (chi.zst/mz)
	pkg_arch=$(echo ${pkg_arch##*-}) 							#remove do começo até o ultimo -

	pkg_str=$(echo ${pkg_fullname%-any.${PRG}*}) 			#remove extensao pacote (chi.zst/mz)
	pkg_str=$(echo ${pkg_str%.${PRG}*}) 						#remove extensao pacote (chi.zst/mz)
	pkg_str=$(echo ${pkg_str%-x86_64*}) 						#remove extensao pacote (chi.zst/mz)
	pkg_str=$(echo ${pkg_str%.${PRG}*})  						#remove extensao pacote (chi.zst/mz)

	IFS='-'																# hyphen (-) is set as delimiter
	read -ra ADDR <<< "$pkg_str"									# str is read into an array as tokens separated by IFS
	for var in "${ADDR[@]}"; do 									# access each element of array
		re='^[a-zA-Z]'
		if [[ "$var" =~ $re ]]; then
			pkg_base="$pkg_base${var}$char"
		else
			((nconta++))
			[[ $nconta -eq 1 ]] && pkg_version=$var || pkg_build=$var
		fi
	done
 	IFS=$SAVEIFS # reset to default value after usage
	pkg_base=${pkg_base%-*}
	pkg_version="${pkg_version}"
	pkg_base_version="${pkg_base}-${pkg_version}-${pkg_build}"
	[[ $pkg_folder = "" ]] && pkg_folder=$pkg_fullname

	aPKGSPLIT=(	$pkg_folder_dir
					$pkg_fullname
					$pkg_arch
					$pkg_base
					$pkg_base_version
					$pkg_version-$pkg_build
					$pkg_build
				)

#	aPKGLIST=${aPKGSPLIT[*]}
#	arr=(${aPKGSPLIT[*]})
	return $?
}

function sh_install()
{
	local param="$@"

	sh_checkdir "OFF"
#	sh_checkparametros $param
	[[ $verbose -eq 0 ]] && (( verbose=1 ))
	sh_listpkgdisp	"$VARCACHE_SEARCH/packages-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	if [[ $public_pkg != "" ]]; then
		[[ -d $VARCACHE_ARCHIVES/ ]] || mkdir -p $VARCACHE_ARCHIVES/
		cd $VARCACHE_ARCHIVES/

		if !(( $LAUTO )); then
			echo
			read -p "${blue}:: ${reset}Continue installation? [Y/n]" LDOWNLOAD
			if [[ $(toupper "${LDOWNLOAD}") = "N" ]]; then
				return
			fi
		fi
      sh_installdownload
      sh_installdoinstallpkg
	fi
	sh_cdroot
}

function sh_installdownload()
{
	for i in $public_pkg; do
		sh_splitpkg ${i}
		local cfullfilename=${aPKGSPLIT[PKG_FULLNAME]}
		local cpacote=${aPKGSPLIT[PKG_FULLNAME]}
		local cpacotebase=${aPKGSPLIT[PKG_BASE]}
		test -e $VARCACHE_ARCHIVES/$cpacote || sh_wgetpartial $i
		local error_value=${?}
		if [ ${error_value} -ne 0 ]; then
			log_failure_msg2 "ERROR: Downloading ${orange}${cfullfilename}"
			log_wait_msg "Restarting download ${orange}${cfullfilename}"
			sh_wgetfull
			local error_value=${?}
			if [ ${error_value} -ne 0 ]; then
				log_failure_msg2 "ERROR: Fatal error downloading ${orange}${cfullfilename}. ${reset}"
				exit 1
			fi
		fi
	done
}

function sh_installdoinstallpkg()
{
	local LINSTALLED=$false

	for i in $public_pkg; do
		sh_splitpkg ${i}
		local cfullfilename=${aPKGSPLIT[PKG_FULLNAME]}
		local cpacote=${aPKGSPLIT[PKG_FULLNAME]}
		local cpacotebase=${aPKGSPLIT[PKG_BASE]}
		local cBaseVersion=${aPKGSPLIT[$PKG_BASE_VERSION]}

		case $cpacotebase in
			gcc)	      log_failure_msg2 "Skipping package: $cpacotebase"; continue;;
			gcc-libs)   log_failure_msg2 "Skipping package: $cpacotebase"; continue;;
			glibc)	   log_failure_msg2 "Skipping package: $cpacotebase"; continue;;
			file)	      log_failure_msg2 "Skipping package: $cpacotebase"; continue;;
			flac)	      log_failure_msg2 "Skipping package: $cpacotebase"; continue;;
		esac

		local cpacoteinstalled=$(grep ^$cpacotebase$SEP ${VARCACHE_SEARCH}/packages-installed-split | cut -d$SEP -f6)
		[[ "$cpacoteinstalled" == "$cBaseVersion" ]] && LINSTALLED=$true || LINSTALLED=$false
		if (( $LINSTALLED )) && !(( $LFORCE )); then
			log_failure_msg2 "${orange}${cBaseVersion} ${reset}Package is already installed. Use the -f option to force reinstallation."
			continue
		fi
		sh_installpkg ${cpacote}
		local error_value=${?}
		if [ ${error_value} -ne 0 ]; then
			log_failure_msg2 "${red}ERROR:${reset} installing package: ${orange}${cpacote}${reset}"
		else
			log_success_msg2 "${green}${cpacote} ${reset}Done. package installation successfully."
		fi
	done
}

function sh_search()
{
	local oldverbose=$verbose
	local param=$@

	[[ $verbose -gt 1 ]] || (( verbose=0 ))
	LDEPS=$false; sh_listpkgdisp "$VARCACHE_SEARCH/packages-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	if [[ $public_pkg != "" ]]; then
		for i in $public_pkg; do
			sh_splitpkg ${i}
			local cfullname=${aPKGSPLIT[1]}.desc
			local cBase=${aPKGSPLIT[$PKG_BASE]}
			local cBaseVersion=${aPKGSPLIT[$PKG_BASE_VERSION]}
			local cpacote=${aPKGSPLIT[$PKG_BASE_VERSION]}.desc
			local cVersion=${aPKGSPLIT[$PKG_VERSION]}
			local cBuild=${aPKGSPLIT[$PKG_BUILD]}
			local	error_value=0

			cpacote=$VARCACHE_ARCHIVES/$cfullname
			if [[ $LFORCE = $true ]] || ! [[ -e ${cpacote} ]]; then
				sh_wgetdesc
	    		error_value="${?}"
			fi

    		if [[ ${error_value} = 0 ]]; then
				sh_ShortCatPkg "$cpacote" $true
    		else
    			log_failure_msg2 "ERROR Downloading ${red}$cfullname${reset}"
    		fi

		done
	fi
	verbose=$oldverbose
}

function sh_listmeta()
{
	local LLIST=$true
	local Cont=0

	sh_checkdir "OFF"
	log_wait_msg "${blue}Reading meta package lists in the repository..."
	param=$1

	#if (( $LALL )); then
#		metapkg=$(cat $VARCACHE_SEARCH/folders_metapackages)
#	else
#		metapkg=$(grep $param $VARCACHE_SEARCH/folders_metapackages)
#	fi


	for s in ${param[@]}; do
		cListSearch="$cListSearch $(echo ${s})"
	done

	if (( $LALL )) || [[ "$cListSearch" == "" ]]; then
		if (( $LALL )); then
			metapkg=$(cat $VARCACHE_SEARCH/folders_metapackages)
		else
			log_failure_msg2 "${red}error${reset}: nenhum alvo definido (use -h para obter ajuda)"
			exit 1
		fi
	else
		for x in ${cListSearch}; do
			if (( $LEXACT )); then
				metapkg="$metapkg $(grep ^$x.meta$ $VARCACHE_SEARCH/metapackages)"
			else
				metapkg="$metapkg $(grep $x $VARCACHE_SEARCH/folders_metapackages)"
			fi
		done
	fi

	[[ $(toupper "${2}") = "OFF" ]] && LLIST=$false || LLIST=$true
	log_success_msg2 "${blue}Listing... Done"

	if [[ $metapkg != "" ]]; then
		for i in $metapkg; do
			[[ $LLIST = $true ]] && log_success_msg2 "${blue}FOUND ${orange}$i"
			((Cont++))
		done
		 [[ $LLIST = $true ]] && log_success_msg2 "($Cont) meta package(s) found."
	else
		 log_failure_msg2 "${red}${param} NOT FOUND ${reset} ${orange}$i${reset}"
		 log_failure_msg2 "($Cont) meta package(s) found."
		 echo
		 echo -e "${reset}Use: # ${0##*/} update - to update with the repository${reset}"
	fi
	sh_cdroot
}

function sh_meta()
{
	local param=$@
	local cmetafile
	local i
	local pkgInMeta

	sh_listmeta $param

	if [[ -n $metapkg ]]; then
		if !(( $LAUTO )); then
			echo
			read -p "Install meta package(s)? [Y/n]" LDOWNLOAD
			if [[ $(toupper "${LDOWNLOAD}") = "N" ]]; then
				return
			fi
			LAUTO=$true
		fi
		cd $VARCACHE_ARCHIVES/

		for cmetafile in $metapkg; do
			local cmetabase=$(echo $cmetafile | cut -d/ -f1)
			local cmetapackage=$(echo $cmetafile | cut -d/ -f2)

			if !(( $GITSITE )); then
				#site normal
            curl --silent -k -O "${SITE}/packages/$cmetafile"
			else
				#repositorio github
				curl --silent -k -O "${RAW}/packages/$cmetafile"
			fi

			pkgInMeta=$(cat $VARCACHE_ARCHIVES/$cmetapackage)

			for i in $pkgInMeta; do
				local cfile=$i
				local cpacote=${i}
				local LINSTALLED=$false

				pkginstalled=
				pkginstalled="$pkginstalled $(grep ^$cpacote: $VARCACHE_SEARCH/packages-installed-split | cut -d$SEP -f1)"

				{	local item
					index=0
					for item in ${pkginstalled[*]}
					do
						[ $item = $cpacote ] && { LINSTALLED=$true; break; }
						((index++))
					done
				}

				if (( $LINSTALLED )) && !(( $LFORCE )); then
   				log_failure_msg2 "${orange}${cpacote} ${reset}Package is already installed. Use the -f option to force reinstallation."
               continue
				fi

				pkg=$(grep ^$cpacote: $VARCACHE_SEARCH/packages-split | cut -d$SEP -f5)
				if [[ $pkg = "" ]]; then
					log_warning_msg "${orange}${cpacote} ${red}WARNING!! package not in repo! Use 'fetch update' to update the database"
         		continue
				fi

				sh_splitpkg $pkg
				i=$pkg
				cpacote=${aPKGSPLIT[$PKG_FULLNAME]}
				cBaseVersion=${aPKGSPLIT[PKG_BASE_VERSION]}

				test -e $VARCACHE_ARCHIVES/$cpacote || sh_wgetpartial
				#sh_checksha256sum

				local error_value="${?}"
				if [ ${error_value} -ne 0 ]; then
					log_failure_msg2 "ERROR: Checking sha256sum ${cpacote}.sha256... FAIL"
    				log_wait_msg "Restarting download ${cpacote}..."
    				sh_wgetpartial
    				#sh_checksha256sum
					local error_value="${?}"
					if [ ${error_value} -ne 0 ]; then
						log_failure_msg2 "ERROR: Checking sha256sum ${cpacote}.sha256... FAIL. Aborting..."
						exit 1
					fi
				fi

				if !(( $LINSTALLED )); then
					log_info_msg "Installing package ${orange}$cpacote"
				else
					log_info_msg "Reinstalling package ${orange}$cpacote"
				fi

				#ERROR=$(sh_installpkg $cpacote 2>&1>/dev/null)
				sh_installpkg $cpacote
				evaluate_retval

				local error_value="${?}"
				if [ ${error_value} -ne 0 ]; then
					log_failure_msg2 "ERROR: installing package ${orange}${cpacote}... FAIL"
				fi
			done
		done
	fi
	sh_cdroot
}

function sh_recreatefilepackagesinstalled()
{
	local param=$@
	local pkgNumber=0
	local s

	log_msg "Recreating list of installed packages"
	if (( verbose >= 2 )); then
		log_wait_msg "Reading lists of installed packages"
		log_wait_msg "Checking packages installed"
	fi
	printf '' > "$VARCACHE_SEARCH/packages-installed-split" &> /dev/null

	pushd $VARLIB_DESC/ &>/dev/null
	aCachedesc=($(echo *.desc))
	local nfilesinstalled=${#aCachedesc[*]}

	if (( nfilesinstalled )); then
		if (( verbose >= 2 )); then
			sh_cabec $nfilesinstalled
		fi
		for item in ${aCachedesc[*]}; do
			cfileinstalled=$(echo ${item%.desc*})
			cfileinstalled=$(echo ${cfileinstalled%.${PRG}*})
			(( pkgNumber++ ))
			if (( verbose >= 2 )); then
				sh_write $cfileinstalled "5" $pkgNumber
			fi
			sh_ascanpkg "$cfileinstalled" "5"
			cline="${aPKGARRAY[0]}$SEP${aPKGARRAY[1]}$SEP${aPKGARRAY[2]}$SEP${aPKGARRAY[3]}$SEP${aPKGARRAY[4]}$SEP${aPKGARRAY[5]}$SEP${aPKGARRAY[6]}"
			echo "${cline}" >> $VARCACHE_SEARCH/packages-installed-split
			if ! [[ -e $VARCACHE_INSTALLED/${cfileinstalled} ]]; then
				printf '' > "$VARCACHE_INSTALLED/${cfileinstalled}"
				echo "$USER|$(date)|yes" >> $VARCACHE_INSTALLED/${cfileinstalled}
			fi
			mv $item $cfileinstalled.desc  &> /dev/null    #consertar pacotes antigos
		done
	fi
	cat $VARCACHE_SEARCH/packages-installed-split|sort|uniq >/tmp/packages-installed-split
	cp /tmp/packages-installed-split $VARCACHE_SEARCH/packages-installed-split
	rm -f /tmp/packages-installed-split
	popd  &>/dev/null
	return $nfilesinstalled
}

function sh_listinstalled()
{
	local param=$@
	local pkgNumber=0
	local s
	local cListSearch
	local ntotalpkg=0
	local arr

	if (( verbose )); then
		log_msg "Listing packages installed"
	fi
	LLIST=$true
	LALL=$false
	LDEPS=$false
	SPLITPOS='0'

	if [[ "$param" == "" ]]; then
		LALL=$true
	fi

	sh_listpkgdisp "$VARCACHE_SEARCH/packages-installed-split" ${param}
	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}
}

function sh_listforinstall()
{
	local pkgNumber=0
	local s
	local param=$@
	local LLIST=$true
	local LEXACT=$false
	local LALL=$false
	local LDEPS=$true
	local ncontapkg=0
	local cListSearch
	local arr

	[[ -e $VARCACHE_SEARCH/packages-installed-split ]] || printf '' > "$VARCACHE_SEARCH/packages-installed-split"
	public_ntotal_pkg_installed=$(grep ^ $VARCACHE_SEARCH/packages-installed-split | wc -l)
	public_ntotal_pkg_listed=$public_ntotal_pkg_installed
	public_pkg=

	for s in ${param[@]}; do
		[[ $(toupper "${s}") = "--NODEPS" ]]    && { LDEPS=$false; continue; }
		[[ $(toupper "${s}") = "-Y" ]]    && { LAUTO=$true; continue; }
     	[[ $(toupper "${s}") = "-F" ]]    && { LFORCE=$true; continue; }
     	[[ $(toupper "${s}") = "OFF" ]]   && { LLIST=$false; continue; }
     	[[ $(toupper "${s}") = "ON"  ]]   && { LLIST=$true; continue; }
		[[ $(toupper "${s}") = "EXACT" ]] && { LEXACT=$true; continue; }
		[[ $(toupper "${s}") = "ALL" ]]   && { LALL=$true; continue; }
		cListSearch="$cListSearch $(echo ${s})"
	done

	if (( $LALL )) || [[ "$cListSearch" == "" ]]; then
		if (( $LALL )); then
			public_pkg=$(grep ^ $VARCACHE_SEARCH/packages-split | cut -d$SEP -f5)
		else
			log_failure_msg2 "${red}error${reset}: nenhum alvo definido (use -h para obter ajuda)"
			exit 1
		fi
	else
		for x in ${cListSearch}; do
			if (( $LEXACT )); then
				if [[ "$SPLITPOS" == "0" ]]; then
					public_pkg="$public_pkg $(grep ^$x: $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)"
				else
					public_pkg="$public_pkg $(grep ^$x: $VARCACHE_SEARCH/packages-split | cut -d$SEP -f5)"
				fi
			else
				if [[ "$SPLITPOS" == "0" ]]; then
					public_pkg="$public_pkg $(grep $x $VARCACHE_SEARCH/packages-split | cut -d$SEP -f1)"
				else
					public_pkg="$public_pkg $(grep $x $VARCACHE_SEARCH/packages-split | cut -d$SEP -f5)"
				fi
			fi
		done
	fi

	if (( $LLIST )); then
   	arr=(${public_pkg[*]})
   	ncontapkg=${#arr[*]}
		if [[ "${#public_pkg}" -gt 0 ]]; then # pacote?
			pkgNumber=0
  			sh_getdeps $LDEPS
      	arr=(${public_pkg[*]})
      	ncontapkg=${#arr[*]}
			public_ntotal_pkg_listed=$ncontapkg
		else
			log_msg "($pkgNumber) package(s) found."
			echo
			echo -e "${reset}Use: # ${APP} -Sy - to update with the repository${reset}"
		fi
	else
		pkgNumber=0
		for i in $public_pkg; do
			((pkgNumber++))
		done
		public_ntotal_pkg_listed=$pkgNumber
	fi
	sh_cdroot
	return $pkgNumber
}

function _LIST_ARCHIVES_DIRECTORIES()
{
	local packname="${1}.list"
	local LIST_CLEAN_DIRECTORIES

	sed -i "
        s/^\.\///g
        s/^\///g
        s|\/$||g
        /^\./d
        /^ *$/d
        /^bin$/d
        /^info$/d
        /^boot$/d
        /^dev$/d
        /^etc$/d
        /^home$/d
        /^lib$/d
        /^lib64$/d
        /^media$/d
        /^mnt$/d
        /^opt$/d
        /^proc$/d
        /^root$/d
        /^run$/d
        /^sbin$/d
        /^srv$/d
        /^sys$/d
        /^tmp$/d
        /^usr$/d
        /^var$/d
        /^info\/pos\.sh$/d
        /^info\/pre\.sh$/d
        /^info\/desc/d
        /info\/rm.sh/d
        /^var\/lib\/banana\/list\/.*\.list/d
        /^var\/lib$/d
        /^var\/lib\/banana/d
        /^var\/lib\/banana\/list/d
        /^var\/lib\/banana\/remove/d
	" "${VARLIB_LIST}/${packname}"

	LIST_CLEAN_DIRECTORIES=(
		'var'
		'lib'
		'media'
		'usr'
		'usr/share'
		'srv'
	)

	while read view; do
		if [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[0]}/(cache|lib|local|lock|log|mail|opt|run|spool|tmp)$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^$view$/d" "${VARLIB_LIST}/${packname}"
		elif [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[1]}/(lib64)$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^$view$/d" "${VARLIB_LIST}/${packname}"
		elif [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[2]}/(cdrom|floppy)$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^$view$/d" "${VARLIB_LIST}/${packname}"
		elif [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[3]}/(bin|etc|lib|lib\/(pkgconfig)|local|share|doc|include|libexec|sbin|src)$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^$view$/d" "${VARLIB_LIST}/${packname}"
		elif [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[4]}/(keymaps|fonts|pixmaps|applications|doc|man|man\/man[[:digit:]]+|man\/.{2})$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^$view$/d" "${VARLIB_LIST}/${packname}"
		elif [[ "$view" =~ ^${LIST_CLEAN_DIRECTORIES[5]}/(www|httpd)$ ]]; then
			local view="${view//\//\\/}"
			sed -i "/^${view}$/d" "${VARLIB_LIST}/${packname}"
		fi
	done < "${VARLIB_LIST}/${packname}"
}

function retstat()
{
	[[ "$?" -ne '0' ]] && return 1 || return 0
}

function _SUBSHELL_STATUS()
{
	[[ "$?" -ne '0' ]] && return 1 || return 0
}

function _MANAGE_SCRIPTS_AND_ARCHIVES()
{
	sh_splitpkg "${1}"
	local packname=${aPKGSPLIT[PKG_BASE_VERSION]}
	local dir_desc="${VARLIB_LIST/list/desc}"

	if ! [[ -e "/tmp/info/desc" ]]; then
		log_failure_msg2 "ERROR! /info/desc does not exist. ABORT!"
		return 1
	fi

	pushd "/tmp/info/" &>/dev/null

	if ! mv 'desc' "$VARLIB_DESC/${packname}.desc" ; then
		log_failure_msg2 "ERROR! could not move desc to /${dir_desc}/${packname}.desc"
		log_failure_msg2 "ABORTING..."
		return 1
	fi

	if [[ -e "pos.sh" ]]; then
		bash "pos.sh"
	fi

	if [[ -e "/tmp/info/.INSTALL" ]]; then
		source .INSTALL &> /dev/null
		post_install
		post_upgrade
	fi

	if [[ -e "rm.sh" ]]; then
		if ! mv 'rm.sh' "$VARLIB_REMO/${packname}.rm" ; then
			log_failure_msg2 "ERROR! could not move rm.sh to $VARLIB_REMO/${packname}.rm"
			log_failure_msg2 "ABORTING..."
			return 1
		fi
    fi

	popd &>/dev/null
	[[ -d "/info/"     ]] && rm -r "/info/"
	[[ -d '/tmp/info/' ]] && rm -r "/tmp/info/"
	[[ -e '/.BUILDINFO' ]] && rm "/.BUILDINFO"
	[[ -e '/.MTREE' ]] && rm "/.MTREE"
	[[ -e '/.PKGINFO' ]] && rm "/.PKGINFO"
	[[ -e '/.INSTALL' ]] && rm "/.INSTALL"
	return 0
}

function _CREATE_LIST()
{
	local packname="$1"

	if ! tar --force-local --list --file "$packname" > "${VARLIB_LIST}/${name_version_build}.list"; then
		log_failure_msg2 "ERROR! Can not create ${VARLIB_LIST}/${name_version_build}.list"
		return 1
	fi
	return 0
}

function _INPUT_NULL_PARAMETER()
{
	pkg=$1

	local arr
	if [[ -z "$pkg" ]]; then
		pkg=$(echo $PWD | sed 's/\// /g' | awk '{print $NF}'|sed 's/-/_/g'| sed 's/\(.*\)_/\1 /'|sed 's/ /-/g')
		arr=($pkg)
		[[ ${#arr[*]} -gt 2 ]] && pkg="${arr[0]}_${arr[1]} ${arr[2]}"
		pkg=${pkg}-${DESC_BUILD}
	fi
	sh_info "INPUT_NULL" $pkg
	return 0
}

function _NAME_FORMAT_PKG()
{
	local packname="$1"

	re="\b${PKG_EXT}\b"
	if ! [[ "$packname" =~ .*\.${re}$ ]]; then
		log_failure_msg2 "ERROR Package need finish .${PKG_EXT}"
		return 1
	fi
	return 0
}

function _GENERATE_DESC()
{
	local i
	local DESC_PACKNAME="$1"
	local DESC_VERSION="$2"
	local DESC_BUILD="$3"
	DESC=$(echo "${DESC//\'}") 		## remove apostrofe. ex: let´s => lets

	[[ ! -d "info" ]] && mkdir info

	if [ -e info/desc ]; then
		evaluate_retval
		(( ncount++ ))
		if !(( $LFORCE )); then
			log_info_msg "$(fmt)${orange} info/desc ${reset}already exist. Skipping... Use the -f option to force recreate."
			return
		else
			log_info_msg "$(fmt)${orange} info/desc ${reset}already exist. Rewriting"
		fi
	fi
	_CAT > "info/desc" << EOF
######################################################################
# Generated with fetch
# Generated with alienpkg
######################################################################
maintainer='$MAINTAINER'
pkgname='$DESC_PACKNAME'
version='$DESC_VERSION'
build='$DESC_BUILD'
license='$LICENSE'
lfs_version='$LFS_VERSION'
lfs_init='$LFS_INIT'
arch='$ARCH'
distro='$DISTRO'
desc='$DESC'
size='$SIZE'
url='$URL'
dep=('')
EOF

	for i in ${deps[*]}
	do
		echo depend="'$i'" >> $descme
	done
	return 0
}

function sh_generatepkg()
{
	shift
	local param=$@
	local inc=0

	if [[ ${#param} -eq 0 ]]; then # run standalone
		LAUTO=$true
#		LFORCE=$true
		LLIST=$false
		pkg="${PWD##*/}"
	else
		for s in ${param[@]}; do
			if [[ $(toupper "${s}") = "-Y" ]]; then
				LAUTO=$true
			elif [[ $(toupper "${s}") = "-F" ]]; then
				LFORCE=$true
			elif [[ $(toupper "${s}") = "OFF" ]]; then
				LLIST=$false
			else
				pkg="$s"
				continue
			fi
		done
	fi

	(( ncount++ ))
	log_info_msg "$(fmt) Generating info for package $pkg"
	if [[ ! -e "info/desc" ]]; then
		LFORCE=$true
	fi
	if (( $LAUTO )) || (( $LFORCE )); then
		#for take in 'field_pkgname' 'field_version' 'field_build'; do
		#	let inc++
		#	eval $take="$(echo "$pkg" | cut -d '-' -f ${inc})" # Expanda e pegue o seu devido valor
		#done

		if [[ -z "$DESC_PACKNAME" ]]; then
			sh_splitpkg ${pkg}
			field_pkgname=${aPKGSPLIT[$PKG_BASE]}
			field_version=${aPKGSPLIT[$PKG_VERSION]}
			field_build=${aPKGSPLIT[$PKG_BUILD]}
	    else
    		field_pkgname=${DESC_PACKNAME}
    		field_version=${DESC_VERSION}
	    	field_build=${DESC_BUILD}
	   fi
	   [[ -z "$field_build" ]] && field_build=$DESC_BUILD
#		[[ -z "$DESC" ]] && DESC="$field_pkgname-$field_version-$field_build"
		[[ -z "$DESC" ]] && DESC="$field_pkgname-$field_version"
		_GENERATE_DESC "$field_pkgname" "$field_version" "$field_build" || return 1
	fi
	evaluate_retval
	unset check_var
	return 0
}

function sh_doinstallpkg()
{
	(
	local packname="$1"
	local name_version_build
	local tmp_pack
	local PRE_SH='pre.sh'
	local INSTALL_SH='.INSTALL'

	if ! tar -h --force-local --use-compress-program=zstd --extract --preserve-permissions --touch --file "${packname}" -C "/tmp/" "./${descme}"; then
		log_failure_msg2 "${red}ERROR! ${reset}I could not unzip the file: ${orange}${packname}.desc${reset}"
		return 1
	fi
	source "/tmp/${descme}" || log_failure_msg2 "ERROR! Not load ${descme}"
	if [[ ! -e "/tmp/${descme}" ]]; then
		log_failure_msg2 "ERROR! Could not load /tmp/${descme}. Archive not exist. ABORT!"
		return 1
	fi

	if tar -h --force-local --use-compress-program=zstd --list --file "${packname}" "./info/$PRE_SH" &>/dev/null; then
		if ! tar -h --force-local --use-compress-program=zstd --extract --preserve-permissions --file "$packname" -C /tmp "./info/$PRE_SH" &>/dev/null; then
			log_failure_msg2 "ERROR! Cannot extract ${PRE_SH}, ABORT"
			return 1
		fi
		bash "/tmp/info/$PRE_SH"
	fi

	if tar -h --force-local --use-compress-program=zstd --list --file "${packname}" "./info/$INSTALL_SH" &>/dev/null; then
		if ! tar -h --force-local --use-compress-program=zstd --extract --preserve-permissions --file "$packname" -C /tmp "./info/$INSTALL_SH" &>/dev/null; then
			log_failure_msg2 "ERROR! Cannot extract ${INSTALL_SH}, ABORT"
			return 1
		fi
	fi

	#name_version_build="${pkgname}-${version}-${build}"
	sh_splitpkg ${packname}
	name_version_build=${aPKGSPLIT[$PKG_BASE_VERSION]}
	tar -h --force-local --use-compress-program=zstd --extract --preserve-permissions --touch --file "${packname}" -C / | tee -a ${VARLIB_LIST}/"${name_version_build}.list" &>/dev/null || return 1

	_CREATE_LIST "$1" || return 1
	_MANAGE_SCRIPTS_AND_ARCHIVES "${name_version_build}" || return 1
	_LIST_ARCHIVES_DIRECTORIES "${name_version_build}"
	)
	_SUBSHELL_STATUS
}

function sh_initinstallpkg()
{
	local pkg=
	local param=$@
	local package
	local arr=
	local nfiles=

	if !(( $LALL )); then
		test $# -lt 1 && die "Missing value for the required argument '$param'. ${yellow}Try ${0##*/} -Sl <package>" 1; _arg_unit="$2"
	fi

	shopt -s nullglob       # enable suppress error message of a command
	if (( $LALL )); then
		pkg="$pkg $(find "$PWD/" "$VARCACHE_ARCHIVES/" -type f -iname "*.${PRG}")"
	else
		for s in ${param[@]}; do
			cfile=$(echo $s | sed 's/\// /g' | awk '{print $NF}')
			pkg="$pkg $(find "$PWD/" "$VARCACHE_ARCHIVES/" -type f -iname "*.${PRG}" | grep "$cfile")"
		done
	fi

	pkgCheckNumber=0
	LLIST=$true
	arr=(${pkg[*]})
	nfiles=${#arr[*]}

	if (( $nfiles )); then # pacote?
		for i in $pkg; do
			[[ $LLIST = $true ]] && log_success_msg2 "${blue}FOUND local package ${orange}$i"
			((pkgCheckNumber++))
		done

		if (( $pkgCheckNumber )); then
			if !(( $LAUTO )); then
				echo
				conf "$(DOT)continue installation?"
				LAUTO=$?
			fi
		fi

		if (( $LAUTO )); then
			for package in $pkg
			do
				log_wait_msg "Installing local package ${orange}$package"
				#ERROR=$(sh_installpkg $package 2>&1>/dev/null)
				sh_installpkg $package
			done
		fi
	else
		msg "${orange}$param ${red}NOT FOUND ${reset}local package in ${orange}${VARCACHE_ARCHIVES}${reset}"
		msg "${orange}$param ${red}NOT FOUND ${reset}local package in ${orange}${PWD} ${reset}"
		printf "${reset}Use: # ${0##*/} -Sy to update with the repository${reset}\n"
	fi
	shopt -u nullglob       # disable suppress error message of a command
}

function sh_installpkg()
{
	local retval=0
	local _pkg=

	while [[ -n "$1" ]]; do
		sh_doinstallpkg "$1" || return 1
		local retval=${?}
		if [ ${retval} -eq 0 ]; then
			sh_splitpkg "$1"
			cfileinstalled=${aPKGSPLIT[PKG_BASE_VERSION]}
			_pkg=${aPKGSPLIT[PKG_BASE_VERSION]}
			[[ $retval = 0 ]] && > ${VARCACHE_INSTALLED}/${_pkg}
			[[ $retval = 0 ]] && echo "$USER|$(date)|yes" >> $VARCACHE_INSTALLED/${_pkg}
			[[ $retval = 0 ]] && sed -i '/'${_pkg}'/d' $VARCACHE_SEARCH/packages-installed-split
			sh_ascanpkg "$cfileinstalled" "5"
			local retvalascan=${?}
			if (( $retvalascan )); then
				cline="${aPKGARRAY[0]}$SEP${aPKGARRAY[1]}$SEP${aPKGARRAY[2]}$SEP${aPKGARRAY[3]}$SEP${aPKGARRAY[4]}$SEP${aPKGARRAY[5]}$SEP${aPKGARRAY[6]}"
				echo "${cline}" >> $VARCACHE_SEARCH/packages-installed-split
			fi
		fi
		shift
	done
	return $retval
}

function _REMOVE_NOW()
{
	local packname="${1/%.${PKG_EXT}/}"
	local a='0'
	local d='0'
	local l='0'
	local archive

	[[ -z "$name_version_build" ]] && { log_failure_msg2 "ERROR! Variable 'name_version_build' NULL. ABORT"; return 1 ;}
	pushd "/" &>/dev/null

	if [[ -e "${VARLIB_REMO}/${packname}.rm" ]]; then
		sed -E "/rm[[:space:]]+\-(rf|fr)/d" "${VARLIB_REMO}/${packname}.rm" &>/dev/null
		bash "${VARLIB_REMO}/${packname}.rm"
		if [[ -e "${VARLIB_REMO}/${packname}.rm" ]]; then
			rm "${VARLIB_REMO}/${packname}.rm"
		fi
	fi

	while IFS= read thefile; do
		if [[ -f "$thefile" ]]; then
			rm "$thefile" &>/dev/null && print "Delete\t${thefile}"
		fi
	done < "${VARLIB_LIST}/${packname}.list"
	unset archive

	while IFS= read thelink; do
		if [[ -L "$thelink" ]]; then
			unlink "$thelink" &>/dev/null
		fi
	done < "${VARLIB_LIST}/${packname}.list"
	unset archive

	while IFS= read thedir; do
		if [[ -d "$thedir" ]] && [[ -z "$(ls -A ${thedir})" ]]; then
			rmdir -p "${thedir}" &>/dev/null
		fi
	done < "${VARLIB_LIST}/${packname}.list"

	for removeitem in "desc" "list"; do
		case $removeitem in
			desc)   DIREC="$VARLIB_DESC";;
			list)   DIREC="$VARLIB_LIST";;
		esac
		if [[ -e "${DIREC}/${packname}.${removeitem}" ]]; then
			if ! rm "${DIREC}/${packname}.${removeitem}"; then
				log_failure_msg2 "ERROR! It was not possible remove ${DIREC}/${packname}.list"
				return 1
			fi
		else
			continue
		fi
	done
	popd &>/dev/null
	IFS=$SAVEIFS
	return 0
}

function _GPG_SIGN()
{
	local package="$1"
	local sig='sig'

	#Pacote existe?
	if [[ ! -e "${package}.${PKG_EXT}" ]]; then
		printf "${red}[ERRO]${end} Unable to sign package. ${package}.${PKG_EXT}\n"
		printf "Reason: Package not found.\n"
		printf "For security reasons, do not pass the package on to third parties.\n"
		return 1
	fi

	[ "$REWRITE_SIG" = "1" ] && rm -f ../${package}.${PKG_EXT}.${sig}
	[ "$REWRITE_SIG" = "1" ] && rm -f ${package}.${PKG_EXT}.${sig}

	which gpg &> /dev/null
	if [ $? = 0 ]; then
		#Gerando Assinatura no pacote
		gpg --detach-sign --pinentry-mode loopback "${package}.${PKG_EXT}" &>/dev/null || \
		gpg --detach-sign "${package}.${PKG_EXT}" || return 1
		echo -e "${blue}[Create]${end} Your ${sig} on:   ../${package}.${PKG_EXT}.${sig}"
	fi
	return 0
}

function _VERIFY_ON()
{
	local package="$1"

	#sh_generatepkg "$1"

	(
	local dir_info='info'  # Diretorio info que contem informações como (desc)
	local info_desc='desc' # Descrição do pacote

	if [[ ! -d "$dir_info" ]]; then # Diretório info existe?
		log_failure_msg2 "${red}[ERROR!]${end} ${pink}${dir_info}${end} directory\n"
		log_failure_msg2 "It's necessary your package have the DIRECTORY ${pink}info${end}."
		log_failure_msg2 "${pink}${dir_info}${end} its a directory store important archives."
		log_failure_msg2 "For more information use -h, --help."
		exit 77
	elif [[ ! -e "${dir_info}/${info_desc}" ]]; then
		log_failure_msg2 "${red}[ERROR!]${end} ${pink}${info_desc}${end} archive\n"
		log_failure_msg2 "It's necessary your package have the ARCHIVE ${pink}desc${end} inside of directory '${dir_info}'."
		log_failure_msg2 "${pink}${info_desc}${end} have informations of your package."
		log_failure_msg2 "For more information use -h, --help."
		exit 1
	else
		# Se caiu aqui está tudo certo, vamo então conferir as variaveis do 'desc'
		# Se alguma variavel estiver nula não podemos continuar.
		source ${dir_info}/${info_desc} # Carregando arquivo.

		if [[ -z "$maintainer" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, sh_VARIABLE ${blue}maintainer${end} null"
			log_failure_msg2 "Enter the name of the package maintainer into variable maintainer."
			#exit 1
		elif [[ -z "$pkgname" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, VARIABLE ${blue}pkgname${end} null"
			log_failure_msg2 "Enter the name of the package into variable pkgname."
			#exit 1
		elif [[ -z "$version" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, VARIABLE ${blue}version${end} null"
			log_failure_msg2 "Enter a version of software into variable version."
			#exit 1
		elif [[ -z "$build" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, VARIABLE ${blue}build${end} null"
			log_failure_msg2 "Enter the build number of package."
			#exit 1
		elif [[ -z "$desc" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, VARIABLE ${blue}desc${end} null"
			log_failure_msg2 "Detail a small description into variable desc."
			#exit 1
		elif [[ -z "$url" ]]; then
			log_failure_msg2 "Check ${pink}${info_desc}${end}, VARIABLE ${blue}url${end} null"
			log_failure_msg2 "Enter a url of project/software into variable url."
			#exit 1
		fi

        # Conferindo se o nome do pacote e versão batem com o que
        # o usuario passou em linha, se não bater não devemos continuar.

#        if [[ "$pkgname" != "$(echo "$package" | cut -d '-' -f '1')" ]]; then
#            echo -e "Check ${pink}${info_desc}${end}, VARIABLE ${blue}pkgname${end} it different"
#            echo "of the name you entered as an argument. Check and return ;)"
#            exit 1

#        elif [[ "$version" != $(echo "$package" | cut -d '-' -f '2' | sed 's/\.'${PKG_EXT}'//') ]]; then
#            echo -e "Check ${pink}${info_desc}${end}, VARIABLE ${blue}version${end} it different"
#            echo "of the version you entered as an argument. Check and return ;)"
#            exit 1

#        elif [[ "$build" != $(echo "$package" | cut -d '-' -f '3' | sed 's/\.'${PKG_EXT}'//') ]]; then
#            echo -e "Check ${pink}${info_desc}${end}, VARIABLE ${blue}build${end} it different"
#            echo "of the version you entered as an argument. Check and return ;)"
#            exit 1
#        fi
		fi

		#Verificando se rm -rf está presente em um dos scripts.
		for check_script in 'pre.sh' 'pos.sh' 'rm.sh'; do
			if [[ -e "${dir_info}/${check_script}" ]]; then
			if _GREP 'rm[[:space:]]+\-(rf|fr)' "${dir_info}/${check_script}" &>/dev/null; then
				log_failure_msg2 "${red}[CRAZY!]${end} ${PWD}/${dir_info}/$check_script contain command rm -rf. ABORTED NOW."
				return $false
			fi
		fi
   	done
 	)
	_SUBSHELL_STATUS
}

function _CREATE_PKG()
{
	local package="${1/%.${PKG_EXT}/}"
	local ext_desc='desc'

	if tar --force-local --use-compress-program="zstd -19" --create --file ../${package}.${PKG_EXT} .; then
		cp "$descme" ../${package}.${PKG_EXT}.${ext_desc} &>/dev/null
		pushd .. &>/dev/null
		if (( $CREATE_SHA256 )); then
			sha256sum ${package}.${PKG_EXT} > ${package}.${PKG_EXT}.sha256
		fi
		if (( $GPG_SIGN )); then
			_GPG_SIGN "${package}" || return 1
			popd &>/dev/null
		else
			return 0
		fi
	fi
	evaluate_retval
}

function sh_createpkg()
{
	shift
	local param=$@
	local s
	local ret

	for s in ${param[@]}
	do
		if [[ $(toupper "${s}") = "-Y" ]]; then
			LAUTO=$true
		elif [[ $(toupper "${s}") = "-F" ]]; then
			LFORCE=$true
		elif [[ $(toupper "${s}") = "OFF" ]]; then
			LLIST=$false
		else
			pkg="$s"
			#break
			continue
		fi
	done

	if [[ -z "$pkg" ]] ; then
		local pkg=$(echo $PWD |sed 's/\// /g'|awk '{print $NF}')
	fi

	log_wait_msg "$(fmt) Building package $pkg"
	sh_generatepkg $pkg $pkg -Y $4 $5
	_NAME_FORMAT_PKG "$pkg.${PKG_EXT}" || exit 1
	_VERIFY_ON "$pkg"
	ret=$?
	if [ $ret -ne 0 ]; then
		exit 1
	fi
	_CREATE_PKG "$pkg" || exit 1
	(( ncount++ ))
	log_info_msg "$(fmt) Generating package $pkg"
	unset check_var
	evaluate_retval
}

function sh_alienpkg_pkgsize()
{
	size="$(du -sk --apparent-size)"
   size="$(( ${size%%[^0-9]*} * 1024 ))"
}

function sh_alienpkg_initvars()
{
	unset BUILDDIR
	unset size
	ALIEN_CACHE_DIR="${ALIEN_CACHE_DIR:=/var/cache/pacman/pkg}"
	PKGS=$@
	BUILDDIR="${PKGCORE:=${CACHEDIR}/archives}"
	[[ -n ${BUILDDIR} ]] || BUILDDIR="${CACHEDIR}/archives" &> /dev/null
	[[ -d ${BUILDDIR} ]] || mkdir -p "${BUILDDIR}" &> /dev/null
}

function sh_alienpkg_exec()
{
	local pkg
	local param=$*
	local package
	local LFORCELOCAL=
#	local LFIND=$false
#	local LALL=$false
#	local mtime=0
	local string=
	local ntotalpkg=0
	local ncount=0
	local arraypkg=

	if [[ -z "${param}" ]]; then
		LALL=$true
	fi

#	if [[ $(toupper "${param}") = "--DEFAULT" ]]; then
#		param="all -atime=0 -keep"
#	fi

  	for s in ${param[@]}; do
		string="$string ${s}"
	done

	if (( $LALL )); then
		if !(( $LFIND )); then
			pkg=$(ls -1 $ALIEN_CACHE_DIR/*.{zst,xz})
		else
			pkg=$(find $ALIEN_CACHE_DIR/ -type f -atime $mtime)
		fi
	else
  		for str in ${string[@]}; do
			if !(( $LFIND )); then
				files=$(ls -1 $ALIEN_CACHE_DIR/*.{zst,xz} | grep $str)
				pkg="$pkg $(echo $files | grep $str)"
			else
				files=$(find $ALIEN_CACHE_DIR/*.{zst,xz} -type f -atime $mtime | grep $str)
				pkg="$pkg $(echo $files | grep $str)"
			fi
		done
	fi

	arraypkg=($pkg)
	ntotalpkg=${#arraypkg[*]}
	nfullpkg=${ntotalpkg}
	LFORCELOCAL=$LFORCE

	if [[ "${#arraypkg}" -gt 0 ]]; then # package found?
		for package in $pkg
		do
			packagedir=${package}
			file=${package}
			FULLDIR=$BUILDDIR/$packagedir
			ncount=0

			pkgtar=$(echo ${file##*/})                   #remove diretorio deixando somente nome do pacote
			pkgtar=$(echo ${pkgtar%%.pkg.tar.zst})       #remove .pkg.tar.zst
			pkgtar=$(echo ${pkgtar%%.pkg.tar.xz})        #remove .pkg.tar.xz

			cPacoteSemExt=$(echo ${pkgtar%%.*})          # https://elmord.org/blog/?entry=20121227-manipulando-strings-bash
			cPacoteSemExt=$(echo ${cPacoteSemExt%-*})    # https://elmord.org/blog/?entry=20121227-manipulando-strings-bash

			if !(( $LFORCELOCAL )); then
				local firstletter=${pkgtar::1}
				local FilteredPackage=$pkgtar.chi.zst
				local destpkgGIT="${GITDIR}/packages/${firstletter}/${FilteredPackage}"
				local destpkgCORE="${GITDIR}/packages/core/${FilteredPackage}"

				if [[ -e ${destpkgGIT} ]]; then
					log_failure_msg2 "$(fmt) ${orange}${FilteredPackage} ${reset}Package already exist in ${green}${GITDIR}/packages/${firstletter/}${reset} Use the -f option to force rebuild."
					(( ntotalpkg-- ))
					continue
				fi
				if [[ -e ${destpkgCORE} ]]; then
					log_failure_msg2 "$(fmt) ${orange}${FilteredPackage} ${reset}Package already exist in ${green}${PKGCORE}/${reset} Use the -f option to force rebuild."
					(( ntotalpkg-- ))
					continue
				fi
			fi

			destdir=$BUILDDIR/$pkgtar
			((ncount++))
			log_info_msg "$(fmt) Creating directory $destdir"
			mkdir -p $destdir
			evaluate_retval

			((ncount++))
			log_info_msg "$(fmt) Unpacking package $package at $destdir"
			tar --force-local --extract --file $package -C $destdir >/dev/null 2>&1
			evaluate_retval

			case $packagedir in
				luit-[0-9]* )
				sed -i -e "/D_XOPEN/s/5/6/" configure
				;;
			esac

	#		CFG_FILE=$destdir/.PKGINFO
	#		CFG_CONTENT=$(cat $CFG_FILE | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
	#		eval "$CFG_CONTENT"
	#		info $CFG_CONTENT

	#		while read var value
	#		do
	#		    export "$var" "$value"
	#		done < $destdir/.PKGINFO

			sed -i 's/ = /="/g' $destdir/.PKGINFO  >/dev/null 2>&1
			sed -i 's/$/"/g' $destdir/.PKGINFO  >/dev/null 2>&1
			source "$destdir/.PKGINFO"

			export    ALIEN_DESC_BUILD="${pkgtar: -1}"
			export          DESC_BUILD="${pkgtar: -1}"
			export           ALIEN_URL="$url"
			export                 URL="$url"
			export       ALIEN_LICENSE="$license"
			export             LICENSE="$license"
			export          ALIEN_ARCH="$arch"
			export                ARCH="$arch"
			export          ALIEN_SIZE="$size"
			export                SIZE="$size"
			export          ALIEN_DESC="$pkgdesc"
			export                DESC="$pkgdesc"
			export           ALIEN_DEP="$depend"
			export                 DEP="$depend"
			export ALIEN_DESC_PACKNAME="$pkgname"
			export       DESC_PACKNAME="$pkgname"
			export 	ALIEN_DESC_VERSION="$pkgver"
			export        DESC_VERSION="$pkgver"
			export    ALIEN_DESC_BUILD="${pkgver: -1}"
			export          DESC_BUILD="${pkgver: -1}"
			export deps=$(cat $destdir/.PKGINFO | grep ^depend | awk -F'"' '{print $2}')

			pushd $destdir	>/dev/null 2>&1
			rm -f $destdir/.BUILDINFO >/dev/null 2>&1
			rm -f $destdir/.MTREE     >/dev/null 2>&1
			rm -f $destdir/.PKGINFO   >/dev/null 2>&1

			((ncount++))
			sh_createpkg $pkgtar $pkgtar -Y -F
			sh_alienpkg_pkgsize

			if !(( $LKEEP )); then
				((ncount++))
				log_wait_msg "$(fmt) Verifying candidate package for pruning ${yellow}${GITDIR}/packages/$cPacoteSemExt"
				#removeoldpkgchili $cPacoteSemExt
				((ncount++))
				log_info_msg "$(fmt) Removing ${red}OLD ${reset}package ${yellow}${GITDIR}/packages/$cPacoteSemExt"
				fetchpack -q -c "$GITDIR/packages/" -m /tmp/ "$cPacoteSemExt"
				evaluate_retval
			fi
			echo
			(( ntotalpkg-- ))
		done
	else
		log_failure_msg "${red}error${reset}: ${orange}${x} ${reset}package target ${yellow}${param} ${reset}was ${red}NOT ${reset}found in ${yellow}${ALIEN_CACHE_DIR} ${reset}for import"
	fi
	popd >/dev/null 2>&1
	unset size ncount ntotalpkg
}

function sh_alienpkg_logo()
{
	_CAT << 'EOF'
       _ _                  _
  __ _| (_) ___ _ __  _ __ | | ____ _
 / _` | | |/ _ \ '_ \| '_ \| |/ / _` |
| (_| | | |  __/ | | | |_) |   < (_| |
 \__,_|_|_|\___|_| |_| .__/|_|\_\__, |
                     |_|        |___/
EOF
	sh_version
}

function sh_aliencheck()
{
	allfiles=$(ls -1 *.zst)

	for pkg in $allfiles
	do
		firstletter=${pkg::1}
		FilteredPackage=$(echo $pkg | sed 's/\(.*\)-/\1*/'|cut -d* -f1).chi.zst
		destpkg="${GITDIR}/packages/${firstletter}/${FilteredPackage}"
		if [[ -e ${destpkg} ]]; then
			echo "file exist: ${destpkg}"
		fi
	done
}

function sh_alienpkg_main()
{
	sh_alienpkg_initvars $*
	sh_alienpkg_exec $*
}

function sh_upgrade()
{
	local param="$@"
	local LLIST=$false
	local count=0
	local s
	local item
	local cBaseInstalled cBaseVersionInstalled cVersionInstalled cBuildInstalled
	local	cBase cBaseVersion cVersion cBuild
	local ntotalinstalled
	local ntotalconfered
	local pkgrepo
	local ntotal_pkg_installed
	local ntotal_pkg_listed

#	sh_checkparametros "$@"
#	sh_listinstalled ${param} "OFF" "EXACT"
	[[ $verbose -gt 1 ]] || (( verbose=0 ))
	LDEPS=$false; LEXACT=$true; LLIST=$false; sh_listpkgdisp	"$VARCACHE_SEARCH/packages-installed-split" ${param}

	local ntotal_pkg_installed=${public_ntotal_pkg_installed}
	local ntotal_pkg_listed=${public_ntotal_pkg_listed}

	for i in $public_pkg
	do
		sh_splitpkg "${i}"
		cBaseInstalled=${aPKGSPLIT[PKG_BASE]}
		cBaseVersionInstalled=${aPKGSPLIT[PKG_BASE_VERSION]}
		cVersionInstalled=${aPKGSPLIT[PKG_VERSION]}
		cBuildInstalled=${aPKGSPLIT[PKG_BUILD]}
		pkgrepo=$(grep ^$cBaseInstalled$SEP $VARCACHE_SEARCH/packages-split | cut -d$SEP -f4)
		count=0
		((ntotalconfered++))

		if [[ "${#pkgrepo}" -gt 0 ]]; then # pacote?
			for cPkg in ${pkgrepo}; do
				#debug $cPkg
				sh_splitpkg "${cPkg}"
				cBase=${aPKGSPLIT[PKG_BASE]}
				cBaseVersion=${aPKGSPLIT[PKG_BASE_VERSION]}
				cVersion=${aPKGSPLIT[PKG_VERSION]}
				cBuild=${aPKGSPLIT[PKG_BUILD]}

				case $cBase in
					Python) continue;;
					gtk+)   continue;;
				esac

				if [[ $cBaseInstalled == $cBase ]]; then
					((count++))
					if [[ "$(vercmp $cBaseVersionInstalled $cBaseVersion)" -lt 0 ]]; then
						log_success_msg2 "[$ntotalconfered/$ntotal_pkg_listed]${orange}${cBase} ${reset}is being updated to newest version ($cVersion)."
						sh_doremove $cBaseVersionInstalled "OFF"
						sh_install "$cBase" -y -f --nodeps
					elif [[ "$cBaseVersionInstalled" = "$cBaseVersion" ]]; then
						if (( $LFORCE )); then
							sh_install "$cBase" -y -f --nodeps
							continue
						else
							log_success_msg2 "[$ntotalconfered/$ntotal_pkg_listed]${orange}${cBase} ${reset}is already the newest version ${green}($cVersionInstalled)${reset}. Use the -f option to force reinstallation."
							continue
						fi
					else
						if (( $LFORCE )); then
							sh_install "$cBase" -y -f --nodeps
						else
							log_success_msg2 "[$ntotalconfered/$ntotal_pkg_listed]${orange}${cBase} ${reset}is already the newest version ($cVersionInstalled)."
						fi
						if [ $count -gt 1 ]; then
							log_warning_msg "${orange}${cBaseInstalled} ${red}WARNING!! there is more than one release of the package in the repo!"
						fi
					fi
				else
   	 			log_warning_msg "[$ntotalconfered/$ntotal_pkg_listed]${orange}${cBase} ${reset}not installed."
				fi
			done
		else
			log_warning_msg "[$ntotalconfered/$ntotal_pkg_listed]${orange}${cBaseInstalled} ${red}WARNING!! package not in repo! Use 'fetch update' to update the database"
		fi
	done

	if [[ "${#public_pkg}" -le 1 ]]; then # nenhum pacote?
		log_warning_msg "${orange}${@}${cyan} package not installed"
		echo
		conf "${blue}:: ${reset}Install Pakages(s)?"
		LAUTO=$?
		if (( $LAUTO )); then
			sh_install $param -y -f --nodeps
		fi
	fi
	sh_cdroot
}

function checkDependencies()
{
  local errorFound=0

  for command in "${DEPENDENCIES[@]}"; do
    if ! which "$command"  &> /dev/null ; then
      echo "ERRO: não encontrei o comando '$command'" >&2
      errorFound=1
    fi
  done

  if [[ "$errorFound" != "0" ]]; then
    echo "---IMPOSSÍVEL CONTINUAR---"
    echo "Esse script precisa dos comandos listados acima" >&2
    echo "Instale-os e/ou verifique se estão no seu \$PATH" >&2
    exit 1
  fi
}

function sh_cleaning()
{
	log_msg "Cleaning temporary files..."
	rm -rf $TMP_DIR_ROOT/ &> /dev/null
}

function cleanup()
{
	log_msg "Cleaning..."
	cp -f $TMP_DIR_BACKUP/* $VARCACHE_SEARCH/ &> /dev/null
	rm -rf $TMP_ROOT_BACKUP/ &> /dev/null
	exit
}
trap cleanup SIGINT SIGTERM

function sh_backup()
{
	if (( verbose >= 2 )); then
		log_wait_msg "Making backup: $VARCACHE_SEARCH/"
	fi
	mkdir -p $TMP_DIR_BACKUP/ &> /dev/null
	mkdir -p $TMP_DIR_FOLDERS/ &> /dev/null
	cp -f $VARCACHE_SEARCH/* $TMP_DIR_BACKUP/ &> /dev/null
}

#figlet
function logo()
{
	_CAT << 'EOF'
  __      _       _
 / _| ___| |_ ___| |__     Copyright (c) 2019-2022 Vilmar Catafesta <vcatafesta@gmail.com>
| |_ / _ \ __/ __| '_ \    Copyright (c) 2019-2022 Chilios Linux Development Team
|  _|  __/ || (__| | | |
|_|  \___|\__\___|_| |_|   Este programa pode ser redistribuído livremente
                           sob os termos da Licença Pública Geral GNU.
EOF
	sh_version
}

function usage()
{
	cat <<EOF
${cyan}Most used commands:
${red}  -h,  help           ${reset}- display this help and exit
${red}  -Sy, update         ${reset}- update list packages in repository online. Need Internet
${red}  -S,  install        ${reset}- install packages
${red}  -Ss, search         ${reset}- search for packages
${red}  -Su, upgrade        ${reset}- upgrade packages
${red}  -Sw, download       ${reset}- only download the binary package into cache directory
${red}  -Sa, alienpkg       ${reset}- import package from ArchLinux
${red}  -Sl, local          ${reset}- install local package
${red}  -Sg, generate       ${reset}- generate info package from source
${red}  -C,  create         ${reset}- build package
${red}  -Sm, meta           ${reset}- install meta packages
${red}  -R,  remove         ${reset}- remove packages
${red}  -L,  list           ${reset}- list avaiable packages based on package names
${red}  -La, list-avaiable  ${reset}- list avaiable packages based on package names
${red}  -Lc, list-cache     ${reset}- list downloaded packages in cache
${red}  -Li, list-installed ${reset}- list installed packages
${red}  -Pi, in-cache       ${reset}- list packages in-cache
${red}  -Po, out-cache      ${reset}- list packages out-cache
${red}  -Qi, show           ${reset}- show package details
${red}  -Sc, clean          ${reset}- erase downloaded packages files
${red}  -Ti, recreate       ${reset}- recreate database packages installed
${red}  -V,  version        ${reset}- output version information and exit
${cyan}ex:
  ${reset}fetch ${pink}-Sy ${reset} self ${yellow}=> Update self fetch via internet
  ${reset}fetch ${pink}-Sy ${reset}      ${yellow}=> Update database
  ${reset}fetch ${pink}-Syy${reset}      ${yellow}=> Force update database
  ${reset}fetch ${pink}-S  ${reset}<package> [<...>] [--all] [--noconfirm] [--force] [--nodeps]
  ${reset}fetch ${pink}-R  ${reset}<package> [<...>] [--all] [--noconfirm] [--force]
  ${reset}fetch ${pink}-Su ${reset}[<package>] [<...>] [--all] [--nonconfirm] [--force]
  ${reset}fetch ${pink}-Ss ${reset}<package> [<...>] [--noconfirm] [--force] [--exact] [--nodeps]
  ${reset}fetch ${pink}-Li ${reset}[<package>] [<...>] [--all] [--exact]
  ${reset}fetch ${pink}-Sw ${reset}[<package>] [<...>] [--all] [--noconfirm] [--force]
  ${reset}fetch ${pink}-Qi ${reset}[<package> [<...>]]
  ${reset}fetch ${pink}-C  ${reset}[<packname-version-build>]
  ${reset}fetch ${pink}-Sm ${reset}<xorg> [--noconfirm] [--force]
  ${reset}fetch ${pink}-Sa ${reset}<package> [<...>] [--all] [--noconfirm] [--force] [--ctime=<n>] [--keep] [--default]
EOF
}

function sh_parseparam()
{
	local param="$@"
   local s
   local newparam

	LDEPS=$true
	LAUTO=$false
	LFORCE=$false
	verbose=1
	mtime=0
	SPLITPOS='4'
	LLIST=$false
	LEXACT=$false
	LALL=$false
	LSELF=$false
	LKEEP=$false
	LFIND=$false
	LSEARCHONLY=$true

	for s in ${param[@]}
   do
      [[ $(tolower "${s:0:8}") = "--ctime=" ]] && { LFIND=$true; mtime="${s:8}"; continue;}
      [[ $(tolower "${s}") = "--default"    ]] && { LFIND=$true; LKEEP=$true; LALL=$true; continue; }
      [[ $(tolower "${s}") = "--keep"       ]] && { LKEEP=$true; continue; }
      [[ $(tolower "${s}") = "self"         ]] && { LSELF=$true; continue; }
      [[ $(tolower "${s}") = "--self"       ]] && { LSELF=$true; continue; }
      [[ $(tolower "${s}") = "--nodeps"     ]] && { LDEPS=$false; continue; }
      [[ $(tolower "${s}") = "-y"           ]] && { LAUTO=$true; continue; }
      [[ $(tolower "${s}") = "--auto"       ]] && { LAUTO=$true; continue; }
      [[ $(tolower "${s}") = "--noconfirm"  ]] && { LAUTO=$true; continue; }
      [[ $(tolower "${s}") = "-f"           ]] && { LFORCE=$true; continue; }
      [[ $(tolower "${s}") = "--force"      ]] && { LFORCE=$true; continue; }
      [[ $(tolower "${s}") = "-vv"          ]] && { verbose=2; continue; }
      [[	$(tolower "${s}") = "-vvv"         ]] && { verbose=3; continue; }
      [[	$(tolower "${s}") = "-q"           ]] && { verbose=0; continue; }
      [[ $(tolower "${s}") = "--quiet"      ]] && { verbose=0; continue; }
      [[ $(tolower "${s}") = "off"          ]] && { LLIST=$false; continue; }
      [[ $(tolower "${s}") = "on"           ]] && { LLIST=$true; continue; }
      [[ $(tolower "${s}") = "--exact"      ]] && { LEXACT=$true; continue; }
      [[ $(tolower "${s}") = "all"          ]] && { LALL=$true; continue; }
      [[ $(tolower "${s}") = "--all"        ]] && { LALL=$true; continue; }
      [[ $(tolower "${s}") = "--nocolor"    ]] && { unsetvarcolors;USE_COLOR='n';continue;}
		newparam="$newparam $(echo ${s})"
   done
#  debug "$newparam"
	log_prefix
	init $newparam
}

function init()
{
  	while test $# -gt 0
	do
		case "${1}" in
			-Si|-S|install)								shift;LSEARCHONLY=$false;sh_install "$@";return;;
			-Sl|local)  									shift;sh_initinstallpkg "$@";exit;;
			-Sa|alienpkg)	  		   					shift;sh_alienpkg_main "$@";return;;
			-Sc|clean)										sh_clean;exit 0;;
			-Sg|-g|generate)								sh_generatepkg "$@";exit;;
			-Sc|clean)  									sh_clean "$@";exit;;
			-Ss|search)	     								shift;sh_search "$@";exit;;
			-Sy|update)										shift;sh_updaterepo "${param}";exit;;
			-Syy|refresh)									shift;sh_update "${param}";exit;;
			-c|-C|create)					   			sh_createpkg "${param}";exit;;
			-Sm|--meta|meta) 		            		shift;sh_meta "${@}";exit;;
			-R|remove) 										shift;sh_remove "$@";exit;;
			-Sw|download) 									shift;sh_download "$@";exit;;
			-L|list)    	 								shift;sh_list "$@";exit;;
			-La|avaiable) 									shift;sh_list "$@";exit;;
			-Lc|list-cache) 	        					shift;sh_FilesInCache "${param}";exit;;
			-Li|list-installed)							shift;sh_listinstalled "${@}";exit;;
			-Po|out-cache)	            				shift;sh_pkgoutcache "${param}";exit;;
			-Qi|show) 										shift;sh_show "$@";exit;;
			-Su|upgrade)									shift;sh_upgrade "$@";exit;;
			-Ti|recreate)									shift;sh_recreatefilepackagesinstalled;exit;;
      	-V*|--version|version)						logo;exit 0;;
      	-u|-unit)										test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1; _arg_unit="$2";shift;;
			--unit=*)										_arg_unit="${_key##--unit=}";;
			-u*)												_arg_unit="${_key##-u}";;
      	-f*|--force)									LFORCE=1;;
      	-y*|--auto)										LAUTO=1;;
      	-exact|--exact)								LEXACT=1;;
      	-q|--quiet)										verbose=0;;
      	--nocolor)										unsetvarcolors;USE_COLOR='n';;
      	-v*|--no-verbose|--verbose)				(( ++verbose ));test "${1:0:5}" = "--no-" && verbose=0;;
      	-h|--help)										usage;exit $(( $# ? 0 : 1 ));;
#      	*)													usage;exit 0;_last_positional="$1";_positionals+=("$_last_positional");_positionals_count=$((_positionals_count + 1));;
      	*)													die "operation not supported: $1 (use -h for help)";;
		esac
		shift
	done
}

function parsestdin()
{
	file=${1--} # POSIX-compliant; ${1:--} can be used either.
	IFS='\n'
	while read line; do
		echo "$line"
		init -a "$line"
	done < /dev/stdin
	#done < <(cat -- "$file")
	#done < <(cat /dev/stdin)
	#done < /dev/stdin
	#done < <(cat "$@")
}

configure
sh_checkroot
checkDependencies
setvarcolors
sh_checkdir "OFF"

if [[ $1 = "" ]]; then
	die "no operation specified (use -h for help)"
fi

if [[ -z $1 || $1 = @(-h|--help) || $1 = "-h" || $1 = "--help" || $1 = "help" || $1 = "-help" ]]; then
	usage
	exit $(( $# ? 0 : 1 ))
fi

sh_arraypkgfull
#sh_checkparametros "$@"
#init "$@"

if [ -p /dev/stdin ]; then
	#for FILE in "$@" /dev/stdin
	for FILE in /dev/stdin
	do
		while IFS= read -r LINE
		do
			#echo "$LINE"
			init "$@" "$LINE"
		done < "$FILE"
	done
else
	# init "$@"
	sh_parseparam "$@"
fi

# vim:set ts=3 sw=3 et:
