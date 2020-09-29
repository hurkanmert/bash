#!/bin/bash



read -p "Object Name or Coordinates : " object_name
#read -p "Coordinate System : " coordinate_system
#read -p "Observation Dates : " observation_dates
printf "Missions = > \n\n"
printf "\nMost Requested Missions = >\n [ CHANDRA - FERMI - HaloSat - Hitomi - MAXI - nicer - NuSTAR\nROSAT - RXTE - SUZAKU - SWIFT - WMAP - XMM-NEWTON ]\n\n"
printf "Other X-Ray and EUV Missions = >\n [ ARIEL V - ASCA - BBXRT - BEPPOSAX - COPERNICUS - EINSTEIN\n EUVE - EXOSAT - GINGA - HEAO1 - Kvant - OSO8\n SAS-3 - UHURU - VELA 5B ] \n\n "
printf "Other Gamma-Ray Missions = >\n [ AGILE - CALET - CGRO - COS B - HETE-2 - INTEGRAL - SAS-2 - GAMMA-RAY BURSTS - RHESSI ] \n\n "
printf "Missions and Facilities = >\n [ AKARI - ANS - COBE - COROT - FAUST - FUSE - GALEX - ground-based\nHerschel - HST - IRAS - ISO - IUE - LPF - MSX\nPlanck - SDSS - Spitzer - TD1 - UIT - WISE ]\n\n"
read -p "What missions and catalogs do you want to search ? : " missions
echo "If you do not want to limit, please enter "0" "
read -p "Limit Result To : " limit

filename=${object_name/ /_}
full_catalog=$filename"_full_catalog.txt"
mkdir /next/lmxbs/$filename
cd /next/lmxbs/$filename
filename=$filename."txt"

read -p "Are you sure about the information you entered, start the download process? (y / n) : " ask

if [[ "$(echo "$ask" | tr '[:upper:]' '[:lower:]')" == "y" ]] || [[ "$(echo "$ask" | tr '[:upper:]' '[:lower:]')" == "yes" ]] ;
then
	#command
	curl -d "Entry=$object_name&Observatory_xray1=$missions&ResultMax=$limit&displaymode=PureTextDisplay&table_type=Observation&Coordinates=J2000" -H "Content-Type: application/x-www-form-urlencoded" -X POST https://heasarc.gsfc.nasa.gov/cgi-bin/W3Browse/w3table.pl > $full_catalog
	#dosyanın kayıt edileceği yer düzenlenebilir, bu durumda grep komutunda ki konumda düzenlenmeli
	error=$(grep -n "Error" $full_catalog | head -n 1 | cut -d: -f1)
	echo $error
	if [ "$error" == "" ];then


		xtemaster=$(grep -n "Results from heasarc_xtemaster: XTE Master Catalog" $full_catalog | head -n 1 | cut -d: -f1)
		start_read=$((xtemaster + 1))
		file_end=$(grep -n "No matches for:" $full_catalog | head -n 1 | cut -d: -f1)
		if [ "$file_end" == "" ];then
			xteindex=$(grep -n "Results from heasarc_xteindex: XTE Target Index Catalog" $full_catalog | head -n 1 | cut -d: -f1)
			xteslew=$(grep -n "Results from heasarc_xteslew: XTE Archived Public Slew Data" $full_catalog | head -n 1 | cut -d: -f1)

			if [ "$xteindex" == "" ];then
					if [ "$xtemaster" -gt "$xteslew" ];then
						stop=$(cat $file | wc -l )
						stop_read=$((stop - 2))
					else
						stop_read=$(($xteslew - 2))
					fi
				elif [ "$xteslew" == "" ];then
					if [ "xtemaster" -gt "$xteindex" ];then
						stop=$(cat $file | wc -l )
						stop_read=$((stop - 2))
					else
						stop_read=$(($xteindex - 2))
					fi
				else

					if [ "$xtemaster" -gt "$xteindex" ] && [ "$xtemaster" -gt "$xteslew" ];then
						stop=$(cat $file | wc -l )
						stop_read=$((stop - 2))
					elif [ "$xteindex" -gt "$xtemaster" ] && [ "$xteindex" -gt "$xteslew" ] && [ "$xteslew" -gt "$xtemaster" ];then
						stop_read=$(($xteslew - 2))
					elif [ "$xteslew" -gt "$xtemaster" ] && [ "$xteslew" -gt "$xteindex" ] && [ "$xteindex" -gt "$xtemaster" ];then
						stop_read=$(($xteindex -2))
					elif [ "$xteindex" -gt "$xtemaster" ] && [ "$xteindex" -gt "$xteslew" ] && [ "$xteslew" -lt "$xtemaster" ];then
						stop_read=$(($xteindex - 2))
					elif [ "$xteslew" -gt "$xtemaster" ] && [ "$xteslew" -gt "$xteindex" ] && [ "$xteindex" -lt "$xtemaster" ];then
						stop_read=$(($xteslew -2))
					fi

			 	fi

		else
			stop_read=$((file_end - 2))
		fi

		awk  -v  s="$start_read" -v e="$stop_read" 'NR>1*s&&NR<1*e' $full_catalog > $filename
		echo "Downloaded successfully."


	else
		echo "The information entered is incorrect! Please be sure to write the information correctly."
		rm $full_catalog
	fi
	#command

