#!/usr/bin/env bash

NULLDEV=/dev/null
COMPANY=nuvoton
PROJECT=ma35d1
PROJECT_DIR=${PWD}/board/${COMPANY}/${PROJECT}
NUWRITER_DIR=${PROJECT_DIR}/nuwriter

IMAGE_BASENAME="core-image-buildroot"
MACHINE=
EXT2_SIZE=
SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.rootfs.sdcard

# Boot partition size [in KiB]
BOOT_SPACE="32768"

# Set alignment in KiB
IMAGE_ROOTFS_ALIGNMENT="4096"

UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048 -O 2048"
IS_OPTEE=
UBOOT_DTB_NAME=

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

IMAGE_CMD_spinand() {

	( \
		cd ${BINARIES_DIR}; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-spinand; \
		cp ${BINARIES_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt-spinand; \
		${HOST_DIR}/sbin/ubinize ${UBINIZE_ARGS} -o ${BINARIES_DIR}/uboot-env.ubi-spinand ${PROJECT_DIR}/env/uEnv-spinand-ubi.cfg; \
	)

	if [ -f ${BINARIES_DIR}/rootfs.ubi ]; then
		( \
			cd ${BINARIES_DIR}; \
			ln -sf ${MACHINE}.dtb Image.dtb; \
			cp ${NUWRITER_DIR}/ddrimg_tfa.bin ${BINARIES_DIR}; \
			cp fip.bin fip.bin-spinand; \
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-spinand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-spinand.bin; \
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_DIR}/pack-spinand.json; \
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-spinand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
			rm Image.dtb; \
		)
	fi
} 

