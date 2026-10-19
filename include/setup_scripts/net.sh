#!/usr/bin/env bash

# Usage: This file has a set of network script

# This script checks if you have an internet connection, and if you don't it will tell the user the http user
check_connection()
{
    local url="${CONNECTIVITY_URL:-https://deb.debian.org}"
    local http_code=""
    local curl_rc=0

    # First I check if we even have the tools to test for a connection with google
    if ! command -v curl &> /dev/null; then
        # If curl does not exist, we cant check for network connection, so just attempt to install it
        log_info "curl is not installed, attempting to install..."
        if command -v apt &> /dev/null; then
            # curl comes pre-installed with rockylinux
            if command -v sudo &> /dev/null; then
                sudo apt-get update -y
                sudo apt-get install curl -y
            else
                apt-get update -y
                apt-get install curl sudo software-properties-common apt-utils -y
            fi
            # curl comes pre-installed with rockylinux, but if someone deleted it, then we have this
        elif command -v dnf &> /dev/null; then
            sudo dnf install curl -y
        else
            log_error "Neither apt nor dnf package manager was found on this system"
        fi
        # Check if the installation was successful
        if ! command -v curl &> /dev/null; then
            log_error "Failed to install curl. Please check your internet connection"
            exit 1 # Exit with an error code
        fi
    fi

    # This checks if you have a network connection by trying to curl google.com and seeing if you get something that is not 000
    # I used to check for just code 200 but turns out if you have a VPN that can change
    # --fail-with-body is not used: we want the status even on 4xx/5xx.
    # --max-time bounds a hung proxy. pipefail is already on via config.sh.
    http_code="$(
        curl \
            --silent \
            --show-error \
            --output /dev/null \
            --connect-timeout 10 \
            --max-time 30 \
            --write-out '%{http_code}' \
            --proto '=https' \
            --tlsv1.2 \
            "${url}"
    )" || curl_rc=$?

    case "${http_code}" in
        000)
            log_error "No network path to ${url} (curl exit ${curl_rc}, HTTP 000)"
            ;;
        2?? | 3??)
            log_info "Network reachable: ${url} returned HTTP ${http_code}"
            return 0
            ;;
        401 | 403)
            # Auth failure still proves the host is reachable (common behind VPN/proxy).
            log_warning "Reachable but unauthorized: ${url} HTTP ${http_code}"
            return 0
            ;;
        4??)
            log_error "HTTP client error from ${url}: ${http_code}"
            ;;
        5??)
            log_error "HTTP server error from ${url}: ${http_code}"
            ;;
        *)
            log_error "Unexpected HTTP status from ${url}: '${http_code}' (curl exit ${curl_rc})"
            ;;
    esac
}
