#!/bin/sh

if grep -Eq "^BR2_INIT_BUSYBOX=y$" ${BR2_CONFIG}; then
	cp -af board/nuvoton/nuc9x0/rootfs-g2d/* output/target/
fi

