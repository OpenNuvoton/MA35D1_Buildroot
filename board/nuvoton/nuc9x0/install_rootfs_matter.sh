#!/bin/sh

rm output/target/etc/resolv.conf
cp -af board/nuvoton/nuc9x0/rootfs-chili-matter/* output/target/

