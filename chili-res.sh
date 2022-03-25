#!/bin/bash
	source /usr/share/fetch/core.sh

	#output='VGA-1'
	#output='DVI-1'
	output='HDMI-1'

	hmode=('2560' '2560' '1920')
	vmode=('1080' '1440' '1440')
	ncounter=0
	arr=()
	off=()
	n=0

	for x in "${hmode[@]}"
	do
		arr[$n]="${hmode[$n]} ${vmode[$n]}"
		off[$n]="OFF"
	   (( n++ ))
	done

	while true
   do
#   nchoice=$( whiptail \
#   				--title "ChiliOS resolucao" \
#              --menu "Escolha uma resolucao:" 0 0 0 \
#               "${arr[@]}" "${arr[@]}" 2>&1 >/dev/tty)


  nchoice=$(dialog 												\
  				--stdout                        				\
            --separate-output                			\
            --checklist 'Choose resolucion for add:'	\
            0 0 0                                     \
         "${arr[@]}" "${arr[@]}" "${arr[@]}")

   retval=$?
	whiptail --msgbox "$retval" 0 0
   if [[ $retval -eq 1 ]]; then
   	exit
   fi

#	modeline=$(cvt "${hmode[ncounter]}" "${vmode[ncounter]}" | grep Modeline | sed 's/Modeline //')
#	mode=$(echo "${modeline}" | awk '{print $1}')

	modeline=$(cvt "$nchoice}" | grep Modeline | sed 's/Modeline //')
	mode=$(echo "${modeline}" | awk '{print $1}')
   printf "${modeline}\n"
	printf "${mode}\n"
	xrandr --verbose --newmode ${modeline}
	xrandr --verbose --addmode $output $mode
	(( ncounter++ ))
done

function  sh_setfont()
{
   local colddir=$PWD
   cd /usr/share/kbd/consolefonts/
   fonts="$(ls -1 *.gz)"
   array=()
   n=0
   for i in ${fonts[@]}
   do
      base="${i%.psfu.gz*}"
      base="${base%.psf.gz*}"
      base="${base%.cp.gz*}"
      base="${base%.fnt.gz*}"
      base="${base%.gz*}"
      array[((n++))]=$i
      array[((n++))]=$i
   done

   while true
   do
      whiptail --title "ChiliOS setfont" \
               --menu "Escolha uma fonte:" 0 0 0 \
               "${array[@]}" "${array[@]}"

#whiptail --msgbox "$?" 0 0
#exit
      retval=$?
      if [[ $retval -eq 1 ]]; then
         cd $colddir
         exit
      fi
      echo $retval
      setfont $1
   done
   cd $colddir
}
