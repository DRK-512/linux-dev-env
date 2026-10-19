#!/usr/bin/env bash

# Usage: This file has script for checking the operating system currently running
# And ensuring it is compatiable with the build system
# If there is a valid OS, it prints the token to stdout
# Exits via log_error on unsupported OS.
detect_os()
{
    local os_id=""
    local version_id=""

    if [[ ! -r /etc/os-release ]]; then
        log_error "Cannot read /etc/os-release"
    fi

    # Source only ID and VERSION_ID. os-release is trusted host metadata.
    # shellcheck disable=SC1091
    os_id="$(. /etc/os-release && printf '%s' "${ID}")"
    version_id="$(. /etc/os-release && printf '%s' "${VERSION_ID}")"

    case "${os_id}:${version_id}" in
        debian:13 | debian:13.* | ubuntu:26.04)
            printf '%s\n' "debian13"
            ;;
        rocky:10 | rocky:10.*)
            printf '%s\n' "rocky10"
            ;;
        arch:*)
            printf '%s\n' "arch"
            ;;
        *)
            log_error "Unsupported OS '${os_id}' version '${version_id}'. Compatible: Debian 13, Rocky Linux 10"
            ;;
    esac
}
