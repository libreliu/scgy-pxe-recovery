# SCGYSU PXE-Based Computer Recovery Utility

### Description
本项目准备用于少院机房的无人值守恢复系统。系统基于扇区层面的复制，暂不支持基于文件系统的恢复。

1. 维护一个少人使用、及时更新的干净系统，并定期上传其镜像（使用“Save”功能）到FTP服务器
2. 在有需要恢复的计算机上，在PXE阶段按**Ctrl-B**即可进入iPXE菜单，选择进入恢复环境。
3. 恢复环境中，根据提示，可以进入shell/脱离无人值守/选择功能。如果什么操作都不做，就会恢复后重启系统。

This is intended to be used in SCGY's computer room. Lacking in recover mechanisms in SCGY have resulted in messy computers.
An sector based recovery & save utility was written to deal with the problem.

### Performance
- 100Mbps Ethernet, Atom N270 with 5400rpm SATA, block fragment 100M. ~11.6M/s for downloading/uploading and ~50M/s for disk read/write.

### Software Architecture
基于 TinyCore Linux v9.0，经过重新打包initrd镜像，插入scgy_recover.sh。

### Modifications
- Packed `curl` and `pci-utils` into `/tmp/builtin/`
- Packed `scgy_recover.sh` into `/opt/scgy_recover.sh`
- Modified `/etc/inittab` to allow for direct entrance into the script

### Requirements for iPXE
Originated from [iPXE Download Page](http://ipxe.org/download)
- gcc (version 3 or later)
- binutils (version 2.18 or later)
- make
- perl
- liblzma or xz header files
- mtools
- mkisofs (needed only for building .iso images)
- syslinux (for isolinux, needed only for building .iso images)

### Notice on Licenses
`vmlinuz` and `tinycore` are borrowed from [Tinycore Linux v9.0](http://www.tinycorelinux.net/). Sources available under their licenses.

### Deploy
0. **WARNING**: Problem found while sending entire tinycore folder via Git, use the cpio (gzipped) instead.
   `mkdir /mnt/tmp && cd /mnt/tmp && gunzip tinycore.gz && cpio -idmv < tinycore`
1. Configure all the options with `config_script.sh`, necessary for different IP's and paths other than test environment.
2. Build initrd by using `make_initrd.sh`. Note: having `AdvanceComp` will shrink the initrd to its minimum.
3. Build iPXE image by using `build_ipxe.sh`.
4. Set up DNS and TFTP, as well as http. (Eg. `dnsmasq` + `darkhttpd`)
   For example configurations, open `setup_pxe_env.sh` with a text editor.
5. Set up your machine's type and the action you want to do in `info.sh`. An example is provided by detecting and running on *LZT-TEST-TONGFANG* machine.

### Hierarchy
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

### TODOs & Bugs
1. Currently during iPXE exit, a manual "Enter" is required.
2. Smart Deploy System
3. Partition Table Override for MBR and GPT
4. Download & dd simutaenously
5. Exit conditions improvement and info.sh problem in saving process
