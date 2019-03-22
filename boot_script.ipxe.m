#!ipxe

set menu_timeout 5000
echo SCGYSU-Tech PXE Recovery Utility ${version}
prompt --key 0x02 --timeout 1500 Press Ctrl-B to enter SCGY Recovery Menu... && goto start || goto exit

:start
menu SCGYSU-Tech PXE Recovery Utility ${version}
item --gap --             ------------------------- Tools and utilities ----------------------------
item --key r recovery Run Computer Recovery Utility (Notice: This will *ERASE* all of your file!)
item --gap --             ------------------------- Advanced options -------------------------------
item shell                Drop to iPXE shell
item reboot               Reboot computer
item
item --key x exit         Exit iPXE and continue BIOS boot
choose --timeout ${menu_timeout} --default exit selected || goto cancel
set menu-timeout 0
goto ${selected}

:cancel
echo You cancelled the menu, dropping you to a shell

:shell
echo Type 'exit' to get the back to the menu
shell
set menu-timeout 0
set submenu-timeout 0
goto start

:reboot
reboot

:exit
exit

:back
set submenu-timeout 0
clear submenu-default
goto start

:recovery
dhcp
kernel tftp://192.168.0.251/vmlinuz
initrd tftp://192.168.0.251/tinycore.gz
boot
