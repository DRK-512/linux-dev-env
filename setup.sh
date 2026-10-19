#!/usr/bin/env bash

# Reference the README to learn about this script
config() {
        if [[ -f "$SCRIPT_DIR/../scripts/config.sh" ]]; then
                # shellcheck source=./config.sh
                source "$SCRIPT_DIR/../scripts/config.sh"
        else
                echo -e "\e[31mERROR: Cannot find config.sh\e[0m"
                exit 1
        fi

        if [[ -f "$SCRIPT_DIR/arch.sh" ]] &&  \
        [[ -f "$SCRIPT_DIR/bash_setup.sh" ]] && \
        [[ -f "$SCRIPT_DIR/debian.sh" ]] && \
        [[ -f "$SCRIPT_DIR/fetch_depends.sh" ]] && \
        [[ -f "$SCRIPT_DIR/net.sh" ]] && \
        [[ -f "$SCRIPT_DIR/os_check.sh" ]] && \
        [[ -f "$SCRIPT_DIR/packages.sh" ]] && \
        [[ -f "$SCRIPT_DIR/python.sh" ]] && \
        [[ -f "$SCRIPT_DIR/rocky.sh" ]] && \
        [[ -f "$SCRIPT_DIR/rust.sh" ]]; then
        
                source "$SCRIPT_DIR/arch.sh"
                source "$SCRIPT_DIR/bash_setup.sh"
                source "$SCRIPT_DIR/debian.sh"
                source "$SCRIPT_DIR/fetch_depends.sh"
                source "$SCRIPT_DIR/net.sh"
                source "$SCRIPT_DIR/os_check.sh"
                source "$SCRIPT_DIR/packages.sh"
                source "$SCRIPT_DIR/python.sh"
                source "$SCRIPT_DIR/rocky.sh"
                source "$SCRIPT_DIR/rust.sh"

        else
                log_error "Cannot find required source files"
        fi

        INPUT_USER=""
        # Check if the program was ran with sudo
        if [[ "$EUID" -eq 0 ]] && [[ -e $SUDO_USER ]]; then
                INPUT_USER=$SUDO_USER
        else
                INPUT_USER=$(id -un)
        fi

        log_info "Starting ${INPUT_USER} environment setup..."
}

main() {
        # Vars defined globally
        SCRIPT_DIR="$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)/include/setup_scripts"

        # Define which constants are readonly
        readonly SCRIPT_DIR
        
        config
        # The rest of the functions are found in ./scripts/setup_scripts/
        check_connection

        git submodule update --init --recursive

        package_setup
        rust_setup
        python_setup

        bashrc_setup
        nvim_config
        color_setup
        setup_scripts

        # Create sudo file so user is not notified
        sudo touch ~/.sudo_as_admin_successful

        log_success "Success! please run the following then reboot your machine"
        log_success "newgrp docker"
}

main "$@"
