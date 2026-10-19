#!/usr/bin/env bash

# Usage: This file sets up the dnf packages for rockylinux10, and provideds a way to validate them

# This script installs all the dnf packages defined in packages.sh
rocky10_package_fetch()
{
    log_info "Looking for missing dnf packages ..."

    # Pre install check
    check_connection
    sudo dnf update -y
    if ! command -v sudo &> /dev/null; then
        dnf install sudo -y
    fi
    sudo dnf groupinstall "Development Tools" -y

    # Rocky Linux handles development tools through the Code Ready Builder (CRB) repository
    # This is needed to install certain tools
    sudo dnf install -y 'dnf-command(config-manager)'
    sudo dnf config-manager --set-enabled crb
    sudo dnf --refresh install -y doxygen flex-devel
    sudo dnf install -y epel-release

    MISSING_DNF_LIST=()
    # Check if dnf packages are already installed
    for key in "${DNF_PACKAGE_LIST[@]}"; do
        if ! rpm -q "$key" &> /dev/null; then

            # Enable CodeReady Builder (CRB) for development tools
            if [[ "${key}" == "gcc-aarch64-linux-gnu" ]] || [[ "${key}" == "gcc-c++-aarch64-linux-gnu" ]]; then
                if ! dnf repolist | grep -q "crb"; then
                    log_info "Enabling CodeReady Builder repository ..."
                    sudo dnf config-manager --set-enabled crb
                fi
            fi

            MISSING_DNF_LIST+=("${key}")
        fi
    done

    # If any dnf packages are missing we will install them
    if [[ "${#MISSING_DNF_LIST[@]}" -ne 0 ]]; then
        # The * looks better for logging
        log_info "The following packages were not installed: ${MISSING_DNF_LIST[*]}"
        log_info "Now checking if they exist within dnf ..."

        # Check if required packages exist
        for key in "${MISSING_DNF_LIST[@]}"; do
            if ! dnf info "${key}" &> /dev/null; then
                log_error "Cannot find package: ${key}"
                exit 1
            fi
        done

        log_info "Now installing missing dnf packages ..."
        sudo dnf install "${MISSING_DNF_LIST[@]}" -y
        sudo dnf clean all -y
        sudo dnf autoremove -y
    fi
    # This must be installed after everything else
    if ! rpm -q libudev-devel &> /dev/null; then
        sudo dnf install libudev-devel -y
    fi

    # When installing flex, it brings in the static libs, not shared the ones, so I have to change that
    if [[ -f /usr/lib64/libfl.a ]]; then
        mkdir flex_tmp
        cd ./flex_tmp || log_error "Failed to create flex_tmp dir"
        ar x /usr/lib64/libfl.a
        gcc -shared -o libfl.so.2 ./*.o
        sudo cp ./libfl.so.2 /usr/lib64/
        sudo ln -sf /usr/lib64/libfl.so.2 /usr/lib64/libfl.so
        sudo ldconfig
        cd ../
        rm -rf ./flex_tmp
    fi

    # Rocky does not setup the sysroot completely, so we need to do this
    sudo dnf install \
        --installroot="/usr/aarch64-linux-gnu/sys-root" \
        --releasever=10 \
        --forcearch=aarch64 \
        --repofrompath=baseos-aarch64,https://download.rockylinux.org/pub/rocky/10/BaseOS/aarch64/os/ \
        --repofrompath=appstream-aarch64,https://download.rockylinux.org/pub/rocky/10/AppStream/aarch64/os/ \
        --setopt=install_weak_deps=False \
        --nogpgcheck \
        -y \
        glibc \
        glibc-devel \
        glibc-headers \
        libgcc \
        libstdc++ \
        libstdc++-devel \
        kernel-headers

    # Create the symlink that the linker needs for cross-compiling
    ## This date changed all the time, so I gotta catch it
    local saved
    saved=$(shopt -p nullglob extglob) || true # shopt -p returns non-zero if any opt is OFF; that's expected
    shopt -s nullglob extglob
    # Resolve the actual file (8-digit date constrained for safety).
    matches=(/usr/aarch64-linux-gnu/sys-root/lib64/libgcc_s-14-\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9].so.1)
    eval "$saved" # Now turning off nullglob since we might want it later

    # Fail loud on zero or multiple matches — no silent guessing.
    if ((${#matches[@]} != 1)); then
        log_error "ERROR: expected exactly 1 match, got ${#matches[@]}"
    fi

    libpath="${matches[0]}"

    # Strip prefix up to and including 'libgcc_s-14-', then strip the '.so.1' suffix.
    # Pure bash parameter expansion — no external processes, no word-splitting risk.
    date="${libpath##*libgcc_s-14-}" # -> 20251022.so.1
    date="${date%.so.1}"             # -> 20251022
    # With the date captured, I can create the correct sym links
    sudo ln -sf /usr/aarch64-linux-gnu/sys-root/lib64/libgcc_s-14-"$date".so.1 \
        /usr/aarch64-linux-gnu/sys-root/lib64/libgcc_s.so.1
    sudo ln -sf /usr/aarch64-linux-gnu/sys-root/lib64/libgcc_s.so.1 \
        /usr/aarch64-linux-gnu/sys-root/lib64/libgcc_s.so

    log_success "All dnf packages installed"
}

# Check dnf packages defined in packages.sh via rpm
check_dnf_packages()
{
    log_info "Verifying dnf packages..."
    for pkg in "${DNF_PACKAGE_LIST[@]}"; do
        if ! rpm -q "$pkg" &> /dev/null; then
            if ! command -v "$pkg" &> /dev/null; then
                record_missing "DNF" "$pkg"
            fi
        fi
    done
}
