#!/bin/sh

IPXE_DIR="./ipxe"

# locate in ./ only
EMBED_SCRIPT_TEMPLATE=boot_script.ipxe.m
# desired output of the file, will be overrided by TEMPLATE_GENERATION PROCESS
EMBED_SCRIPT=boot_script.ipxe

# expected binary name
EXPECTED_IPXE_OUTPUT=scgy-cfg.kpxe

# from https://gist.github.com/MacLemon/4247471, under WTFPL.
fill_template() {
    echo "Processing template..."

    # Get a svn-like revision number that keeps increasing with every commit.
    REV=$(git log --pretty=format:'' | wc -l | sed 's/[ \t]//g')
    echo "git rev: $REV"

    # Getting the current branch
    GITBRANCH=$(git branch | grep "*" | sed -e 's/^* //')
    echo "Git Branch: $GITBRANCH"

    # full build hash
    GITHASH=$(git rev-parse HEAD)
    echo "Git Hash: $GITHASH"

    # commonly used short hash
    GITHASHSHORT=$(git rev-parse --short HEAD)
    echo "Git Hash Short: $GITHASHSHORT"

    # parsing tags to build the CFBundleVersion in the form of <MAJOR>.<MINOR>.<PATCH>.<REV>
    # Parts of the version number that are missing are substituted with zeros.
    NEAREST=$(git describe --abbrev=0 --match "release_[0-9]*")
    echo "Nearest release Tag: \"$NEAREST\""

    MAJOR="0"
    MINOR="0"
    PATCH="0"
    if [ "$NEAREST" == "" ]
    then
        echo "No release tag found!"
    else
        MAJOR=$(echo $NEAREST | cut -d "_" -f 2)
        if [ $MAJOR == "" ]
        then
            MAJOR="0"
        else
            MINOR=$(echo $NEAREST | cut -d "_" -f 3)
            if [ $MINOR == "" ]
            then
                MINOR="0"
            else
                PATCH=$(echo $NEAREST | cut -d "_" -f 4)
                if [ $PATCH == "" ]
                then
                    PATCH="0"
                fi
            fi
        fi
    fi

    echo "Version String: $MAJOR.$MINOR.$PATCH.$REV"
    VERSION="set version $MAJOR.$MINOR.$PATCH.$REV (git$GITHASHSHORT)"
    sed "2i$VERSION" "$EMBED_SCRIPT_TEMPLATE" > $EMBED_SCRIPT
    
    echo "Done."
}

echo "This script is used to configure iPXE with embed scripts."
echo "*All params in the script* for laziness"
echo "Notice: template file is inserted with vars in the second line."
echo "======================================="

fill_template

if ! [ -d $IPXE_DIR ]; then
	echo "Seems that iPXE dirs not exist. Grab one from iPXE Git."
	git clone git://git.ipxe.org/ipxe.git
else
	echo "Checking for iPXE updates.."
	cd ipxe && git pull
	cd ..
fi

cp $EMBED_SCRIPT ./ipxe/src && cd ipxe/src && make bin/undionly.kpxe EMBED="$EMBED_SCRIPT" NO_WERROR=1 && cp bin/undionly.kpxe ../../undionly.kpxe
mv ../../undionly.kpxe "../../$EXPECTED_IPXE_OUTPUT"