IMAGE_CMD_nand() {

	( \
		cd ${BINARIES_DIR}; \
		cp ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.bin-nand; \
		cp ${BINARIES_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt-nand; \
		${HOST_DIR}/sbin/ubinize ${UBINIZE_ARGS} -o ${BINARIES_DIR}/u-boot-env.ubi-nand ${PROJECT_DIR}/env/uEnv-nand-ubi.cfg \
	)

	if [ -f ${BINARIES_DIR}/rootfs.ubi ]; then
		( \
			cd ${BINARIES_DIR}; \
			ln -sf ${MACHINE}.dtb Image.dtb; \
			cp ${NUWRITER_DIR}/ddrimg_tfa.bin ${BINARIES_DIR}; \
			cp fip.bin fip.bin-nand; \
			${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-nand.json; \
			cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-nand.bin; \
			${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_DIR}/pack-nand.json; \
			cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-nand.bin; \
			rm -rf $(date "+%m%d-*") conv pack; \
			rm Image.dtb; \
		)
	fi
}

IMAGE_CMD_sdcard() 
{
	EXT2_SIZE=$(sed -n -e 's/^BR2_TARGET_ROOTFS_EXT2_SIZE=/ /p' ${BR2_CONFIG} | sed 's/M/ /g' | sed 's/\"/ /g')
	EXT2_SIZE=$((1024*$EXT2_SIZE))

	BOOT_SPACE_ALIGNED=$(($BOOT_SPACE))
	SDCARD_SIZE=$(($BOOT_SPACE_ALIGNED+$IMAGE_ROOTFS_ALIGNMENT+$EXT2_SIZE+$IMAGE_ROOTFS_ALIGNMENT))
	
	
        # Initialize a sparse file
        dd if=/dev/zero of=${SDCARD} bs=1 count=0 seek=$((1024*$SDCARD_SIZE)) &>${NULLDEV}
	sudo ${HOST_DIR}/sbin/parted ${SDCARD} -s mklabel msdos
	sudo ${HOST_DIR}/sbin/parted ${SDCARD} -s unit KiB mkpart primary \
        	$(($BOOT_SPACE_ALIGNED+$IMAGE_ROOTFS_ALIGNMENT)) \
        	$(($BOOT_SPACE_ALIGNED+$IMAGE_ROOTFS_ALIGNMENT+$EXT2_SIZE))
	sudo ${HOST_DIR}/sbin/parted ${SDCARD} print

        # MBR table for nuwriter
	dd if=/dev/zero of=${BINARIES_DIR}/MBR.scdard.bin bs=1 count=0 seek=512 &>${NULLDEV}
	dd if=${SDCARD} of=${BINARIES_DIR}/MBR.scdard.bin conv=notrunc seek=0 count=1 bs=512 &>${NULLDEV}

	( \
		cd ${BINARIES_DIR}; \
		ln -sf ${MACHINE}.dtb Image.dtb;
		cp uboot-env.bin uboot-env.bin-sdcard; \
		cp uboot-env.txt uboot-env.txt-sdcard; \
		cp fip.bin fip.bin-sdcard; \
		cp ${NUWRITER_DIR}/ddrimg_tfa.bin ${BINARIES_DIR}; \
		${HOST_DIR}/bin/nuwriter.py -c ${NUWRITER_DIR}/header-sdcard.json; \
		cp conv/header.bin header-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin; \
		$(cat ${NUWRITER_DIR}/pack-sdcard.json | ${HOST_DIR}/bin/jq 'setpath(["image",9,"offset"];"'$(( ${BOOT_SPACE_ALIGNED}*1024+$IMAGE_ROOTFS_ALIGNMENT*1024))'")' > ${NUWRITER_DIR}/pack-sdcard-tmp.json); \
		cp ${NUWRITER_DIR}/pack-sdcard-tmp.json ${NUWRITER_DIR}/pack-sdcard.json; \
		rm ${NUWRITER_DIR}/pack-sdcard-tmp.json; \
		${HOST_DIR}/bin/nuwriter.py -p ${NUWRITER_DIR}/pack-sdcard.json; \
		cp pack/pack.bin pack-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin; \
		rm -rf $(date "+%m%d-*") conv pack; \
		rm Image.dtb; \
	)

	# 0x400
	dd if=${BINARIES_DIR}/header-${IMAGE_BASENAME}-${MACHINE}-sdcard.bin of=${SDCARD} conv=notrunc seek=2 bs=512 &>${NULLDEV}
	# 0x10000
        dd if=${NUWRITER_DIR}/ddrimg_tfa.bin of=${SDCARD} conv=notrunc seek=128 bs=512 &>${NULLDEV}
        # 0x20000
        dd if=${BINARIES_DIR}/bl2.dtb of=${SDCARD} conv=notrunc seek=256 bs=512 &>${NULLDEV}
        # 0x30000
        dd if=${BINARIES_DIR}/bl2.bin of=${SDCARD} conv=notrunc seek=384 bs=512 &>${NULLDEV}
        # 0x40000
        dd if=${BINARIES_DIR}/uboot-env.bin-sdcard of=${SDCARD} conv=notrunc seek=512 bs=512 &>${NULLDEV}
        # 0xC0000
        dd if=${BINARIES_DIR}/fip.bin-sdcard of=${SDCARD} conv=notrunc seek=1536 bs=512 &>${NULLDEV}
        # 0x2c0000
        dd if=${BINARIES_DIR}/${MACHINE}.dtb of=${SDCARD} conv=notrunc seek=5632 bs=512 &>${NULLDEV}
        # 0x300000
        dd if=${BINARIES_DIR}/Image of=${SDCARD} conv=notrunc seek=6144 bs=512 &>${NULLDEV}
        # root fs
        dd if=${BINARIES_DIR}/rootfs.ext4 of=${SDCARD} conv=notrunc,fsync seek=1 bs=$(($BOOT_SPACE_ALIGNED*1024+$IMAGE_ROOTFS_ALIGNMENT*1024)) &>${NULLDEV}
}


uboot_cmd() {
	cp ${PROJECT_DIR}/uboot-env.txt ${BINARIES_DIR}/uboot-env.txt
	if [[ $MACHINE == "${PROJECT}-evb" ]]
	then	
		if [[ $IS_OPTEE == "yes" ]] 
		then
			sed -i "s/kernelmem=256M/kernelmem=248M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
		
	elif  [[ $MACHINE == "${PROJECT}-iot" ]]
	then
		sed -i "s/kernelmem=256M/kernelmem=128M/1" ${BINARIES_DIR}/uboot-env.txt
		if [[ $IS_OPTEE == "yes" ]]
		then
			sed -i "s/kernelmem=128M/kernelmem=120M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
		sed -i "s/mmc_block=mmcblk1p1/mmc_block=mmcblk0p1/1" ${BINARIES_DIR}/uboot-env.txt
	elif  [[ $MACHINE == "${PROJECT}-som" ]]
	then
		sed -i "s/kernelmem=256M/kernelmem=512M/1" ${BINARIES_DIR}/uboot-env.txt
		if [[ $IS_OPTEE == "yes" ]]
		then
			sed -i "s/kernelmem=512M/kernelmem=504M/1" ${BINARIES_DIR}/uboot-env.txt
		fi
	elif  [[ $MACHINE == "${PROJECT}-som-1gb" ]]
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

	${HOST_DIR}/bin/mkenvimage -s 0x10000 -o ${BINARIES_DIR}/uboot-env.bin ${BINARIES_DIR}/uboot-env.txt
}

main()
{
	UBOOT_DTB_NAME=$(uboot_dtb_name)
	MACHINE="$(dtb_list)"
	IS_OPTEE=$(optee_image)
	SDCARD=${BINARIES_DIR}/${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.rootfs.sdcard
	uboot_cmd
	if [[ $(echo $UBOOT_DTB_NAME | grep "spinand") != "" ]]
	then
		IMAGE_CMD_spinand
	elif [[ $(echo $UBOOT_DTB_NAME | grep "nand") != "" ]]
	then
		IMAGE_CMD_nand
	else
		IMAGE_CMD_sdcard
	fi
	
	exit $?
}

main $@
