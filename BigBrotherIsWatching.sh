#!/bin/bash
# This script uses "progress-bar.sh" by Edouard Lopez, licensed under the MIT License.
# Repository: https://github.com/edouard-lopez/progress-bar.sh

# Since the import command does not work in wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "This script requires Xorg. Please switch to Xorg and try again."
    exit 1
fi

Hours="$@" # Session duration e.g. 1.5
TBegin=$SECONDS
echo -e "Big Brother started the surveillance!"

if [ "$(basename $(pwd))" = "Productivity_Check" ]; then
	echo "You are running the script from the correct directory"
else
	echo "Wrong directory! Start over!"
	# beep sound to signal the error
	echo -ne '\a'
	exit 1
fi

source third_party/progress-bar.sh
# Prepare the progress bar

DurationCustomized=$(expr 3600*$Hours | bc) # Preparing the input for progress bar as integer 
#and a few second less than the total duration to keep time for processing the files
DurationCustomRounded=$(awk 'BEGIN{print int('"$DurationCustomized"')}')
tForProcessing=2*60
echo -e  "Focus from now on for $Hours hours!"
progress-bar $(($DurationCustomRounded-2*$tForProcessing)) & \
# Initialization

RANDOM=$$
DURATION=0
MaxDuration=$(($DurationCustomRounded-$tForProcessing))
MaxJitter=$((60*5)) # maximum of jitter set to 5 minutes 
MaxNrOfScreenshots=25
Interval=$(echo "scale=0; $Hours*3600/$MaxNrOfScreenshots" | bc) # estimation of time between screenshots
today=$(date +%Y-%m-%d)
echo ""
screenshot_counter=0

while  [  $DURATION -lt $MaxDuration ]; do 
	JITTER=$(shuf -i 0-$MaxJitter -n 1) #jitter between 1 second and maxJitter
 	R=$(($Interval+$JITTER))
 	#to not exceed the maximum duration
	if [ $(bc<<<"$R + $DURATION") -ge $MaxDuration ]; then
	   R=$(($MaxDuration-$DURATION));				
	fi
	sleep $R 

	filename=screenshot_${today}_${screenshot_counter}.jpg
	import -window root $filename
  	mogrify -resize 50% $filename		

	DURATION=$(( $SECONDS - $TBegin )) #seconds:  the number of seconds elapsed since the current instance of shell is invoked
	screenshot_counter=$(($screenshot_counter+1)) 
done

T2Add=$(( $SECONDS - $TBegin )) 
# In case time duration is not exactly equal to the  maxduration 
sleep $(($DurationCustomRounded-$T2Add))
echo -e '\n'
echo $(($DurationCustomRounded-T2Add))
finishing_time=$SECONDS
echo "Loop Duration: "
printf '%dh:%dm:%ds\n' $(($finishing_time/3600)) $(($finishing_time%3600/60)) $(($finishing_time%60))

# Beep sound to signal that the session done
echo -ne '\a'
echo -e '\n'

totalDuration=$SECONDS
echo "Total Duration: "
printf '%dh:%dm:%ds\n' $(($totalDuration/3600)) $(($totalDuration%3600/60)) $(($totalDuration%60))

if [ "$(basename $(pwd))" = "Productivity_Check" ]; then
	echo "You are still in the correct directory" 
else
	exit 1	
fi

echo "processing the files..." 
# Deleting old files (all except screenshots of today and bash scripts)
#files=($(find . -type f -name '*.png')) 
oldfiles=($(find . -type f -not \( -iname "*${today}*" -o -iname "*.sh" -o -iname ".gitignore" -o -path "*/.git/*" -o -path "./third_party/*" \)))
printf "%s\n" "${files[@]}"
printf "%s\n" "${oldfiles[@]}"
# Ask for confirmation
read -p "Do you want to delete these files? (y/n): " answer
if [ "$answer" = "y" ]; then
    rm "${oldfiles[@]}"
    echo "Files deleted."
else
    echo "No files were deleted."
fi

rm -i Productivity_check*.zip # Remove the zip file one
export_filename=Productivity_check_${today}.zip
echo $export_filename
zip $export_filename *.jpg
echo "zip file is generated! Enjoy your break!"
