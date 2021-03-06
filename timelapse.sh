#!/bin/bash

# variables
resized_folder=resized
deflickered_folder=deflickered
video_folder=video
fps=25
path_to_defl_sript="$(dirname $0)"

# functions
usage ()
{
	echo "Usage:"
	echo "  parameters: file_path             runs the script and generates the video"
	echo "  parameters: file_path --clean     deletes old files"
	exit
}

# params check
if [ "$#" -eq "1" ] || [ "$#" -eq "2" ]
then
	# directories
	file_dir=$1
	resi_dir=$file_dir/$resized_folder
	out_dir=$file_dir/$video_folder
	# filenames
	out_name=`basename "$file_dir"`
	file_defl=$out_dir/${out_name}_defl_${fps}fps
	file_undefl=$out_dir/${out_name}_${fps}fps
	echo "Timelapse creator: $out_name"

	# delete files if --clean flag
	if [ "$#" -eq "2" ]
	then
		if [ $2 = "--clean" ]
		then
			echo "...clean up..."
			if [[ -e $file_defl.avi ]]; then
				echo "......delete .avi files"
				rm $file_defl.avi
				rm $file_undefl.avi
			else
				echo "......cant delete .avi files, they do not exist"
			fi
			if [[ -e $resi_dir ]]; then
				echo "......delete resized folder"
				rm -r $resi_dir
			else
				echo "......cant delete resized folder, it does not exist"
			fi
		else
			usage
		fi
		echo "...Sucess..."
		exit
	fi
else
	usage
fi

# file extension
file=$(find $file_dir -maxdepth 1 -name '*.jpg' -o -name '*.JPG' | head -n 1)
if [ -z "$file" ]
then
	echo "...empty directory, no jpg or JPG files"
	exit
fi
filename=$(basename "$file")
exte="${filename##*.}"
echo "...use ${exte} as file extension"

# resize to hd
if [[ ! -e $resi_dir ]]; then
	echo "...create folder: $resized_folder"
	mkdir $resi_dir
	echo "...resize"
	mogrify -path $resi_dir -resize 1920x1080! $file_dir/*.${exte}
elif [[ ! -d $resi_dir ]]; then
	echo "...$resized_folder already exists but is not a directory" 1>&2
	exit
else
	echo "...$resized_folder folder already exists, please use --clean to resize again"
fi

# deflicker script
$path_to_defl_sript/timelapse-deflicker.pl -p 2 -P $resi_dir
defl_dir=$resi_dir/$deflickered_folder

# video output dir
if [[ ! -e $out_dir ]]; then
	echo "...create folder: $video_folder"
	mkdir $out_dir
elif [[ ! -d $out_dir ]]; then
	echo "...$video_folder already exists but is not a directory" 1>&2
	exit
else
	echo "...$video_folder folder for output already exists"
fi

# create video
ffmpeg -r $fps -pattern_type glob -i $defl_dir'/*.'${exte} -c:v copy $file_defl.avi
ffmpeg -r $fps -pattern_type glob -i $resi_dir'/*.'${exte} -c:v copy $file_undefl.avi

# compress .mkv
#ffmpeg -i $file_defl.avi -c:v libx264 -preset slow -crf 15 $file_defl-final.mkv
#ffmpeg -i $file_undefl.avi -c:v libx264 -preset slow -crf 15 $file_undefl-final.mkv

# compress .mp4
ffmpeg -i $file_defl.avi -c:v libx264 -preset slow -crf 15 $file_defl-final.mp4
ffmpeg -i $file_undefl.avi -c:v libx264 -preset slow -crf 15 $file_undefl-final.mp4

echo "...Sucess..."


# EOF
