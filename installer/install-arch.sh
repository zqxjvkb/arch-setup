#!/usr/bin/env bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Set preliminary variables
echo -n "Hostname: "
read hostname
: "${hostname:?"Missing hostname"}"

echo -n "Password: "
read -s password
echo
echo -n "Repeat Password: "
read -s password2
echo
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

echo -e "\nDisks:"
lsblk

echo -e "\nChoose a disk from the above:"
read disk
echo -n "Size of boot partition (in MiB): "
read boot_size
echo -n "Size of swap partition (in MiB): "
read swap_size
boot_end=$(1 + $boot_size + 1)MiB
swap_end=$($boot_end + $swap_size + 1)MiB

# Partition disk
parted --script "${disk}" -- mklabel gpt \
       mkpart ESP fat32 1Mib ${boot_end} \
       set 1 boot on \
       mkpart primary linux-swap ${boot_end} ${swap_end} \
       mkpart primary ext4 ${swap_end} 100%
