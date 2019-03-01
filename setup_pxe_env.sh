#!/bin/sh

echo "This is intended for test purposes. Do not use in production."
echo "First, setup an valid http server."
echo "In this example, darkhttpd is used."
echo "darkhttpd runs in background. Remember to kill it when shutdown."
sudo darkhttpd . &

echo "Second, setup DHCP and TFTP server."
echo "In this example, dnsmasq is used. (See also: Archwiki)"
echo "======================"
echo "# /etc/dnsmasq.conf"
echo "port=0"
echo "interface=enp0s25"
echo "bind-interfaces"
echo "dhcp-range=192.168.0.50, 192.168.0.150, 12h"
echo "dhcp-boot=scgy-cfg.kpxe"
echo "enable-tftp"
echo "tftp-root=/home/libreliu/RDMA/Netboot/scgy-pxe-recovery/"
echo "======================"

sudo systemctl restart dnsmasq.service

echo "Third, setup FTP server."
echo "In this example, pyftpdlib is used."
echo "Make sure that you've configurated username and password."
echo "Make sure that the user get the permission to write"
echo "and make sure that directory exists."

python -m pyftpdlib -w