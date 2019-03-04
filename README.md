# scgy-pxe-recovery

#### Description
用于机房的PXE系统镜像工具，支持无人值守。

#### Software Architecture
基于 TinyCore Linux v9.0，经过重新打包initrd镜像，插入scgy_recover.sh。

#### Modifications
- Packed `curl` and `pci-utils` into `/tmp/builtin/`
- Packed `scgy_recover.sh` into `/opt/scgy_recover.sh`
- Modified `/etc/inittab` to allow for direct entrance into the script

#### Requirements for iPXE
Originated from [iPXE Download Page](http://ipxe.org/download)
- gcc (version 3 or later)
- binutils (version 2.18 or later)
- make
- perl
- liblzma or xz header files
- mtools
- mkisofs (needed only for building .iso images)
- syslinux (for isolinux, needed only for building .iso images)

#### Notice on Licenses
`vmlinuz` and `tinycore` are borrowed from [Tinycore Linux v9.0](http://www.tinycorelinux.net/). Sources available under their licenses.

#### Deploy
1. Configure all the options with `config_script.sh`, necessary for different IP's and paths other than test environment.
2. Build initrd by using `make_initrd.sh`. Note: having `AdvanceComp` will shrink the initrd to its minimum.
3. Build iPXE image by using `build_ipxe.sh`.
4. Set up DNS and TFTP, as well as http. (Eg. `dnsmasq` + `darkhttpd`)
   For example configurations, open `setup_pxe_env.sh` with a text editor.
5. Enjoy.

#### Hierarchy
```
├── boot_script.ipxe           # generated from boot_script.ipxe.m, with build_ipxe.sh
├── boot_script.ipxe.m         # boot script template, used by iPXE embedding
├── build_ipxe.sh              # iPXE binary builder
├── config_script.sh            # edit tinycore/opt/scgy_recover_cfg.sh
├── info.sh                    # example info.sh, used when boot and called recover/save
├── ipxe                       # iPXE sources, retrived by build_ipxe.sh
│   ├── contrib
│   ├── COPYING
│   ├── COPYING.GPLv2
│   ├── COPYING.UBDL
│   ├── README
│   └── src
├── make_initrd.sh             # build tinycore/ into initrd named tinycore.gz
├── README.md
├── scgy-backup                # test used temporary folder
│   └── disks                  # contains backup images and a copy of info.sh 
├── scgy-cfg.kpxe              # iPXE binary built with build_ipxe.sh
├── setup_pxe_env.sh           # example configurations on PXE server environments
├── tinycore                   # TinyCore Linux v9.0 initrd decompressed
│   ├── bin
│   ├── dev
│   ├── etc                    # modified inittab for automatic starting up recovery
│   ├── home
│   ├── init
│   ├── lib
│   ├── linuxrc -> bin/busybox
│   ├── mnt
│   ├── opt                    # contains scgy-recover scripts, for 1st stage startup
│   ├── proc
│   ├── root
│   ├── run
│   ├── sbin
│   ├── sys
│   ├── tmp                    # put curl and deps here, loaded by tc-config automatically
│   ├── usr
│   └── var
├── tinycore.gz                # built initrd
└── vmlinuz                    # TinyCore Linux v9.0 kernel binary
```

#### TODOs
Almost everything..