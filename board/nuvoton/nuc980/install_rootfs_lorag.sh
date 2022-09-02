#!/bin/sh

rm output/target/etc/resolv.conf
cp -a board/nuvoton/nuc980/rootfs-lorag/* output/target/
