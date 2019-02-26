# scgy-pxe-recovery

#### Description
用于机房的PXE系统镜像工具，支持无人值守。

#### Software Architecture
基于 TinyCore Linux v9.0，经过重新打包initrd镜像，插入scgy_recover.sh。

#### Modifications
- Packed `curl` and `pci-utils` into `/tmp/builtin/`
- Packed `scgy_recover.sh` into `/opt/scgy_recover.sh`
- Modified `/etc/inittab` to allow for direct entrance into the script

#### Notice on Licenses
`vmlinuz` and `tinycore` are borrowed from Tinycore Linux v9.0. Sources available under their licenses.

#### Deploy
1. Configure all the options with `config_script.sh`
2. Build initrd by using `make_initrd.sh`. Note: having `AdvanceComp` will shrink the initrd to its minimum.
3. Configure the rest. *(TODO on this: give a out-of-box iPXE build)*
4. Set up DNS and TFTP, as well as http. (Eg. by `dnsmasq`)
5. Enjoy

#### TODOs
Almost everything..