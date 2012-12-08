#!/bin/bash
#
# 
# Copyright (c) 2010-2012 xeros.78<at>gmail.com
#
#
# This file is part of BetaShub.
#
# BetaShub is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# BetaShub is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with BetaShub.  If not, see <http://www.gnu.org/licenses/>.

VERSION=0.2;
RENAME=false;
DOWNLOAD_SUB=false;
NO_INTERACT=false;
ALTERNATE_NAME="";
LANG="VO";

API_KEY="337ed544dc3a";

parse_opts(){
while getopts ":rdylhva:" opt; do
  case $opt in
    r)
		RENAME=true;
      ;;
    d)
      	DOWNLOAD_SUB=true;
      ;;
    y)
      	NO_INTERACT=true;
      ;;
    a)
      	ALTERNATE_NAME="$OPTARG";
      ;;
    l)
      	LANG="$OPTARG";
      ;;
    h)
      	show_help;
      ;;
    v)
      	echo "BetaShub v$VERSION";
      	exit;
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      ;;
  esac
done
return "$OPTIND"
}

#Get file list and execute
#TODO separate  this function in sub-function may be ?
parse_args(){
	for f in "$@"
	do

		if [[ $(is_movie "$f") == "not_movie" ]]; then
		 	continue;
		fi
		if [ "$ALTERNATE_NAME" == "" ]; then		
			l="$f"
		else
			l="$ALTERNATE_NAME"
		fi
		
		echo "Searching for $l ... "
		l=$(echo "$l" | uri_encode)
		url="http://api.betaseries.com/shows/scraper.json?key=$API_KEY&file=$l"
		
		rep=$(curl -s $url)

                code=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^code/ {print $2}'  | tr -d '"')

                if [[ !( $code == '1' ) ]]; then
                    echo $(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^content/ {print $2}' | tr -d '"')
					continue;
                fi

                title=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^title/ {print $2}' | tr -d '"')
                number=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^number/ {print $2}' | tr -d '"' | tr '[:lower:]' '[:upper:]')
		

		if [ $RENAME == true ] && [ -f "$f" ] && [ "$f" != "$title - $number.${f##*.}" ]; then
			if [ $NO_INTERACT == false ]; then		
				read -p "Would you like to rename the file to :  $title - $number.${f##*.} [y/n]" interact
			fi
			
			if [ $NO_INTERACT == true ] || [ $interact == "y" ]; then
				echo "> Renaming to : $title - $number.${f##*.}"
				mv "$f" "$title - $number.${f##*.}"
			else
				RENAME=false;
			fi	
#TODO think of that.
#		else
#			RENAME=false;	
		fi
		
		if [ $DOWNLOAD_SUB == true  ]; then			
			echo "> Searching subs for : $title - $number"
            url=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^url/ {print $2}' | tr -d '"')
            episode=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^episode/ {print $2}' | tr -d '"')
            season=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^season/ {print $2}' | tr -d '"')
            
            url="http://api.betaseries.com/subtitles/show/$url.json?key=$API_KEY&language=$LANG&season=$season&episode=$episode"
			rep=$(curl -s $url)
			
            code=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^code/ {print $2}'  | tr -d '"')

            if [[ !( $code == '1' ) ]]; then
                echo $(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^content/ {print $2}' | tr -d '"')
				continue;
            fi
                      
            subtitles=$(echo "$rep" | awk -v RS=',"' -F: '/^subtitles/ {print $2}'  | tr -d '"')

            if [ $subtitles != "{}" ]; then
				    titles=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"' -v ORS=';' -F'":"' '/^file/ {print $2;}' | tr -d '\\"' )
				    subs=$(echo "$rep" |  sed -e 's/[{}]/''/g' | awk -v RS=',"'  -v ORS=';' -F'":"' '/^url/ {print $2;}' | tr -d '\\"')
					old_IFS=$IFS;
            
		        if [ $NO_INTERACT == false ]; then
			
					echo "# Select between those file : "
					IFS=';' 
					i=0;  
					for l in $titles
					do 
						i=$(($i+1)); 
						echo "	[$i] $l";
					done       
					IFS=$old_IFS
					read -p 'choose a number : ' i2;
			

				else
					#TODO algo pour déterminer le meilleur sous-titre;
					i2=1
				fi
				
            	i=0;  
			    IFS=';'			
			    sub="";
			    for l in $subs
				do 
					i=$(($i+1)); 
					if [ "$i" ==  "$i2" ]; then
						sub=$l;
					fi
				done       
			    echo $sub;
				IFS=$old_IFS
            fi
            
            if [ ! -z "$sub" ]; then
            	echo "> Downloading sub at : $sub ..."
            	
            	tmp="/tmp/$(basename $0).$RANDOM";
		        curl -L -o "$tmp" "$sub";
		        
		        mime=$( file -b -i "$tmp" | cut -d';' -f1);
		      
            	if [ "$mime" == "application/zip" ]; then
            		tmpd="/tmp/$(basename $0).$RANDOM";
            		mkdir "$tmpd";
 					unzip -qq "$tmp" -d "$tmpd";
 					rm "$tmp";
 					tmp=$( ls "$tmpd" | grep ".srt" | head -n1);
 					tmp="$tmpd/$tmp";
				fi
				
		        if [ $RENAME == true ]; then
		        	name="$title - $number.srt"
		        else
		        	name="${f%.*}.srt"
			fi
			
		    mv """$tmp""" "$name";
				
			else
		       	echo "	> No subtitle found."
			fi
		fi
		
		
	done
}

# Check if the file is movie.
# $1: single file
is_movie() {
		local FILE=$1
        if [[ $FILE =~ (mp4|avi|mkv)$ ]]; then
		echo "is_movie";
        else
            	echo "not_movie";
        fi
}



# Encode a complete url.
uri_encode() {
    sed -e 's/ /%20/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g'
}

# Show the help message and exit script.
show_help() {
	echo "Usage: betashub [OPTIONS] [FILE]

  Get info from betaseries to rename file and download subtiltles for tv shows.

Global options:

  -h		Show help info
  -v		Return betashub version
  -r		Rename file
  -d		Download subtitles
  -y		Force yes (no interaction)
  -l		Select language (VO|VF) default : VO
  -a		Force an alternate name for the file (usefull if it doesn't find with the original name)

"
	
    exit;
}

parse_opts "$@"
parse_args "${@:$?}"
