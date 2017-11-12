#!/bin/bash


##################################################################################
#                                     VARIABLES
##################################################################################

# GLOBALNE PREMENNE
# GLOBAL VARIABLES
NO_ARGS=0
SCRIPT_VERSION=0.1
SCRIPT_AUTHOR="LALA -> lala (at) linuxor (dot) sk"
SCRIPT_YEAR="2017"


##################################################################################
#                                     FUNCTIONS
##################################################################################

# Print usage message
function print_usage ()
{
    printf "%s\n" "Usage: `basename $0` [options]"
    printf "%s\n" "       -i YOUTUBE_VIDEO_ID  ID of youtube video."
    printf "%s\n" "       -v                   Show script version."
}

# Print script version
function print_version ()
{
    printf "%s\n" "`basename $0` $SCRIPT_VERSION ($SCRIPT_YEAR) by $SCRIPT_AUTHOR"
}


##################################################################################
#                                     PARSE ARGUMENTS
##################################################################################

##################################### Check script arguments
if (( $# == "$NO_ARGS" ))
then
    print_usage
    exit 1
fi

if (( $#<2 && $#!=1  ))
then
    print_usage
    printf "\nRequired options are -i YOUTUBE_VIDEO_ID\n"
    exit 1
fi


##################################### Process script arguments
while getopts ":i:v" Option
do
    case $Option in


##################################### Argument "-i YOUTUBE_VIDEO_ID"
##################################### Find timestamps (3x) in which is frame from thumbnail picture in YOUTUBE VIDEO with specified ID
    i)
    VIDEO_ID=${OPTARG}
    ;;


##################################### Argument "-v"
##################################### Show script version
    v)
    print_version
    exit 0
    ;;


##################################### Default
##################################### Show usage
    *)
    print_usage
    exit 0
    ;;


    esac
done


# Dekrementujeme smernik argumentu, takze ukazuje na nasledujuci parameter.
# $1 teraz referuje na prvu polozku (nie volbu) poskytnutu na prikazovom riadku.
shift $(($OPTIND - 1))



##################################################################################
#                              PREPARE ENVIRONMENT
##################################################################################

##################################### Check output directory (If not exists then create)
BASEDIR=~
VIDEOBASE=$BASEDIR/$VIDEO_ID
VIDEODIR=$BASEDIR/$VIDEO_ID/video
THUMBDIR=$BASEDIR/$VIDEO_ID/thumb
FRAMESDIR=$BASEDIR/$VIDEO_ID/frames


# If $VIDEOBASE exists then remove it completely
if [ -d $VIDEOBASE ]
then
    rm -rf $VIDEOBASE
fi

# Create clean directories
mkdir -p $VIDEODIR
mkdir -p $THUMBDIR
mkdir -p $FRAMESDIR


##################################################################################
#                                     MAIN
##################################################################################

cd $VIDEODIR
# youtube-dl --id $VIDEO_ID -f 'bestvideo[width<=640]' > /dev/null 2>&1
# youtube-dl --id $VIDEO_ID -f best[ext=webm] > /dev/null 2>&1

# TOTO TREBA VYLEPSIT NA MOZNOST VYBERU ROZLISENIA
youtube-dl --id $VIDEO_ID -f 'bestvideo[height=480][ext=webm]' > /dev/null 2>&1



cd $THUMBDIR
wget https://i.ytimg.com/vi/$VIDEO_ID/0.jpg > /dev/null 2>&1


ffmpeg -i $VIDEODIR/$VIDEO_ID.webm $FRAMESDIR/thumb%04d.jpg -hide_banner  > /dev/null 2>&1
width=$(identify -format "%[fx:w] %[fx:h]" $FRAMESDIR/thumb0001.jpg 2>&1 | awk '{print $1}')
height=$(identify -format "%[fx:w] %[fx:h]" $FRAMESDIR/thumb0001.jpg 2>&1 | awk '{print $2}')

# TU JE AKTUALNE PROBLEM
convert $THUMBDIR/0.jpg -colorspace RGB +sigmoidal-contrast 7.5 -filter Lanczos -define filter:blur=.9891028367558475 -distort Resize `echo $width`x`echo $height` -sigmoidal-contrast 7.5 -colorspace sRGB $THUMBDIR/reference.jpg > /dev/null 2>&1


cd $BASEDIR
FRAMES=$FRAMESDIR/thumb*

for f in $FRAMES
do
    rmse=$( compare -metric RMSE $f $THUMBDIR/reference.jpg NULL: 2>&1 | awk '{print $1}')
    file=$( basename "$f" )
    frame=$( echo "${file//[!0-9]}" )
    echo $frame $rmse >> $VIDEOBASE/results
done

echo "Printing 3 youtube video timestamps in which is probably picture from video thumbnail."
sort -nk 2 $VIDEOBASE/results | head -n 3 | sort -nk 1 | awk '{ timestamp=$1/25; printf "%d\n", timestamp}'



##################################################################################
#                                     CLEANING
##################################################################################
unset VIDEO_ID
unset BASEDIR
unset VIDEOBASE
unset VIDEODIR
unset THUMBDIR
unset FRAMESDIR
unset width
unset height
unset rmse
unset file
unset frame


# Uspesny koniec
exit 0

