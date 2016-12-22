## install fedora aarch64 on your raspberry

download the folliwing image
follow these steps for installation


## configure wifi -- didn't work

git clone https://github.com/RPi-Distro/firmware-nonfree.git
cd firmware-nonfree/brcm80211/brcm/
cp brcmfmac43430-sdio.bin brcmfmac43430-sdio.txt /lib/firmware/brcm/
reboot

systemctl enable NetworkManager
systemctl start NetworkManager
dnf install NetworkManager-tui

nmcli con add con-name tplink ifname wlan0 type wifi ssid TP-LINK_26A6
nmcli con modify tplink wifi-sec.key-mgmt wpa-psk
nmcli con modify tplink wifi-sec.psk 89493434

#build openshift images

```
make release
./hack/build-base-images.sh
./hack/build-images.sh

docker login

for i in `docker images | grep 'raffaelespazzoli/origin-' | grep latest | awk '{print $1}'`; do docker push $i:latest; done; 


#host preparation
setup ssh keys
setup dnsmasq for forward and reverse name resolution
boostrap ansible-needed packages
dnf install -y python2 python2-dnf libselinux-python libsemanage-python python2-firewall pyOpenSSL python-cryptography

