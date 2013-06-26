#!/bin/bash

set -eu

function print_usage_and_die
{
cat >&2 << EOF
usage: $0 XENSERVER_IP XENSERVER_PASS

A simple script to test a XenServer devstack with Neutron

positional arguments:
 XENSERVER_IP     The IP address of the XenServer
 XENSERVER_PASS   The root password for the XenServer

An example run:

$0 10.219.10.25 mypassword
EOF
exit 1
}

XENSERVER_IP="${1-$(print_usage_and_die)}"
XENSERVER_PASS="${2-$(print_usage_and_die)}"

set -eux

ssh -q \
    -o Batchmode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "root@$XENSERVER_IP" bash -s -- << END_OF_XENSERVER_COMMANDS
set -exu
rm -rf "devstack-master"
wget -qO - https://github.com/openstack-dev/devstack/archive/master.tar.gz |
    tar -xzf -
cd "devstack-master"

cat << LOCALRC_CONTENT_ENDS_HERE > localrc
# Passwords
MYSQL_PASSWORD=citrix
SERVICE_TOKEN=citrix
ADMIN_PASSWORD=citrix
SERVICE_PASSWORD=citrix
RABBIT_PASSWORD=citrix
GUEST_PASSWORD=citrix
XENAPI_PASSWORD="$XENSERVER_PASS"
SWIFT_HASH="66a3d6b56c1f479c8b4e70ab5c2000f5"

# Use xvdb for backing cinder volumes
XEN_XVDB_SIZE_GB=10
VOLUME_BACKING_DEVICE=/dev/xvdb

# Tempest
DEFAULT_INSTANCE_TYPE="m1.tiny"

# Compute settings
EXTRA_OPTS=("xenapi_disable_agent=True")
API_RATE_LIMIT=False
VIRT_DRIVER=xenserver

# Cinder settings
VOLUME_BACKING_FILE_SIZE=10000M

# Networking
MGT_IP="dhcp"

PUB_IP=172.24.4.10
PUB_NETMASK=255.255.255.0

# Expose OpenStack services on management interface
HOST_IP_IFACE=eth2

# OpenStack VM settings
OSDOMU_MEM_MB=4096
UBUNTU_INST_RELEASE=precise
UBUNTU_INST_IFACE="eth2"
OSDOMU_VDI_GB=40

# Exercise settings
ACTIVE_TIMEOUT=500
TERMINATE_TIMEOUT=500

# Increase boot timeout for quantum tests:
BOOT_TIMEOUT=500

# DevStack settings
LOGFILE=/tmp/devstack/log/stack.log
SCREEN_LOGDIR=/tmp/devstack/log/
VERBOSE=False

# XenAPI specific
XENAPI_CONNECTION_URL="http://$XENSERVER_IP"
VNCSERVER_PROXYCLIENT_ADDRESS="$XENSERVER_IP"

Q_PLUGIN=openvswitch
MULTI_HOST=False
ENABLED_SERVICES+=,tempest,quantum,q-svc,q-agt,q-dhcp,q-l3,q-meta,q-domua,-n-net

# Disable security groups
Q_USE_SECGROUP=False

# With XenServer single box install, VLANs need to be enabled
ENABLE_TENANT_VLANS="True"
OVS_VLAN_RANGES="physnet1:1000:1024"

# CLEAN_TEMPLATES=true

Q_USE_DEBUG_COMMAND=True

SKIP_EXERCISES=boot_from_volume,client-env

# Use a XenServer Image
IMAGE_URLS="https://github.com/downloads/citrix-openstack/warehouse/cirros-0.3.0-x86_64-disk.vhd.tgz"
DEFAULT_IMAGE_NAME="cirros-0.3.0-x86_64-disk"

# Citrix specific settings to speed up Ubuntu install (Remove them)
UBUNTU_INST_HTTP_HOSTNAME="mirror.anl.gov"
UBUNTU_INST_HTTP_DIRECTORY="/pub/ubuntu"
UBUNTU_INST_HTTP_PROXY="http://gold.eng.hq.xensource.com:8000"

# Citrix settings (Remove them)
CEILOMETER_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/ceilometer.git
CEILOMETERCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-ceilometerclient.git
CINDER_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/cinder.git
CINDERCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-cinderclient.git
NOVA_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/nova.git
SWIFT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/swift.git
SWIFT3_REPO=git://gold.eng.hq.xensource.com/git/github/fujita/swift3.git
SWIFTCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-swiftclient.git
GLANCE_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/glance.git
GLANCECLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-glanceclient.git
KEYSTONE_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/keystone.git
NOVNC_REPO=git://gold.eng.hq.xensource.com/git/github/kanaka/noVNC.git
HORIZON_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/horizon.git
NOVACLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-novaclient.git
OPENSTACKCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-openstackclient.git
KEYSTONECLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-keystoneclient.git
QUANTUMCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-quantumclient.git
QUANTUM_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/quantum.git
TEMPEST_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/tempest.git
HEAT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/heat.git
HEATCLIENT_REPO=git://gold.eng.hq.xensource.com/git/github/openstack/python-heatclient.git
RYU_REPO=git://gold.eng.hq.xensource.com/git/github/osrg/ryu.git
BM_IMAGE_BUILD_REPO=git://gold.eng.hq.xensource.com/git/github/stackforge/diskimage-builder.git
BM_POSEUR_REPO=git://gold.eng.hq.xensource.com/git/github/tripleo/bm_poseur.git

NOVA_ZIPBALL_URL="http://gold.eng.hq.xensource.com/git/github/openstack/nova/zipball/master"
QUANTUM_ZIPBALL_URL="http://gold.eng.hq.xensource.com/git/github/openstack/quantum/zipball/master"

LOCALRC_CONTENT_ENDS_HERE

cd tools/xen
./install_os_domU.sh
END_OF_XENSERVER_COMMANDS


# Run tests
ssh -q \
    -o Batchmode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "root@$XENSERVER_IP" bash -s -- << END_OF_XENSERVER_COMMANDS
set -exu
GUEST_IP=\$(. devstack-master/tools/xen/functions && find_ip_by_name DevStackOSDomU 2)
ssh -q \
    -o Batchmode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "stack@\$GUEST_IP" bash -s -- << END_OF_DEVSTACK_COMMANDS
set -exu
cd /opt/stack/devstack/

echo "---- EXERCISE TESTS ----"
./exercise.sh

cd /opt/stack/tempest 
echo "---- TEMPEST TESTS ----"
nosetests -sv --nologcapture --attr=type=smoke tempest
END_OF_DEVSTACK_COMMANDS

END_OF_XENSERVER_COMMANDS