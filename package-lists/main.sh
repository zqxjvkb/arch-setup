#!/bin/bash

packages=(
    # Package groups TODO: this doesn't work because sync_package_groups removes all the members since the group members aren't explicitly listed here
#    base-devel xorg
    
    # Base packages
    base linux linux-firmware man-db man-pages

    # Packages relating to arch and pacman
    pacman-contrib pacutils reflector

    # Bootloader and related packages
    grub efibootmgr dosfstools os-prober mtools

    # Basic utilities
    networkmanager git cronie

    # Higher-level utilities
    vim emacs firefox qutebrowser mpv youtube-dl

    # xorg-related packages
    xorg-xinit

    # Sound
    alsa-utils alsa-plugins jack2 realtime-privileges qjackctl

    # Make dependencies
    cmake

    # Virtual machines
    qemu libvirt virt-manager ebtables iptables dnsmasq edk2-ovmf

    # Backup
    borg

    # Password manager
    keepassxc

    # Cloud services
    rclone
)

# TODO: package groups work on host machine but not in vm for some reason, does changing -Qqg to -Sqg fix it?
package_groups=(
    base-devel xorg
)
#packages+=(${package_groups[@]})
for group in ${package_groups[@]};
do
    packages+=($(pacman -Sqg $group))
done


packages_aur=(
    discord-canary reaper-bin unityhub yay-git
)

packages_dell_latitude=(
    # Drivers
    xf86-video-vesa sof-firmware
)
packages+=(${packages_dell_latitude[@]})
: '
packages_unneeded=(
    accountsservice alacritty devtools expac iwd lightdm lightdm-slick-greeter lightdm-gtk-greeter lsof luit maint pavucontrol picom pulseaudio-alsa pulseaudio-git s3cmd 
)
packages_unneeded+=$(pacman -Sgq gnome)
packages+=(${packages_unneeded[@]})
'
sync_packages()
{
    # Sync regular packages
    output_packages > temp_package_list.txt
    if [[ "$1" == "--noconfirm" ]]
    then
	sudo pacman -S --needed --noconfirm - < temp_package_list.txt
	sudo pacman -Rsu --noconfirm $(comm -23 <(pacman -Qqe | sort) <(sort temp_package_list.txt))
	if ! pacman -Qi yay-git > /dev/null ;
	then
	    git clone https://aur.archlinux.org/yay-git.git
	    cd yay-git
	    makepkg -si
	    cd ..
	    rm -rf yay-git
	fi
	output_aur_packages > temp_package_list.txt
	yay -S --needed --noconfirm - < temp_package_list.txt
	yay -Rsu --noconfirm $(comm -23 <(pacman -Qqm | sort) <(sort temp_package_list.txt))
    else
	sudo pacman -S --needed - < temp_package_list.txt
	sudo pacman -Rsu $(comm -23 <(pacman -Qqe | sort) <(sort temp_package_list.txt))
	if ! pacman -Qi yay-git > /dev/null ;
	then
	    git clone https://aur.archlinux.org/yay-git.git
	    cd yay-git
	    makepkg -si
	    cd ..
	    rm -rf yay-git
	fi
	output_aur_packages > temp_package_list.txt
	yay -S --needed - < temp_package_list.txt
	yay -Rsu $(comm -23 <(pacman -Qqm | sort) <(sort temp_package_list.txt))
    fi
    rm temp_package_list.txt
}

output_packages()
{
    for p in ${packages[@]};
    do
	echo $p
    done | sort
}
# Maybe do these together instead of separately?
output_aur_packages()
{
    for p in ${packages_aur[@]};
    do
	echo $p
    done | sort
}


diff_packages()
{
    comm -3 <(pacman -Qqe | sort) <(output_packages) # this can only be run in bash not sh, since there's no process substitution in posix
}

# Meant to be run after a clean (re)install of linux
post_install()
{
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg
    systemctl enable NetworkManager
    systemctl enable libvirtd
    # adding groups (this assumes the user is jw)
    usermod -aG libvirt,realtime jw
}
