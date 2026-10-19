#!/usr/bin/env bash

# Usage: This file has a set of scripts used for building/checking the Arch container

# Returns 0 if the name is a repo package or a package group
pacman_pkg_exists()
{
    local pkg="$1"
    pacman -Si "${pkg}" &> /dev/null || pacman -Sg "${pkg}" &> /dev/null
}

# Returns 0 if the name is an installed package or a fully installed group
pacman_pkg_installed()
{
    local pkg="$1"
    pacman -Qi "${pkg}" &> /dev/null || pacman -Qg "${pkg}" &> /dev/null
}

# This function will fetch all the required pacman packages for the Arch container
arch_package_fetch()
{
    log_info "Looking for missing pacman packages ..."

    # Pre install check
    # Always sync and upgrade together: -Sy without -u is a partial upgrade,
    # which Arch does not support and can break the system
    sudo pacman -Syu --noconfirm

    MISSING_PACMAN_LIST=()
    # Check if pacman packages are already installed
    for key in "${PACMAN_PACKAGE_LIST[@]}"; do
        if ! pacman_pkg_installed "${key}"; then
            MISSING_PACMAN_LIST+=("${key}")
        fi
    done

    # If any pacman packages are missing we will install them
    if [[ "${#MISSING_PACMAN_LIST[@]}" -ne 0 ]]; then
        # The * looks better for logging
        log_info "The following packages were not installed: ${MISSING_PACMAN_LIST[*]}"
        log_info "Now checking if they exist within pacman ..."

        # Check if required packages exist in the synced repos
        for key in "${MISSING_PACMAN_LIST[@]}"; do
            if ! pacman_pkg_exists "${key}"; then
                log_error "Cannot find package: ${key}"
                exit 1
            fi
        done

        log_info "Now installing missing pacman packages ..."

        sudo pacman -S --needed --noconfirm "${MISSING_PACMAN_LIST[@]}"

        # Clean uninstalled/old cached packages (keeps currently installed versions)
        sudo pacman -Sc --noconfirm

        # Remove orphans, only if there are any (pacman -Rns errors on empty input)
        mapfile -t ORPHANS < <(pacman -Qdtq)
        if [[ "${#ORPHANS[@]}" -ne 0 ]]; then
            sudo pacman -Rns --noconfirm "${ORPHANS[@]}"
        fi
    fi
    log_success "All pacman packages installed"
}

# Check pacman packages exist via pacman -Q
check_pacman_packages()
{
    log_info "Verifying pacman packages..."
    for pkg in "${PACMAN_PACKAGE_LIST[@]}"; do
        if ! pacman_pkg_installed "${pkg}"; then
            if ! command -v "${pkg}" &> /dev/null; then
                record_missing "PACMAN" "${pkg}"
            fi
        fi
    done
}
