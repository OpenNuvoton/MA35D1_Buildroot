#!/bin/sh

rm output/target/etc/resolv.conf
cp -af board/nuvoton/nuc970/rootfs-matter/* output/target/

