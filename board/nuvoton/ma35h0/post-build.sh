#!/bin/sh

MODULES_DIR=board/nuvoton/ma35h0/modules/5.10.140
MODULES_TDIR=$TARGET_DIR/lib/modules/5.10.140
GFXDRIVERS_TDIR=$TARGET_DIR/usr/lib/directfb-1.7-7/gfxdrivers

RESIZE_FILE=${TARGET_DIR}/etc/init.d/S50resize
cp $MODULES_DIR/../../resize.sh ${TARGET_DIR}/etc/
if [ -f ${RESIZE_FILE} ]; then
        rm ${RESIZE_FILE}
fi
if grep -Eq "^BR2_MA35H0_RESIZE_SD_MAX=y$" ${BR2_CONFIG}; then
	export $(grep "BR2_MA35H0_RESIZE_DISK_DRIVE=" $BR2_CONFIG | sed 's/\"//g')
	export $(grep "BR2_MA35H0_RESIZE_DISK_NUM=" $BR2_CONFIG | sed 's/\"//g')
	echo "#!/bin/sh" >> ${RESIZE_FILE}
	echo "/etc/resize.sh ${BR2_MA35H0_RESIZE_DISK_DRIVE} ${BR2_MA35H0_RESIZE_DISK_NUM}" >> ${RESIZE_FILE}
	chmod 755 ${RESIZE_FILE}
fi

if grep -Eq "^BR2_PACKAGE_BUSYBOX=y$" ${BR2_CONFIG}; then
	install -d -m 755 ${MODULES_TARGET_TDIR}
	install -d -m 755 ${GFXDRIVERS_TDIR}
	cp ${MODULES_DIR}/*.ko ${MODULES_TDIR}/
	cp ${MODULES_DIR}/../libdirectfb_gal.so ${GFXDRIVERS_TDIR}/
	cp ${MODULES_DIR}/../libGAL.so ${TARGET_DIR}/usr/lib/
	cp ${MODULES_DIR}/../modules.sh ${TARGET_DIR}/etc/profile.d/
fi
