#!/bin/bash

failed_services() {
    print_line
    printf "Failed systemd services:\n"
    systemctl --failed
    wait_for_keypress
}

journal_errors() {
    print_line
    printf "High priority systemd journal errors:\n"
    journalctl -p 3 -xb
    wait_for_keypress
}
