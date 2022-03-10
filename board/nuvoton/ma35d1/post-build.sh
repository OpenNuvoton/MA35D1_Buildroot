#!/bin/sh

MODULES_DIR=board/nuvoton/ma35d1/modules
MODULES_TDIR=$TARGET_DIR/lib/modules/5.4.181
GFXDRIVERS_TDIR=$TARGET_DIR/usr/lib/directfb-1.7-7/gfxdrivers

if grep -Eq "^BR2_PACKAGE_BUSYBOX=y$" ${BR2_CONFIG}; then
	install -d -m 755 ${MODULES_TARGET_TDIR}
	install -d -m 755 ${GFXDRIVERS_TDIR}
	cp ${MODULES_DIR}/*.ko ${MODULES_TDIR}/
	cp ${MODULES_DIR}/libdirectfb_gal.so ${GFXDRIVERS_TDIR}/
	cp ${MODULES_DIR}/libGAL.so ${TARGET_DIR}/usr/lib/
	cp ${MODULES_DIR}/modules.sh ${TARGET_DIR}/etc/profile.d/
fi
