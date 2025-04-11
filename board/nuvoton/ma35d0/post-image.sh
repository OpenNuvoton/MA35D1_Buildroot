#!/usr/bin/env bash

NULLDEV=/dev/null
COMPANY=nuvoton
PROJECT=ma35d0
PROJECT_DIR=${PWD}/board/${COMPANY}/${PROJECT}
NUWRITER_DIR=${PROJECT_DIR}/nuwriter
NUWRITER_TARGET=${BINARIES_DIR}/${IMGDEPLOYDIR}/nuwriter

IMAGE_BASENAME="core-image-buildroot"
MACHINE=
EXT2_SIZE=
ENVOPT="-s 0x10000"
SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.rootfs.sdcard

# Boot partition size [in KiB]
BOOT_SPACE="32768"

# Set alignment in KiB
IMAGE_ROOTFS_ALIGNMENT="4096"

UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048 -O 2048"
IS_OPTEE=
UBOOT_DTB_NAME=
ECDSA_KEY=
AES_KEY=

#
# dtb_list extracts the list of DTB files from BR2_LINUX_KERNEL_INTREE_DTS_NAME
# in ${BR_CONFIG}, then prints the corresponding list of file names for the
# genimage configuration file
#
dtb_list()
{
	local DTB_LIST="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\([\/a-z0-9 \-]*\)"$/\1/p' ${BR2_CONFIG})"

	for dt in $DTB_LIST; do
		echo -n "`basename $dt`"
	done
}

#
# uboot_dtb_name extracts the SDARD size from BR2_TARGET_ROOTFS_EXT2_SIZE in
# ${BR_CONFIG}, then prints the baord corresponding file names
#
uboot_dtb_name()
{
	echo $(sed -n -e 's/^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=/ /p' ${BR2_CONFIG} | sed 's/M/ /g' | sed 's/\"/ /g' | sed '/^$/d')
}

optee_image()
{
	if grep -Eq "^BR2_TARGET_OPTEE_OS=y$" ${BR2_CONFIG}; then
		echo "yes"
	else
		echo "no"
	fi
	
}

boot_space()
{
	echo $(sed -n -e 's/^BR2_TARGET_MA35D0_BOOT_SPACE=/ /p' ${BR2_CONFIG} | sed 's/M/ /g' | sed 's/\"/ /g' | sed '/^$/d')
}

IMAGE_CMD_spinand() {

	( \
		cd ${BINARIES_DIR}; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-spinand; \
		cp ${BINARIES_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt-spinand; \
		${HOST_DIR}/sbin/ubinize ${UBINIZE_ARGS} -o ${BINARIES_DIR}/uboot-env.ubi-spinand ${PROJECT_DIR}/env/uEnv-spinand-ubi.cfg; \
	)

	if [ -f ${BINARIES_DIR}/rootfs.ubi ]; then
		if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
		( \
			cd ${BINARIES_DIR}; \
			cp ${MACHINE}.dtb Image.dtb; \
			cp fip.bin fip.bin-spinand; \
			$(cat ${NUWRITER_DIR}/header-spinand.json | ${HOST_DIR}/bin/jq -r ".header.secureboot = \"yes\"" | \
			${HOST_DIR}/bin/jq -r ".header.aeskey = \"${AES_KEY}\"" | \
			${HOST_DIR}/bin/jq -r ".header.ecdsakey = \"${ECDSA_KEY}\"" \
			> ${NUWRITER_TARGET}/header-spinand.json); \
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_TARGET}/header-spinand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-enc-spinand.bin; \
			ln -sf header-${IMAGE_BASENAME}-${MACHINE}-enc-spinand.bin header.bin;
			cp conv/enc_bl2.dtb ${NUWRITER_TARGET}/enc_bl2.dtb; \
			cp conv/enc_bl2.bin ${NUWRITER_TARGET}/enc_bl2.bin; \
			echo "{\""publicx"\": \""$(head -6 conv/header_key.txt | tail +6)"\", \
			\""publicy"\": \""$(head -7 conv/header_key.txt | tail +7)"\", \
			\""aeskey"\": \""$(head -2 conv/header_key.txt | tail +2)"\"}" | \
			${HOST_DIR}/bin/jq  > ${NUWRITER_TARGET}/otp_key.json; \
			$(cat ${NUWRITER_DIR}/pack-spinand.json | \
			${HOST_DIR}/bin/jq 'setpath(["image",1,"file"];"nuwriter/enc_bl2.dtb")' | \
			${HOST_DIR}/bin/jq 'setpath(["image",2,"file"];"nuwriter/enc_bl2.bin")' \
			> ${NUWRITER_TARGET}/pack-spinand.json); \
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-spinand.json; \
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-enc-spinand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
		)
		else
		( \
			cd ${BINARIES_DIR}; \
			cp ${MACHINE}.dtb Image.dtb; \
			cp fip.bin fip.bin-spinand; \
			cp ${NUWRITER_DIR}/header-spinand.json ${NUWRITER_TARGET}/header-spinand.json
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-spinand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-spinand.bin; \
			ln -sf header-${IMAGE_BASENAME}-${MACHINE}-spinand.bin header.bin;
			cp ${NUWRITER_DIR}/pack-spinand.json ${NUWRITER_TARGET}/pack-spinand.json;
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-spinand.json; \
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-spinand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
		)
		fi
	fi
}

