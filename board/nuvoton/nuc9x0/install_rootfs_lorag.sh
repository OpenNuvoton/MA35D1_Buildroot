#!/bin/sh

rm output/target/etc/resolv.conf
cp -a board/nuvoton/nuc9x0/rootfs-lorag/* output/target/
