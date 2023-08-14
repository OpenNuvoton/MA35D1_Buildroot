#!/bin/sh

rm output/target/etc/resolv.conf
cp -af -r board/nuvoton/nuc9x0/rootfs-chili/ output/target/

