#!/bin/bash

# Usage is sudo bash /home/mypc/softwares/concatenate_mp4.sh

#How to use concatenate_mp4.sh process:
#1- Checking concatenate_mp4.sh script is already working. If concatenate_mp4.sh process is already working, process will finish.
#2- Check first line in streamListsQueue.txt, if it's an empty exit, process will finish.
#3- Get Stream ID in streamListsQueue.txt first Item. 
#4- Checking original Stream ID file doesn't exist. If streamID.mp4 does not exist, process will finish.
#5- The next step is script tries streamId_1.mp4 after that continues _2.mp4 _3.mp4 checks files is exist. 
#6- The script tries 3 more files if exist. After that, if files don't exist, process will be finished and removing stream ID in streamListsQueue.txt

function currentFileCheck(){
    	if [ ! -f $currentStream ]
    	then
       		false
   		else
    		true
  		fi
    }


function originalFileCheck(){
    	if [ ! -f $originalFilePath ]
    	then
       		echo "Original file $originalFilePath does not exist, now trying next Stream ID"
       		# This command deleting first line in streamListsQueue list
       		sed -i '1d' $STREAM_SCRIPT_DIRECTORY
       		# Trying next stream ID
       		true
       	else
       		false
       	fi
    }


# concatenate second file to end of first file
# first file  1.mp4 duration: 10sec
# second file 2.mp4 duration: 20sec
# output file 1.mp4 duration: 30sec
concatenate_files() 
{
   file1=$1
   file2=$2
   outputFile=$1_out_temp.mp4
   temp1=$1_temp.ts
   temp2=$2_temp.ts
   

   ffmpeg -y -i $file1 -c copy -bsf:v h264_mp4toannexb -f mpegts  $temp1  
   ffmpeg -y -i $file2 -c copy -bsf:v h264_mp4toannexb -f mpegts  $temp2 
   ffmpeg -f mpegts  -i "concat:$temp1|$temp2"  -c copy -bsf:a aac_adtstoasc  $outputFile 

   #replace outputFile to  first file
   mv $outputFile $file1
   #delete second file and fifos
   rm $2 $temp1 $temp2

}

function begin_function() 
{
	# get the file name
	STREAM_SCRIPT_DIRECTORY="/home/ubuntu/scripts/streamListsQueue.txt"
	AWS_S3_DIRECTORY="/mnt/s3_n/vod/streams"
	CONCATENATED_STREAM_FOLDER="/home/ubuntu/scripts/concatenated_streams.txt"

	firstStreamId=$(head -n 1 $STREAM_SCRIPT_DIRECTORY) 

if [ -z "$firstStreamId" ];
then
   	echo "Stream List Queue is empty"
   	exit 1
fi

	echo "MP4 File:" $firstStreamId

	filename=$(basename "$firstStreamId")

	#find the position of suffix,suffix of "stream1_720p_1.mp4" is "_1.mp4".  original file stream1_720p.mp4 	
	position=`echo $filename | grep -b -o -E "_{1}[0-9]+\.mp4$" | awk 'BEGIN {FS=":"}{print $1}'`
	
	# If stream ID has no suffix
if [ -z $position ]; 
then
	position=`echo $filename | grep -b -o -E "\.mp4$" | awk 'BEGIN {FS=":"}{print $1}'`  
fi

	streamId=${filename:0:$position}
	originalFilePath=$AWS_S3_DIRECTORY/$streamId.mp4

	echo "stream ID: "$streamId
    echo "Original file name: $originalFilePath"

}

# Check process is already working on it

if [ `ps -aux |grep "concatenate" | egrep -v "grep|sh -c"| wc -l` -gt 2 ]
then
    echo "Concatenate_mp4.sh Process already running"
    exit 1
else
    echo "Concatenate_mp4.sh Process is starting"
fi

	echo "Concatenate_mp4.sh script is started"
    begin_function

    # Try check current file is exist 3 times, after that finishes
    while originalFileCheck $originalFilePath
		do

		echo "Trying again in a loop"
		begin_function

	done

    i=0
    c=1

    # Try check current file is exist 3 times, after that finishes
    while [ $i -le 2 ]
		do

			currentStream=$AWS_S3_DIRECTORY/$streamId"_"$c".mp4"
			echo "Current Stream ID: $currentStream"

			echo "Stream file is exist checking"
		
		if currentFileCheck $currentStream; then
			((c++))
			echo $currentStream "concatenating original file ->" $originalFilePath
			concatenate_files $originalFilePath $currentStream;
			echo $currentStream "concatenated original file ->" $originalFilePath >> $CONCATENATED_STREAM_FOLDER
			
		else
			((c++))
			((i++))
			echo "Stream file not found:$currentStream Tried Count:$i"
		fi
	done

# This function deleting first line in streamListsQueue list
sed -i '1d' $STREAM_SCRIPT_DIRECTORY