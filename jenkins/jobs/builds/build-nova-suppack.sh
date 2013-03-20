set -eux

# Update system and install dependencies
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get -qy upgrade
sudo apt-get install -qy git rpm

# Packages needed for ddk unpack
sudo apt-get install -qy kpartx qemu-utils

# Create suppack
GITREPO="$1"
git clone "$GITREPO"
cd nova
cd plugins/xenserver/xenapi/contrib/
./build-rpm.sh

# Get old of ddk
cd
RPMFILE=$(find -name "*.noarch.rpm" -print)

mkdir suppack

wget -q http://copper.eng.hq.xensource.com/ddk.iso
DDKMOUNT=$(mktemp -d)
sudo mount -o loop ddk.iso $DDKMOUNT
( for CHUNK in $DDKMOUNT/ddk/xvda/*; do zcat $CHUNK; done; ) | dd of=xvda.vhd
qemu-img convert xvda.vhd -O raw xvda.raw
sudo kpartx -av xvda.raw

DDKROOT=$(mktemp -d)
sudo mount /dev/mapper/loop1p1 $DDKROOT

sudo mkdir $DDKROOT/mnt/host
sudo mount --bind $(pwd) $DDKROOT/mnt/host

sudo chroot $DDKROOT /usr/bin/build-supplemental-pack.sh \
--output=/mnt/host/suppack \
--vendor-code=novaplugin \
--vendor-name=openstack \
--label=novaplugins \
--text="nova plugins" \
--version=0 \
/mnt/host/$RPMFILE

exit 0
# Cleanup
sudo umount $DDKROOT/mnt/host
sudo umount $DDKROOT
sudo kpartx -d xvda.raw
sudo umount $DDKMOUNT