IMAGE_CMD_spinor() {

	( \
		cd ${BINARIES_DIR}; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-spinor; \
		cp ${BINARIES_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt-spinor; \
	)

	if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
	( \
		cd ${BINARIES_DIR}; \
		cp ${MACHINE}.dtb Image.dtb; \
		cp fip.bin fip.bin-spinor; \
		$(cat ${NUWRITER_DIR}/header-spinor.json | ${HOST_DIR}/bin/jq -r ".header.secureboot = \"yes\"" | \
		${HOST_DIR}/bin/jq -r ".header.aeskey = \"${AES_KEY}\"" | \
		${HOST_DIR}/bin/jq -r ".header.ecdsakey = \"${ECDSA_KEY}\"" \
		> ${NUWRITER_TARGET}/header-spinor.json); \
		${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_TARGET}/header-spinor.json; \
		cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-enc-spinor.bin; \
		ln -sf header-${IMAGE_BASENAME}-${MACHINE}-enc-spinor.bin header.bin;
		cp conv/enc_bl2.dtb ${NUWRITER_TARGET}/enc_bl2.dtb; \
		cp conv/enc_bl2.bin ${NUWRITER_TARGET}/enc_bl2.bin; \
		echo "{\""publicx"\": \""$(head -6 conv/header_key.txt | tail +6)"\", \
		\""publicy"\": \""$(head -7 conv/header_key.txt | tail +7)"\", \
		\""aeskey"\": \""$(head -2 conv/header_key.txt | tail +2)"\"}" | \
		${HOST_DIR}/bin/jq  > ${NUWRITER_TARGET}/otp_key.json; \
		$(cat ${NUWRITER_DIR}/pack-spinor.json | \
		${HOST_DIR}/bin/jq 'setpath(["image",1,"file"];"nuwriter/enc_bl2.dtb")' | \
		${HOST_DIR}/bin/jq 'setpath(["image",2,"file"];"nuwriter/enc_bl2.bin")' \
		> ${NUWRITER_TARGET}/pack-spinor.json); \
		${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-spinor.json; \
		cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-enc-spinor.bin; \
		rm -rf $(date "+%m%d-*") conv pack; \
	)
	else
	( \
		cd ${BINARIES_DIR}; \
		cp ${MACHINE}.dtb Image.dtb; \
		cp fip.bin fip.bin-spinor; \
		cp ${NUWRITER_DIR}/header-spinor.json ${NUWRITER_TARGET}/header-spinor.json
		${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-spinor.json; \
		cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-spinor.bin; \
		ln -sf header-${IMAGE_BASENAME}-${MACHINE}-spinor.bin header.bin;
		${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_DIR}/pack-spinor.json; \
		cp ${NUWRITER_DIR}/pack-spinor.json ${NUWRITER_TARGET}/pack-spinor.json;
		cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-spinor.bin; \
		rm -rf $(date "+%m%d-*") conv pack; \
	)
	fi
} 

IMAGE_CMD_nand() {

	( \
		cd ${BINARIES_DIR}; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-nand; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-ubinand; \
		cp ${BINARIES_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt-nand; \
		${HOST_DIR}/sbin/ubinize ${UBINIZE_ARGS} -o ${BINARIES_DIR}/u-boot-env.ubi-nand ${PROJECT_DIR}/env/uEnv-nand-ubi.cfg \
	)

	if [ -f ${BINARIES_DIR}/rootfs.ubi ]; then
		if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
		( \
			cd ${BINARIES_DIR}; \
			cp ${MACHINE}.dtb Image.dtb; \
			cp fip.bin fip.bin-nand; \
			$(cat ${NUWRITER_DIR}/header-nand.json | ${HOST_DIR}/bin/jq -r ".header.secureboot = \"yes\"" | \
			${HOST_DIR}/bin/jq -r ".header.aeskey = \"${AES_KEY}\"" | \
			${HOST_DIR}/bin/jq -r ".header.ecdsakey = \"${ECDSA_KEY}\"" \
			> ${NUWRITER_TARGET}/header-nand.json); \
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_TARGET}/header-nand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-enc-nand.bin; \
			ln -sf header-${IMAGE_BASENAME}-${MACHINE}-enc-nand.bin header.bin;
			cp conv/enc_bl2.dtb ${NUWRITER_TARGET}/enc_bl2.dtb; \
			cp conv/enc_bl2.bin ${NUWRITER_TARGET}/enc_bl2.bin; \
			echo "{\""publicx"\": \""$(head -6 conv/header_key.txt | tail +6)"\", \
			\""publicy"\": \""$(head -7 conv/header_key.txt | tail +7)"\", \
			\""aeskey"\": \""$(head -2 conv/header_key.txt | tail +2)"\"}" | \
			${HOST_DIR}/bin/jq  > ${NUWRITER_TARGET}/otp_key.json; \
			$(cat ${NUWRITER_DIR}/pack-nand.json | \
			${HOST_DIR}/bin/jq 'setpath(["image",1,"file"];"nuwriter/enc_bl2.dtb")' | \
			${HOST_DIR}/bin/jq 'setpath(["image",2,"file"];"nuwriter/enc_bl2.bin")' \
			> ${NUWRITER_TARGET}/pack-nand.json); \
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-nand.json; \
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-enc-nand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
		)
		else
		( \
			cd ${BINARIES_DIR}; \
			cp ${MACHINE}.dtb Image.dtb; \
			cp fip.bin fip.bin-nand; \
			cp ${NUWRITER_DIR}/header-nand.json ${NUWRITER_TARGET}/header-nand.json
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-nand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-nand.bin; \
			ln -sf header-${IMAGE_BASENAME}-${MACHINE}-nand.bin header.bin;
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_DIR}/pack-nand.json; \
			cp ${NUWRITER_DIR}/pack-nand.json ${NUWRITER_TARGET}/pack-nand.json;
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-nand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
		)
		fi
	fi
}

IMAGE_CMD_sdcard() 
{
	EXT2_SIZE=$(sed -n -e 's/^BR2_TARGET_ROOTFS_EXT2_SIZE=/ /p' ${BR2_CONFIG} | sed 's/M/ /g' | sed 's/\"/ /g')
	EXT2_SIZE=$((1024*$EXT2_SIZE))

	BOOT_SPACE_ALIGNED=$(($BOOT_SPACE))
	SDCARD_SIZE=$(($BOOT_SPACE_ALIGNED+$IMAGE_ROOTFS_ALIGNMENT+$EXT2_SIZE+$IMAGE_ROOTFS_ALIGNMENT))

	if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
		SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}-enc.rootfs.sdcard
	fi
	
        # Initialize a sparse file
        dd if=/dev/zero of=${SDCARD} bs=1 count=0 seek=$((1024*$SDCARD_SIZE)) &>${NULLDEV}
	${HOST_DIR}/bin/fakeroot -u ${HOST_DIR}/sbin/parted ${SDCARD} -s mklabel msdos
	${HOST_DIR}/bin/fakeroot -u ${HOST_DIR}/sbin/parted ${SDCARD} -s unit KiB mkpart primary \
		$(($BOOT_SPACE_ALIGNED)) \
        	$(($BOOT_SPACE_ALIGNED+$IMAGE_ROOTFS_ALIGNMENT+$EXT2_SIZE))
	${HOST_DIR}/bin/fakeroot -u ${HOST_DIR}/sbin/parted ${SDCARD} print

        # MBR table for nuwriter
	dd if=/dev/zero of=${BINARIES_DIR}/MBR.sdcard.bin bs=1 count=0 seek=512 &>${NULLDEV}
	dd if=${SDCARD} of=${BINARIES_DIR}/MBR.sdcard.bin conv=notrunc,fsync seek=0 count=1 bs=512 &>${NULLDEV}

	if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
	( \
		cd ${BINARIES_DIR}; \
		cp ${MACHINE}.dtb Image.dtb; \
		cp uboot-env.bin uboot-env.bin-sdcard; \
		cp uboot-env.txt uboot-env.txt-sdcard; \
		cp fip.bin fip.bin-sdcard; \
		$(cat ${NUWRITER_DIR}/header-sdcard.json | ${HOST_DIR}/bin/jq -r ".header.secureboot = \"yes\"" | \
		${HOST_DIR}/bin/jq -r ".header.aeskey = \"${AES_KEY}\"" | ${HOST_DIR}/bin/jq -r ".header.ecdsakey = \"${ECDSA_KEY}\"" \
		> ${NUWRITER_TARGET}/header-sdcard.json); \
		${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_TARGET}/header-sdcard.json; \
		cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-enc-sdcard.bin; \
		ln -sf header-${IMAGE_BASENAME}-${MACHINE}-enc-sdcard.bin header.bin;
		cp conv/enc_bl2.dtb ${NUWRITER_TARGET}/enc_bl2.dtb; \
		cp conv/enc_bl2.bin ${NUWRITER_TARGET}/enc_bl2.bin; \
		echo "{\""publicx"\": \""$(head -6 conv/header_key.txt | tail +6)"\", \
		\""publicy"\": \""$(head -7 conv/header_key.txt | tail +7)"\", \
		\""aeskey"\": \""$(head -2 conv/header_key.txt | tail +2)"\"}" | \
		${HOST_DIR}/bin/jq  > ${NUWRITER_TARGET}/otp_key.json; \
		$(cat ${NUWRITER_DIR}/pack-sdcard.json | \
		${HOST_DIR}/bin/jq 'setpath(["image",2,"file"];"nuwriter/enc_bl2.dtb")' | \
		${HOST_DIR}/bin/jq 'setpath(["image",3,"file"];"nuwriter/enc_bl2.bin")' | \
		${HOST_DIR}/bin/jq 'setpath(["image",8,"offset"];"'$(( ${BOOT_SPACE_ALIGNED}*1024+$IMAGE_ROOTFS_ALIGNMENT*1024))'")' \
		> ${NUWRITER_TARGET}/pack-sdcard.json); \
		${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-sdcard.json; \
		cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-enc-sdcard.bin; \
		rm -rf $(date "+%m%d-*") conv pack; \
		SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}-enc.rootfs.sdcard
	)
	else
	( \
		cd ${BINARIES_DIR}; \
		cp ${MACHINE}.dtb Image.dtb; \
		cp uboot-env.bin uboot-env.bin-sdcard; \
		cp uboot-env.txt uboot-env.txt-sdcard; \
		cp fip.bin fip.bin-sdcard; \
		cp ${NUWRITER_DIR}/header-sdcard.json ${NUWRITER_TARGET}
		${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_TARGET}/header-sdcard.json; \
		cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin; \
		ln -sf header-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin header.bin;
		$(cat ${NUWRITER_DIR}/pack-sdcard.json | ${HOST_DIR}/bin/jq 'setpath(["image",8,"offset"];"'$(( ${BOOT_SPACE_ALIGNED}*1024))'")' > ${NUWRITER_TARGET}/pack-sdcard.json); \
		${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_TARGET}/pack-sdcard.json; \
		cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin; \
		rm -rf $(date "+%m%d-*") conv pack; \
        )
	fi

	if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
		# 0x400
		dd if=${BINARIES_DIR}/header-${IMAGE_BASENAME}-${MACHINE}-enc-sdcard.bin of=${SDCARD} conv=notrunc seek=2 bs=512 &>${NULLDEV}
		# 0x20000
		dd if=${NUWRITER_TARGET}/enc_bl2.dtb of=${SDCARD} conv=notrunc seek=256 bs=512 &>${NULLDEV}
		# 0x30000
		dd if=${NUWRITER_TARGET}/enc_bl2.bin of=${SDCARD} conv=notrunc seek=384 bs=512 &>${NULLDEV}
	else
		# 0x400
		dd if=${BINARIES_DIR}/header-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin of=${SDCARD} conv=notrunc seek=2 bs=512 &>${NULLDEV}
		# 0x20000
		dd if=${BINARIES_DIR}/bl2.dtb of=${SDCARD} conv=notrunc seek=256 bs=512 &>${NULLDEV}
		# 0x30000
		dd if=${BINARIES_DIR}/bl2.bin of=${SDCARD} conv=notrunc seek=384 bs=512 &>${NULLDEV}
	fi
        # 0x40000
        dd if=${BINARIES_DIR}/uboot-env.bin-sdcard of=${SDCARD} conv=notrunc seek=512 bs=512 &>${NULLDEV}
        # 0xC0000
        dd if=${BINARIES_DIR}/fip.bin-sdcard of=${SDCARD} conv=notrunc seek=1536 bs=512 &>${NULLDEV}
        # 0x2c0000
        dd if=${BINARIES_DIR}/${MACHINE}.dtb of=${SDCARD} conv=notrunc seek=5632 bs=512 &>${NULLDEV}
        # 0x300000
        dd if=${BINARIES_DIR}/Image of=${SDCARD} conv=notrunc seek=6144 bs=512 &>${NULLDEV}
        # root fs
        dd if=${BINARIES_DIR}/rootfs.ext4 of=${SDCARD} conv=notrunc,fsync seek=1 bs=$(($BOOT_SPACE_ALIGNED*1024)) &>${NULLDEV}
}


uboot_cmd() {
	cp ${PROJECT_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt
	if echo ${MACHINE} | grep -q "256"
	then	
		if [[ $IS_OPTEE == "yes" ]] 
		then
			sed -i "s/kernelmem=256M/kernelmem=248M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
		
	elif echo ${MACHINE} | grep -q "128"
	then
		sed -i "s/kernelmem=256M/kernelmem=128M/1" ${BINARIES_DIR}/uboot-env.txt
		if [[ $IS_OPTEE == "yes" ]]
		then
			sed -i "s/kernelmem=128M/kernelmem=120M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
	elif echo ${MACHINE} | grep -q "512"
	then
		sed -i "s/kernelmem=256M/kernelmem=512M/1" ${BINARIES_DIR}/uboot-env.txt
		if [[ $IS_OPTEE == "yes" ]]
		then
			sed -i "s/kernelmem=512M/kernelmem=504M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
	elif echo ${MACHINE} | grep -q "1g"
	then
		sed -i "s/kernelmem=256M/kernelmem=1024M/1" ${BINARIES_DIR}/uboot-env.txt
		if [[ $IS_OPTEE == "yes" ]]
		then
			sed -i "s/kernelmem=1024M/kernelmem=1016M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
	fi

	if [[ $(echo $UBOOT_DTB_NAME | grep "sdcard0") != "" ]]
	then
		sed -i "s/mmc_block=mmcblk1p1/mmc_block=mmcblk0p1/1" ${BINARIES_DIR}/uboot-env.txt
	fi

	if echo $UBOOT_DTB_NAME | grep -q "spinand"
	then
		sed -i "s/boot_targets=/boot_targets=mtd0 /1" ${BINARIES_DIR}/uboot-env.txt
	elif echo $UBOOT_DTB_NAME | grep -q "nand"
	then
		sed -i "s/boot_targets=/boot_targets=nand0 /1" ${BINARIES_DIR}/uboot-env.txt
	fi

	if echo $UBOOT_DTB_NAME | grep -q "spinor"
	then
		sed -i "s/boot_targets=/boot_targets=spinor0 /1" ${BINARIES_DIR}/uboot-env.txt
	fi

	${HOST_DIR}/bin/mkenvimage ${ENVOPT} -o ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.txt
}

main()
{
	BOOT_SPACE=$(boot_space)
	UBOOT_DTB_NAME=$(uboot_dtb_name)
	MACHINE="$(dtb_list)"
	IS_OPTEE=$(optee_image)
	SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.rootfs.sdcard

	#Create nuwriter folder
	if [ ! -d ${NUWRITER_TARGET} ]; then
		mkdir ${NUWRITER_TARGET}
	else
		rm ${NUWRITER_TARGET}/*
	fi

	if [ -f ${BINARIES_DIR}/${IMGDEPLOYDIR}/MBR.sdcard.bin ]; then
		rm ${BINARIES_DIR}/${IMGDEPLOYDIR}/MBR.sdcard.bin
	fi

	if grep -Eq "^BR2_TARGET_MA35D0_SECURE_BOOT=y$" ${BR2_CONFIG}; then
		ECDSA_KEY=$(sed -n -e 's/^BR2_TARGET_MA35D0_ECDSA_KEY=//p' ${BR2_CONFIG} | sed 's/\"//g')
		AES_KEY=$(sed -n -e 's/^BR2_TARGET_MA35D0_AES_KEY=//p' ${BR2_CONFIG} | sed 's/\"//g')
	fi

	if grep -Eq "^CONFIG_SYS_REDUNDAND_ENVIRONMENT=y$" ${BR2_UBOOT_CONFIG}; then
		ENVOPT="-r ${ENVOPT}"
	fi

	(cd ${BINARIES_DIR}/${IMGDEPLOYDIR};
	rm fip.bin-* -f;
	rm header-${IMAGE_BASENAME}*.bin pack-${IMAGE_BASENAME}*.bin ${IMAGE_BASENAME}*.sdcard -rf;)
	uboot_cmd

	if [[ $(echo $UBOOT_DTB_NAME | grep "spinand") != "" ]]
	then
		IMAGE_CMD_spinand
	elif [[ $(echo $UBOOT_DTB_NAME | grep "nand") != "" ]]
	then
		IMAGE_CMD_nand
	elif [[ $(echo $UBOOT_DTB_NAME | grep "spinor") != "" ]]
	then
		IMAGE_CMD_spinor
	else
		IMAGE_CMD_sdcard
	fi
	
	exit $?
}

main $@
