#!/bin/bash

# $1: gcc-arm-none-eabi patch
# $2: nu-eclipse patch
# $3: source patch
# $4: deploy patch

GCC_DIR=$1
ECLIPSE_DIR=$2
SOURCE_DIR=$3
DEPLOY_DIR=$4

PATH=$PATH:${GCC_DIR}/bin
DISPLAY=":99"

ECLIPSE_PAR='-nosplash --launcher.suppressErrors -application org.eclipse.cdt.managedbuilder.core.headlessbuild -data Temp -cleanBuild all -import'

if ! pgrep Xvfb
then
	exec Xvfb ":99" &> /dev/null &
fi

install -d ${DEPLOY_DIR}
#find ${SOURCE_DIR}/SampleCode -name Release -type d | xargs -i rm {} -r
#find ${SOURCE_DIR}/SampleCode -name GCC -type d | xargs -i ${ECLIPSE_DIR}/eclipse ${ECLIPSE_PAR} {} &> build.log
#find ${SOURCE_DIR}/SampleCode -name "*.elf" -type f | xargs -i cp {} ${DEPLOY_DIR}

find ${SOURCE_DIR}/SampleCode -name Release -type d | xargs -i rm {} -r
find ${SOURCE_DIR}/SampleCode -name GCC -type d | xargs -i echo {} > ProjList.txt
while read rows
do
	${ECLIPSE_DIR}/eclipse ${ECLIPSE_PAR} $rows &>> build.log
	rm Temp -rf
done < ProjList.txt
find ${SOURCE_DIR}/SampleCode -name "*.elf" -type f | xargs -i cp {} ${DEPLOY_DIR}

find ${DEPLOY_DIR} -name "*.elf" -type f | xargs -i echo {} | sed "s/\.elf//" > ProjName.txt
while read rows
do
        ELFNAME=$rows
        arm-none-eabi-objcopy -O binary $ELFNAME.elf $ELFNAME.bin
done < ProjName.txt
