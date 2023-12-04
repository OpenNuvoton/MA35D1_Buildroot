#!/bin/sh

rm output/target/etc/resolv.conf
if grep -Eq "^BR2_INIT_BUSYBOX=y$" ${BR2_CONFIG}; then
	cp -af board/nuvoton/nuc9x0/rootfs-chili/* output/target/
fi

