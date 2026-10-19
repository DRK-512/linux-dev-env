#!/usr/bin/env bash

# Usage: This file has a set of script for setting up the rust crates on the system
# and provides a way to validate them

# This script will install all the rust crates, components, and packages defined in packages.sh
rust_setup()
{
    log_info "Checking rust installation ..."

    # cargo-tarpaulin cargo-pants cargo-udeps cargo-outdated cargo-careful cargo-geiger
    # Set RUSTUP_TEMP to avoid cross-device link errors in containers
    export RUSTUP_TEMP="$HOME/.rustup/tmp"
    mkdir -p "$RUSTUP_TEMP"

    # Check if cargo is installed
    if [[ -f $HOME/.cargo/env ]]; then
        # shellcheck disable=SC1091
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    elif [[ -f /home/"$INPUT_USER"/.cargo/env ]]; then
        # INPUT_USER = The login name of the user who invoked sudo
        # shellcheck disable=SC1091
        # shellcheck source=/dev/null
        source "/home/$INPUT_USER/.cargo/env"
    else
        if [[ -d $HOME/.rustup ]]; then
            # If rustup exists, clean tmp directory before operations
            log_info "Cleaning rustup temporary files..."
            rm -rf "$HOME/.rustup/tmp"/*
            rm -rf "$HOME/.rustup/downloads"/*
        fi

        check_connection
        log_info "Installing Rust"

        if [[ -d "$HOME/.rustup/" ]]; then
            log_info "Existing rustup installation detected"

            # If rustup command is available, use it to cleanly uninstall
            if command -v rustup &> /dev/null; then
                log_info "Performing clean rustup self-uninstall..."
                rustup self uninstall -y 2> /dev/null || true
            fi

            # Ensure complete removal
            rm -rf "$HOME/.rustup"
            rm -rf "$HOME/.cargo"
        fi

        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
            --default-toolchain stable \
            --profile default
        export PATH="$HOME/.cargo/bin:$PATH"
        # shellcheck disable=SC1091
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    fi

    # Install Rust components
    rustup update nightly
    log_info "Installing Rust components..."
    for component in "${RUST_COMPONENTS[@]}"; do
        if rustup target list | grep -q "$component.*installed"; then
            log_info "Target $component is already installed, skipping"
        else
            log_info "Installing component: $component"
            rustup +nightly component add "$component" || {
                log_error "Failed to install component: $component"
                # Clean and retry
                rm -rf "$HOME/.rustup/tmp"/*
                rustup +nightly component add "$component"
            }
        fi
    done

    # Install cargo tools
    log_info "Installing cargo tools..."
    for tool in "${CARGO_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            # If you don't have --locked, a compromised minor/patch release of any
            # transitive dep gets pulled in automatically
            cargo install --locked "$tool"
        fi
    done

    # Install cross-compilation targets if requested
    log_info "Setting up cross-compilation targets..."
    for target in "${RUST_TARGETS[@]}"; do
        if ! rustup target list | grep -q "$target.*installed"; then
            rustup target add "$target"
        fi
    done

    # Check if the configuration already exists
    log_info "Appending aarch64 config to config.toml"
    if [[ -f $HOME/.cargo/config.toml ]]; then
        # Make sure config has cross compiling requirements
        if ! grep -q "\[target.aarch64-unknown-linux-gnu\]" ~/.cargo/config.toml; then
            {
                echo "" >> ~/.cargo/config.toml
                echo "[target.aarch64-unknown-linux-gnu]" >> ~/.cargo/config.toml
                echo "linker = \"aarch64-linux-gnu-gcc\""
            } >> ~/.cargo/config.toml
        elif ! grep -q "linker = \"aarch64-linux-gnu-gcc\"" ~/.cargo/config.toml; then
            # If target does exist but the linker does not, add this to the following line of the target
            sed -i '/\[target\.aarch64-unknown-linux-gnu\]/a linker = "aarch64-linux-gnu-gcc"' ~/.cargo/config.toml
        fi
    else
        # Create the file with the configuration
        {
            echo "[target.aarch64-unknown-linux-gnu]"
            echo "linker = \"aarch64-linux-gnu-gcc\""
        } >> ~/.cargo/config.toml
    fi
    # Bring the installation back to the user
    if [[ -d /home/"$INPUT_USER"/.cargo/ ]]; then
        log_info "Bringing cargo install from root into $INPUT_USER"
        # Since the script is ran as root, we have to copy it to the users home
        if [[ -n $(diff -qr ~/.cargo/bin /home/"$INPUT_USER"/.cargo/bin) ]]; then
            # Using rsync to remove need for chwon command, and ignore-existing option
            rsync -avu --ignore-existing --chown="$INPUT_USER":"$INPUT_USER" ~/.cargo/ /home/"$INPUT_USER"/.cargo > /dev/null
            if [[ -n $(diff -qr ~/.cargo/bin /home/"$INPUT_USER"/.cargo/bin) ]]; then
                # Using rsync to remove need for chwon command, and ignore-existing option
                log_warning "cargo dirs dont match after redundancy check, attempting to fix"
                rsync -avu --ignore-existing /home/"$INPUT_USER"/.cargo/ ~/.cargo/ > /dev/null
            fi
        fi
    else
        rsync -avu --ignore-existing --chown="$INPUT_USER":"$INPUT_USER" ~/.cargo/ /home/"$INPUT_USER"/.cargo > /dev/null
    fi
    if [[ -d /home/"$INPUT_USER"/.rustup/ ]]; then
        log_info "Bringing rustup install from root into $INPUT_USER"
        if [[ -n $(diff -qr ~/.rustup/update-hashes/ /home/"$INPUT_USER"/.rustup/update-hashes/) ]]; then
            # If there are things in the INPUT_USER that are not in /root we will account for it
            rsync -avu --ignore-existing --chown="$INPUT_USER":"$INPUT_USER" ~/.rustup/ /home/"$INPUT_USER"/.rustup/ > /dev/null
            # If something exists in user but not root, account for it
            if [[ -n $(diff -qr ~/.rustup/update-hashes/ /home/"$INPUT_USER"/.rustup/update-hashes/) ]]; then
                log_warning "rustup dirs dont match after redundancy check, attempting to fix"
                rsync -avu --ignore-existing /home/"$INPUT_USER"/.rustup/ ~/.rustup/ > /dev/null
            fi
        fi
    else
        rsync -avu --ignore-existing --chown="$INPUT_USER":"$INPUT_USER" ~/.rustup/ /home/"$INPUT_USER"/.rustup/ > /dev/null
    fi

    # Bring cargo source to both bashrc files (root and user)
    if ! grep -q ". \"/home/$INPUT_USER/.cargo/env\"" /home/"$INPUT_USER"/.bashrc; then
        echo ". \"/home/$INPUT_USER/.cargo/env\"" >> /home/"$INPUT_USER"/.bashrc
    fi
    if ! grep -q ". \"$HOME/.cargo/env\"" "$HOME"/.bashrc; then
        echo ". \"$HOME/.cargo/env\"" >> "$HOME"/.bashrc
    fi

    log_success "Rust has completed its install"
}

# Source rust env from whatever user has it, then run a check command
# Returns 0 if rustup/cargo are usable
load_rust_env()
{
    if [[ -f "$HOME/.cargo/env" ]]; then
        # shellcheck disable=SC1091
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
        return 0
    elif [[ -n "$INPUT_USER" ]] && [[ -f "/home/$INPUT_USER/.cargo/env" ]]; then
        # shellcheck disable=SC1091
        # shellcheck source=/dev/null
        source "/home/$INPUT_USER/.cargo/env"
        export PATH="/home/$INPUT_USER/.cargo/bin:$PATH"
        return 0
    fi
    return 1
}

# This function will check the system for all rust components and crates defined in packages.sh
check_rust()
{
    log_info "Verifying Rust installation..."

    if ! load_rust_env; then
        record_missing "RUST" "cargo env not found in root or $INPUT_USER home"
        return
    fi

    if ! command -v rustup &> /dev/null; then
        record_missing "RUST" "rustup binary not found"
        return
    fi
    if ! command -v cargo &> /dev/null; then
        record_missing "RUST" "cargo binary not found"
        return
    fi

    # Components (installed against nightly per installer)
    local installed_components
    installed_components="$(rustup +nightly component list --installed 2> /dev/null)"
    for comp in "${RUST_COMPONENTS[@]}"; do
        if ! echo "$installed_components" | grep -q "^${comp}"; then
            record_missing "RUST-COMPONENT" "$comp (nightly)"
        fi
    done

    # Targets
    local installed_targets
    installed_targets="$(rustup target list --installed 2> /dev/null)"
    for tgt in "${RUST_TARGETS[@]}"; do
        if ! echo "$installed_targets" | grep -q "^${tgt}$"; then
            record_missing "RUST-TARGET" "$tgt"
        fi
    done

    # Cargo tools -- check both root and the user's cargo bin
    for tool in "${CARGO_TOOLS[@]}"; do
        local found=0
        tool_check=$tool
        if [[ $tool == "kani-verifier" ]]; then
            tool_check="kani"   
        fi
        if command -v "$tool_check" &> /dev/null; then
            found=1
        elif [[ -n "$INPUT_USER" ]] && [[ -x "/home/$INPUT_USER/.cargo/bin/$tool_check" ]]; then
            found=1
        elif [[ -x "$HOME/.cargo/bin/$tool_check" ]]; then
            found=1
        fi
        [[ $found -eq 0 ]] && record_missing "CARGO-TOOL" "$tool_check"
    done

    # Cross-compile linker config
    local cargo_cfg=""
    if [[ -f "$HOME/.cargo/config.toml" ]]; then
        cargo_cfg="$HOME/.cargo/config.toml"
    elif [[ -n "$INPUT_USER" ]] && [[ -f "/home/$INPUT_USER/.cargo/config.toml" ]]; then
        cargo_cfg="/home/$INPUT_USER/.cargo/config.toml"
    fi

    if [[ -z "$cargo_cfg" ]]; then
        record_missing "RUST-CONFIG" "cargo config.toml not found"
    else
        if ! grep -q "\[target.aarch64-unknown-linux-gnu\]" "$cargo_cfg"; then
            record_missing "RUST-CONFIG" "[target.aarch64-unknown-linux-gnu] missing in $cargo_cfg"
        fi
        if ! grep -q 'linker = "aarch64-linux-gnu-gcc"' "$cargo_cfg"; then
            record_missing "RUST-CONFIG" "aarch64 linker line missing in $cargo_cfg"
        fi
    fi
}
