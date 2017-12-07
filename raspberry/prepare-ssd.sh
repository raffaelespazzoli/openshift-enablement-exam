sudo arm-image-installer -y --image=/home/rspazzol/Downloads/Fedora-Minimal-27-1.6.aarch64.raw.xz --target=rpi3 --media=/dev/sdb
gparted /dev/sdb (grow /sdb/sdb5 to occupy all the available space)
sudo curl https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm80211/brcm/brcmfmac43430-sdio.txt -o /run/media/rspazzol/b3bf6fcd-c6d0-4afa-bcd9-784ae8690f7e/lib/firmware/brcm/brcmfmac43430-sdio.txt
sudo mkdir -p /run/media/rspazzol/b3bf6fcd-c6d0-4afa-bcd9-784ae8690f7e/root/.ssh
sudo cat /home/rspazzol/.ssh/id_rsa.pub > /run/media/rspazzol/b3bf6fcd-c6d0-4afa-bcd9-784ae8690f7e/root/.ssh/authorized_keys
sudo chmod -R 600 /run/media/rspazzol/b3bf6fcd-c6d0-4afa-bcd9-784ae8690f7e/root/.ssh


on each running raspberry
hostnamectl set-hostname master
nmcli device wifi connect TP-LINK_24A6 password 89493434
dnf install python