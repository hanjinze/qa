set -eu

function print_usage_and_quit
{
cat << USAGE >&2
usage: $0 ISOURL XENSERVER VMNAME NETNAME SSHKEY

Install a DHCP enabled virtual hypervisor on XENSERVER with the name VMNAME.
 - one network interface, connected to NETNAME network on XENSERVER.
 - to connect to XENSERVER, SSHKEY will be used

Positional arguments:
  ISOURL    - An url containing the original XenServer iso
  XENSERVER - Target XenServer
  VMNAME    - Name of the VM
  NETNAME   - Network to use
  SSHKEY    - SSH key to use
USAGE
exit 1
}

ISOURL=${1-$(print_usage_and_quit)}
XENSERVER=${2-$(print_usage_and_quit)}
VMNAME=${3-$(print_usage_and_quit)}
NETNAME=${4-$(print_usage_and_quit)}
SSHKEY=${5-$(print_usage_and_quit)}

set -x

eval $(ssh-agent)
ssh-add "$SSHKEY"

TEMPDIR=$(mktemp -d)

XSISOFILE="$TEMPDIR/xs.iso"
CUSTOMXSISO="$TEMPDIR/xscustom.iso"
ANSWERFILE="$TEMPDIR/answerfile"
VHROOT="$TEMPDIR/vh"

function on_xenserver() {
ssh -q \
    -o Batchmode=yes \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    "root@$XENSERVER" bash -s --
}

on_xenserver << EOF
xe vm-uninstall vm="$VMNAME" force=true | true
EOF

git clone git://github.com/matelakat/virtual-hypervisor.git "$VHROOT"

wget -qO "$TEMPDIR/xs.iso" "$ISOURL"

$VHROOT/scripts/generate_answerfile.sh \
    dhcp > "$ANSWERFILE"

$VHROOT/scripts/create_customxs_iso.sh \
    "$XSISOFILE" "$CUSTOMXSISO" "$ANSWERFILE"

# Cache the server's key to known_hosts
ssh-keyscan "$XENSERVER" >> ~/.ssh/known_hosts

$VHROOT/scripts/xs_start_create_vm_with_cdrom.sh \
    "$CUSTOMXSISO" "$XENSERVER" "$NETNAME" "$VMNAME"

on_xenserver << EOF
xe vm-start vm="$VMNAME"
EOF

rm -rf "$TEMPDIR"
