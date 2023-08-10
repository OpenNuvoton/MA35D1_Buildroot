#!/bin/sh

rm output/target/etc/resolv.conf
cp -af -r board/nuvoton/nuc970/rootfs-matter/* output/target/

