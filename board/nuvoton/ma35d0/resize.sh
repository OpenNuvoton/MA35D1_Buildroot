#!/bin/sh

REC_FILE=/etc/profile.d/.resize_run
if [ -f "$REC_FILE" ] ; then
	exit 1
fi

if ! mount | grep "/ type ext4" ; then
	exit 1
fi

set -e
if [ -z "$1" ] ; then
	echo please tell me the device to resize as the first parameter, like /dev/sda, or like /dev/mmcblk0
	exit 1
fi
if [ -z "$2" ] ; then
	echo please tell me the partition number to resize as the second parameter, like 1 in case you mean /dev/sda1, or like p1 in case you mean /dev/mmcblk0p1
	exit 1
fi
DEVICE=$1
PARTNR=$2
NUM=`echo $PARTNR | tr -cd "[0-9]"`
fdisk -l $DEVICE$PARTNR >> /dev/null 2>&1 || (echo "could not find device $DEVICE$PARTNR - please runs in superuser or check the name" && exit 1)
CURRENTSIZEB=`fdisk -l $DEVICE$PARTNR | grep "Disk $DEVICE$PARTNR" | head -1 | cut -d' ' -f5`
CURRENTSIZE=$(expr $CURRENTSIZEB / 1024 / 1024)
MAXSIZEMB=`printf %s\\n 'unit MB print list' | parted 2>/dev/null | grep "Disk ${DEVICE}" | cut -d' ' -f3 | tr -d MB`
echo "[ok] would/will resize to from ${CURRENTSIZE}MB to ${MAXSIZEMB}MB "
parted ${DEVICE} resizepart ${NUM} ${MAXSIZEMB}
resize2fs $DEVICE$PARTNR
echo "run" > $REC_FILE
sync
echo "[done]"
