#!/bin/bash

pkg_path() {
	if [[ -L "$0" ]]; then
		dirname "$(readlink $0)"
	else
		dirname "$0"
	fi
}

check_optdepends() {
	if [[ -n "$(command -v $1)" ]]; then
		return 0
	else
		return 1
	fi
}

#fallback_view() {
#	printf "\nIncorrect USER_INTERFACE setting -- falling back to default\n" 1>&2
#	read
#	source $(pkg_path)/view/dialog.sh
#}

repair_settings() {
	read -r -p "Would you like to repair settings? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		update_settings
	fi
}

source_settings() {
	source $(pkg_path)/settings.sh
}

source_service() {
	source $(pkg_path)/service/news.sh
	source $(pkg_path)/service/upgrade.sh
	source $(pkg_path)/service/cleanup.sh
	source $(pkg_path)/service/errors.sh
	source $(pkg_path)/service/backup.sh
	source $(pkg_path)/service/settings.sh
}

source_controller() {
	source $(pkg_path)/controller.sh
}

execute_main() {
	main
	test "$?" == 1 && repair_settings
}

if [[ "$EUID" -ne 0 ]]; then
	printf "This script must be run as root\n" 1>&2
	exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
	source_settings
	source_service
	source_controller

#	case "$USER_INTERFACE" in
#		'cli')
#			source $(pkg_path)/view/cli.sh;;
#		'dialog')
#			source $(pkg_path)/view/dialog.sh;;
#		*)
#			fallback_view;;	
#	esac

        source $(pkg_path)/view/cli.sh
	execute_main
fi
