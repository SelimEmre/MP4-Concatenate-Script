### Short brief

This documentation is written for uploading AMS to S3 and concatenating same Stream ID MP4 files.

**How does Stream concatenation and uploading to S3 work?**

The process begins when a new recorded stream is uploaded to S3. After the upload is completed, Ant Media Server writes the Stream ID to the following file `/home/ubuntu/scripts/streamListsQueue.txt` using the `processStreams.sh` script.


**Ant Media Server Configuration Processes**

To configure Ant Media Server, we need to add the `settings.muxerFinishScript=/home/ubuntu/scripts/processStreams.sh` parameter in `/usr/local/antmedia/webapps/{Application-Name}/WEB-INF/red5-web.properties`.

Here are [AWS S3 Configuration](https://github.com/ant-media/Ant-Media-Server/wiki/Amazon-(AWS)-S3-Integration) and [User-Defined scripts](https://github.com/ant-media/Ant-Media-Server/wiki/User-defined-Scripts)

> Please ensure that your script is in the correct path and that MP4 recording is enabled in the application settings.


**Instance Configuration Processes**

In the `/etc/crontab` file, we have the `concatenate_mp4.sh` script. The script works every 3 minutes with a cron job: `*/3 * * * * root /bin/bash -l -c /home/ubuntu/scripts/concatenate_mp4.sh > /home/ubuntu/scripts/myErrorLog.txt 2>&1`.

This means `concatenate_mp4.sh` script works every 3 min with a cron job.

You need to add the following codes for the S3 Mount:

`sudo s3fs s3Bucket /mnt/s3/ -o allow_other -o default_acl='public-read'`

**Let me explain how the `concatenate_mp4.sh` script process works:**

1. Check if any process of the `concatenate_mp4.sh` script is already running. If there is a running process, the process will finish.
2. Check the first line in `streamListsQueue.txt`. If it's empty, the process will exit.
3. Get the Stream ID in the first item of `streamListsQueue.txt`.
4. Check if the original file belongs to the Stream ID exists. If `streamID.mp4` does not exist, the process will finish.
5. The script checks if `streamId_1.mp4`, `streamId_2.mp4`, `streamId_3.mp4`, etc. files exist. If a stream file exists, the concatenate process begins in the concatenate_files function. The concatenate process also works on the S3 mount.
6. The script tries 3 more files if they exist. If the files do not exist, the process will finish and remove the Stream ID in `streamListsQueue.txt`.

Finally, if the concatenate process works normally, the script will write the logs in concatenated_streams.txt. For example: `/mnt/s3_n/vod/streams/677658101701365982735382_1.mp4` concatenated original file -> `/mnt/s3_n/vod/streams/677658101701365982735382.mp4`

Here is an example usage video: [![Watch the video](https://img.youtube.com/vi/E2H6GXvOkps/maxresdefault.jpg)](https://youtu.be/E2H6GXvOkps)

Note: Please use the S3 Fuse folder for concatenating.