fi


################
new=${object_name/ /_}
sed -i -e "1d" $filename
#rm *-e
cut -d '|' -f 2 $filename > "$new"_all_obsid.txt
sed '/^[[:space:]]*$/d' "$new"_all_obsid.txt > "$new"_obsid.txt
rm "$new"_all_obsid.txt

################


read -p "Do you want to create $new download script. (y / n) : " ask

if [[ "$(echo "$ask" | tr '[:upper:]' '[:lower:]')" == "y" ]] || [[ "$(echo "$ask" | tr '[:upper:]' '[:lower:]')" == "yes" ]] ; then
	echo "Ok, continuing..."
else
	exit 1
fi

################
for f in "$new"_obsid.txt

do

	i=1
	ii=0
	number_exist=0
	number_not_ex=0

	#dikkat buraya.. serverda düzelt...

	printf "\rSource Name : %20s : The download script is being prepared... \n" $f
	echo "printf '%-20s %-20s %-20s %-20s %-20s %-20s %-1s\n' Obsid Down_start_date Down_start_time Down_time_second Down_file_size Number_of_file Download_speed_in_per_second>> /next/lmxbs/$new/"$new"_info.txt" >> /next/lmxbs/$new/$new"_download_script.sh"
	echo "" >> /next/lmxbs/$new/$new"_download_script.sh"

	data=$(cat "$f" | wc -l)

	until [ $i -gt "$data" ]

	do

		((ii=i))
  		obsid_first=$(sed -n "$i"p "$f" | cut -d '-' -f 1)
  		obsid_full=$(sed -n "$i"p "$f")
  		obsid_a=$(sed -n "$i"p "$f" | cut -b 1)
  		obsid_d=$(sed -n "$i"p "$f" | cut -b 2)
 	 	obsid_g=$(sed -n "$i"p "$f" | cut -b 1-2)
 		((i=i+1))


  		if [ "$obsid_g" -ge 91 ]; then

   	 		e=1
    		num="$(($obsid_d-$e))"

			url1="https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO1"$num"//P"$obsid_first"/"$obsid_full"/."

			if wget $url1 >/dev/null 2>&1 ; then
				printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full Exists.
				rm index*

				((number_exist=i-1))

				echo "echo $obsid_full Downloading..." >> /next/lmxbs/$new/$new"_download_script.sh"
  				echo "obsid=$obsid_full" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'date=$(date "+%Y-%m-%d %H:%M:%S")' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'start=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "wget -q -nH --no-check-certificate --cut-dirs=5 -r -l0 -c -N -np -R 'index*' -erobots=off --retr-symlinks https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO1"$num"//P"$obsid_first"/"$obsid_full"/." >> /next/lmxbs/$new/$new"_download_script.sh"
   				echo 'end=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"

    			echo 'runtime=$((end-start))' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'size=$(du -ch /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | tail -1 | cut -f1)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_mb=$(echo $size | tr -d M\")' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_speed=$(awk "BEGIN {print ($download_mb)/($runtime)}")' >> /next/lmxbs/$new/$new"_download_script.sh"

    			echo 'nof=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'nof_2=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/* | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "printf '%-20s %-20s %-20s %-20s %-20s %-20s %-1s (MB/s)\n' $"obsid" $"date" $"runtime" $"size" $"nof"/$"nof_2" $"download_speed" >> /next/lmxbs/$new/"$new"_info.txt" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo "" >> /next/lmxbs/$new/$new"_download_script.sh"


			else
				printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full "Does not exists."
				((number_not_exist=i-1))
    		fi


  		elif [ "$obsid_g" == 90 ]; then

			url2="https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO9//P"$obsid_first"/"$obsid_full"/."


			if wget $url2 >/dev/null 2>&1 ; then

			    printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full Exists.
				rm index*

				((number_exist=i-1))

				echo "echo $obsid_full Downloading..." >> /next/lmxbs/$new/$new"_download_script.sh"
  				echo "obsid=$obsid_full" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'date=$(date "+%Y-%m-%d %H:%M:%S")' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'start=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "wget -q -nH --no-check-certificate --cut-dirs=5 -r -l0 -c -N -np -R 'index*' -erobots=off --retr-symlinks https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO9//P"$obsid_first"/"$obsid_full"/." >> /next/lmxbs/$new/$new"_download_script.sh"
   				echo 'end=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'runtime=$((end-start))' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'size=$(du -ch /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | tail -1 | cut -f1)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_mb=$(echo $size | tr -d M\")' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_speed=$(awk "BEGIN {print ($download_mb)/($runtime)}")' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'nof=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'nof_2=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/* | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "printf '%-20s %-20s %-20s %-20s %-20s %-20s %-1s (MB/s)\n' $"obsid" $"date" $"runtime" $"size" $"nof"/$"nof_2" $"download_speed" >> /next/lmxbs/$new/"$new"_info.txt" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo "" >> /next/lmxbs/$new/$new"_download_script.sh"

			else
				printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full  "Does not exists."
				((number_not_exist=i-1))
   		 	fi

  		else

    		url3="https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO"$obsid_a"//P"$obsid_first"/"$obsid_full"/."


			if wget $url3 >/dev/null 2>&1 ; then
				printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full Exists.
				rm index*

				((number_exist=i-1))

				echo "echo $obsid_full Downloading..." >> /next/lmxbs/$new/$new"_download_script.sh"
  				echo "obsid=$obsid_full" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'date=$(date "+%Y-%m-%d %H:%M:%S")' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'start=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "wget -q -nH --no-check-certificate --cut-dirs=5 -r -l0 -c -N -np -R 'index*' -erobots=off --retr-symlinks https://heasarc.gsfc.nasa.gov/FTP/xte/data/archive/AO"$obsid_a"//P"$obsid_first"/"$obsid_full"/." >> /next/lmxbs/$new/$new"_download_script.sh"
   				echo 'end=$(date +%s)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'runtime=$((end-start))' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'size=$(du -ch /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | tail -1 | cut -f1)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_mb=$(echo $size | tr -d M\")' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'download_speed=$(awk "BEGIN {print ($download_mb)/($runtime)}")' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo 'nof=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/ | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
				echo 'nof_2=$(ls /next/lmxbs/'$new'/P'$obsid_first'/'$obsid_full'/* | wc -l)' >> /next/lmxbs/$new/$new"_download_script.sh"
    			echo "printf '%-20s %-20s %-20s %-20s %-20s %-20s %-1s (MB/s)\n' $"obsid" $"date" $"runtime" $"size" $"nof"/$"nof_2" $"download_speed" >> /next/lmxbs/$new/"$new"_info.txt" >> /next/lmxbs/$new/$new"_download_script.sh"
				echo "" >> /next/lmxbs/$new/$new"_download_script.sh"
			else
			    printf " %-1s/%-4s %-2s: %-10s  %-10s\n" $data $ii Obsid $obsid_full "Does not exists."
				((number_not_exist=i-1))
			fi
  		fi
	done

	ex=0
	((exist=$number_exist-$number_not_exist))
	lose_data=0
	((lose_data=$limit-$data))
	no_data=0
	((no_data=$number_not_exist+$lose_data))

	if [ "$no_data" == "$limit" ] ; then
		printf "\rSource Name : %20s : The processing has not been saved. There is no availability data! \n" $f
		rm -rf /next/lmxbs/$new/
	elif [ "$exist" -gt 0 ] ; then
		printf "\rExist :%5s  Not Exist :%5s  No URL :%5s  Download Limit :%5s\n" $exist $number_not_exist $lose_data $limit
		printf "\rSource Name : %20s : The processing has been saved.\n" $f
	else
		printf "\rExist :%5s  Not Exist :%5s  No URL :%5s  Download Limit :%5s\n" $number_exist $number_not_exist $lose_data $limit
		printf "\rSource Name : %20s : The processing has been saved.\n" $f
	fi

done

echo "All works has been completed !"
