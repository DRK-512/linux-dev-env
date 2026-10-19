#!/usr/bin/env bash

# For information on this script, look at the usage function below
usage()
{
    cat << EOF
Usage: ./$0 [OPTIONS]

Options:
  -h, --help          Display this help message

Example:
  # Fetch all the software defined in the packages.sh file
  ./$0
EOF
}

# Filter input flags
parse_args()
{
        inputs=("$@")
        for ((i = 0; i < ${#inputs[@]}; i++)); do
                case "${inputs[$i]}" in
                        package_setup)
                                package_setup
                                ;;
                        rust_setup)
                                rust_setup
                                ;;
                        python_setup)
                                python_setup
                                ;;
                        "-h" | "--help")
                                usage
                                exit 1
                                ;;
                esac
        done
}

# Check OS version
package_setup()
{
        local os=""

        os="$(detect_os)"
        case "${os}" in
                debian13)
                        debian13_package_fetch
                        ;;
                rocky10)
                        rocky10_package_fetch
                        ;;
                arch)
                        arch_package_fetch
                        ;;
                *)
                        log_error "detect_os returned unexpected token: ${os}"
                        ;;
        esac
        # Configure Podman for rootless operation
        sudo mkdir -p /etc/containers && \
        sudo echo '[engine]' | sudo tee /etc/containers/containers.conf && \
        sudo echo 'cgroup_manager = "cgroupfs"' | sudo tee -a /etc/containers/containers.conf && \
        sudo echo 'events_logger = "file"' | sudo tee -a /etc/containers/containers.conf

        # Set storage driver to vfs (works better in nested containers)
        sudo mkdir -p /etc/containers && \
        sudo echo '[storage]' | sudo tee /etc/containers/storage.conf && \
        sudo echo 'driver = "vfs"' | sudo tee -a /etc/containers/storage.conf
}

dispatch()
{
        local cmd="${1:-all}"

        # If you are not using Debian 13 or Rocky 10 then you should comment out the package_setup case
        # and manually install all apt packages found in the debian13_setup function because there
        # is a chance certain packages may not be named the same things between versions
        case "$cmd" in
                package_setup)
                        package_setup
                        ;;
                rust_setup)
                        rust_setup
                        ;;
                python_setup)
                        python_setup
                        ;;
                *)
                        log_error "Unrecognized input ${cmd}"
                        ;;
        esac
}
