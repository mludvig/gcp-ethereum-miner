#!/bin/bash

set -x
pwd

echo nameserver 127.0.0.1 > /etc/resolv.conf

systemctl disable --now jupyter.service
systemctl disable --now docker.service
systemctl disable --now docker.socket

sleep 60
set -e

# Do it again just in case
echo nameserver 127.0.0.1 > /etc/resolv.conf

cd /home/garbagetruck/bin/
nohup ./pool_ethermine.sh ${wallet_address} > /tmp/ethminer.log 2>&1 &
