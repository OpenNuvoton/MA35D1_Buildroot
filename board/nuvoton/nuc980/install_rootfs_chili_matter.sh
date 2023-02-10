#!/bin/sh

rm output/target/etc/resolv.conf
cp -af board/nuvoton/nuc980/rootfs-chili-matter/* output/target/

