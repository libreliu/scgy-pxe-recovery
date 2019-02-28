#!/bin/sh

IPXE_DIR="./ipxe"
# locate in ./ only
EMBED_SCRIPT=boot_script.ipxe

echo "This script is used to configure iPXE with embed scripts."
echo "*All params in the script* for laziness"
echo "======================================="

if ! [ -d $IPXE_DIR ]; then
	echo "Seems that iPXE dirs not exist. Grab one from iPXE Git."
	git clone git://git.ipxe.org/ipxe.git
else
	echo "Checking for iPXE updates.."
	cd ipxe && git pull
	cd ..
fi

cp $EMBED_SCRIPT ./ipxe/src && cd ipxe/src && make bin/undionly.kpxe EMBED="$EMBED_SCRIPT" && cp bin/undionly.kpxe ../../undionly.kpxe

