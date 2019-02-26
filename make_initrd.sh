#!/bin/sh

echo "Making initrd image.."
cd tinycore
sudo find | sudo cpio -o -H newc | gzip -2 > ../tinycore.gz
cd ..

[ -x "$(command -v advdef)" ] && advdef -z4 tinycore.gz || echo "Notice: Install AdvanceComp for smaller initrd size."
