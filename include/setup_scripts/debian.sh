#!/usr/bin/env bash

# Usage: This file has a set of script used for building/checking the debian container

# This function will fetch all the require apt packages for the debian 13 container
debian13_package_fetch()
{
    log_info "Looking for missing apt packages ..."
    # Pre install check
    sudo apt-get update -y
    sudo apt-get upgrade -y

    MISSING_APT_LIST=()
    # Check if apt packages are already installed
    for key in "${APT_PACKAGE_LIST[@]}"; do
        if ! dpkg -s "$key" &> /dev/null; then
            [[ "${key}" == "libjsoncpp-dev" ]] && sudo ln -s /usr/include/jsoncpp/json /usr/include/json
            MISSING_APT_LIST+=("${key}")
        fi
    done

    # If any apt packages are missing we will install them
    if [[ "${#MISSING_APT_LIST[@]}" -ne 0 ]]; then
        # The * looks better for logging
        log_info "The following packages were not install: ${MISSING_APT_LIST[*]}"
        log_info "Now checking if they exist within apt ..."

        # Check if required packages & version exists
        for key in "${MISSING_APT_LIST[@]}"; do
            if ! apt-cache show "${key}" &> /dev/null; then
                log_error "Cannot find package: ${key}"
                exit 1
            fi
        done

        log_info "Now installing missing apt packages ..."

        sudo apt-get install "${MISSING_APT_LIST[@]}" -y
        sudo apt-get autoclean -y
        sudo apt-get autoremove -y
    fi
    log_success "All apt packages installed"
}

# Check apt packages exist via dpkg
check_apt_packages()
{
    log_info "Verifying apt packages..."
    for pkg in "${APT_PACKAGE_LIST[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            if ! command -v "$pkg" &> /dev/null; then
                record_missing "APT" "$pkg"
            fi
        fi
    done
}
