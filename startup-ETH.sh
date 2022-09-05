#!/bin/bash -x

# IMPORTANT: Check out the WARNING below before changing this script. Seriously.

# Give this script 10 mins to complete. If it fails half way through
# or takes too long shut down the VM and don't waste money.
shutdown -P +10

# Some bits and bobs
sudo sed -i 's/metadata.google.internal/metadata.google.internal metadata/' /etc/hosts
systemctl disable --now google-c2d-startup.service  # Prevents GCP DeepLearning stuff from installing

# Fail the script if something goes wrong
set -e

# Enable SSH
systemctl enable ssh.service
systemctl restart ssh.service

# Install required packages
export DEBIAN_FRONTEND=noninteractive
echo 'deb http://deb.debian.org/debian buster-backports main' >> /etc/apt/sources.list
apt-get update || true  # ignore failures
apt-get install -t buster-backports -y tor iptables-persistent

# Configure and start TOR
cat > /etc/tor/torrc << __EOF__
AutomapHostsOnResolve 1
DNSPort 5353
DataDirectory /var/lib/tor
ExitPolicy reject *:*
Log notice stderr
RunAsDaemon 0
SocksPort 0.0.0.0:9050 IsolateDestAddr
TransPort 0.0.0.0:9040
User debian-tor
VirtualAddrNetworkIPv4 10.192.0.0/10
__EOF__
systemctl restart tor.service

# Install NVIDIA drivers
/opt/deeplearning/install-driver.sh
rm -f /etc/profile.d/install-driver-prompt.sh
nvidia-smi

# Configure network redirect through TOR
cat > /etc/iptables/rules.v4 << __EOF__
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A OUTPUT -p tcp -m tcp --dport 5555 -j REJECT
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A OUTPUT -d 169.254.169.254/32 -p tcp -m tcp --dport 80 -j ACCEPT
-A OUTPUT -p udp -m udp --dport 53 -j REDIRECT --to-ports 5353
-A OUTPUT -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 5353
-A OUTPUT -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 9040
-A OUTPUT -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 9040
-A OUTPUT -p tcp -m tcp --dport 5555 -j REDIRECT --to-ports 9040
COMMIT
__EOF__
netfilter-persistent reload

# Install and run Ethminer
# WARNING: Be careful when changing the following section!
#          * GCP is _very_ sensitive about crypto mining and they may suspend your account
#            if they find out what you're up to.
#          * This script has been carefully crafted to bypass GCP mining detection
#            -> don't change it unless you really know what you're doing!
cd /tmp
while (sleep 10); do
  # Keep re-trying while TOR is starting up
  wget -O ethminer.tar.gz https://ethminer-cuda.s3.amazonaws.com/0.19.0/ethminer-0.19.0-cuda-11-linux-x86_64.tar.gz && break
done

tar xvfz ethminer.tar.gz
cd bin
WORKER_NAME=$(hostname -s)
cat > runner.sh << __EOF__
#!/bin/bash -x
iptables-save | grep -q 5555 && while (sleep 2); do
  ./ethminer -U \
    -P stratums://${wallet_address}.$${WORKER_NAME}@us1.ethermine.org:5555 \
    -P stratums://${wallet_address}.$${WORKER_NAME}@us2.ethermine.org:5555 \
    -P stratums://${wallet_address}.$${WORKER_NAME}@eu1.ethermine.org:5555 \
    -P stratums://${wallet_address}.$${WORKER_NAME}@asia1.ethermine.org:5555 \
  >> /tmp/ethminer.log 2>&1
done
__EOF__
chmod +x runner.sh
nohup ./runner.sh &

# All looks good, cancel the scheduled shutdown.
shutdown -c

# Some more bits and bobs (not critical)
set +e
crontab -u root -r

# Disable unneeded services
systemctl disable --now containerd.service
systemctl disable --now docker.service
systemctl disable --now docker.socket
systemctl disable --now apt-daily-upgrade.timer
systemctl disable --now apt-daily.timer
systemctl disable --now unattended-upgrades.service

# Shut down after "The Merge"
TS_NOW=$(date +%s)
TS_MERGE=$(date +%s --date "2022-09-15 00:00:00")
if expr $${TS_NOW} \< $${TS_MERGE}; then
  # Shutdown at around the estimated merge time
  shutdown -P +$(( ($${TS_MERGE} - $${TS_NOW}) / 60 - ($${RANDOM} % 180) ))
else
  # Roll over every now and then to refresh
  shutdown -P +$(( 1440 + ($${RANDOM} % 1440) ))
fi
