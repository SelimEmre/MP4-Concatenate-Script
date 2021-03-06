### Short brief

This documentation written for the AMS to S3 upload and concatenate same Stream ID MP4 files.

**Here is stream concatenation and uploading the S3 works.**

Firstly, the process begins when a new recorded stream is uploaded to S3. After the completion of the upload, Ant Media Server writes Stream ID with `processStreams.sh` script to the following file `/home/ubuntu/scripts/streamListsQueue.txt` file.


**AMS Side Process**

We need to add `settings.muxerFinishScript=/home/ubuntu/scripts/processStreams.sh` parameter in `/usr/local/antmedia/webapps/{Application-Name}/WEB-INF/red5-web.properties`. 

Here are [AWS S3 Configuration](https://github.com/ant-media/Ant-Media-Server/wiki/Amazon-(AWS)-S3-Integration) and [User-Defined scripts](https://github.com/ant-media/Ant-Media-Server/wiki/User-defined-Scripts)

> Please be sure your script is in right path and enable MP4 recording in Application settings.


**Instance Side Process**

We have `concatenate_mp4.sh` script in `/etc/crontab file`. `*/3 * * * * root /bin/bash -l -c /home/ubuntu/scripts/concatenate_mp4.sh > /home/ubuntu/scripts/myErrorLog.txt 2>&1`

This means `concatenate_mp4.sh` works every 3 min.

You need to add below codes for the S3 Mount
`sudo s3fs s3Bucket /mnt/s3_n/ -o allow_other -o default_acl='public-read'`

**Let me explain how `concatenate_mp4.sh` script process works;**

1. Check if any process of `concatenate_mp4.sh` script is already working. If there is a running process, the process will finish. 
2. Check the first line in `streamListsQueue.txt`, if it's an empty exit, the process will finish. 
3. Get Stream ID in `streamListsQueue.txt` first Item. 
4. Check if original file belongs to `Stream ID` exists. If `streamID.mp4` does not exist, the process will finish. 
5. The next step is that script checks if `streamId_1.mp4`, `streamId_2.mp4`, `streamId_3.mp4`, etc. files exist. If a stream file exists, concatenate process begins in `concatenate_files` function. Also, concatenate process is working on the S3 mount. 
6. The script tries 3 more files if they exist. If files don't exist, process will be finished and removing stream ID in `streamListsQueue.txt`

Lastly, if the concatenate process works normally, script will write the logs in `concatenated_streams.txt` For example: `/mnt/s3_n/vod/streams/677658101701365982735382_1.mp4 concatenated original file -> /mnt/s3_n/vod/streams/677658101701365982735382.mp4`
