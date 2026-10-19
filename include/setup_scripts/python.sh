#!/usr/bin/env bash

# Usage: This file has a set of script for setting up the python package on the Systems
# and it provides a way to validate them

# This script will install all the required python packages defined in packages.sh
python_setup()
{
    log_info "Checking python packages ..."

    PIP_INSTALL_LIST=()
    for key in "${PIP_PACKAGE_LIST[@]}"; do
        if ! pip list 2> /dev/null | grep -iq "^${key} "; then
            PIP_INSTALL_LIST+=("${key}")
        fi
    done

    # Check if there are more any elements in the install list
    if ((${#PIP_INSTALL_LIST[@]} > 0)); then
        # pipx creates a virtualized package as opposed to conflicting with apt packages
        sudo pipx ensurepath --global
        sudo pipx install --global "${PIP_INSTALL_LIST[@]}"
        # Once we fetch the cmakelang we must injecy PyYAML into it so it works properly
        sudo pipx inject --global cmakelang PyYAML
    fi

    log_success "All python packages installed"
}

# Check pip packages. Use the user that ran sudo (since installs were done as that user)
check_pip_packages()
{
    log_info "Verifying pip packages..."

    local pip_list_output
    # Prefer SUDO_USER's pip list, since python_setup installed for that user
    if [[ -n "$INPUT_USER" ]] && id "$INPUT_USER" &> /dev/null; then
        pip_list_output="$(sudo -u "$INPUT_USER" pip3 list 2> /dev/null)"
    else
        pip_list_output="$(pip3 list 2> /dev/null)"
    fi

    if [[ -z "$pip_list_output" ]]; then
        record_missing "PIP" "pip3 produced no output -- pip3 may not be installed"
        return
    fi

    for pkg in "${PIP_PACKAGE_LIST[@]}"; do
        # -F = fixed-string, -i = case-insensitive (pip names are normalized)
        if ! echo "$pip_list_output" | grep -iF "$pkg" &> /dev/null; then
            # If not in pip list, check if its in /usr/local/bin since pipx installs there
            if ! find /usr/local/bin -name "*${pkg}*" -exec sh -c 'exit 0' \; -quit 2> /dev/null; then
                record_missing "PIP" "$pkg"
            fi
        fi
    done
}
