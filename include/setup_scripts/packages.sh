#!/usr/bin/env bash

export APT_PACKAGE_LIST=(
    "g++" "gcc" "bc" "build-essential" "pkg-config" "cmake" "git" "shellcheck" "git" "pipx"
    "libexpat1-dev" "graphviz" "doxygen" "cmake-curses-gui" "libncursesw6" "libncurses-dev"
    "can-utils" "rsync" "wget" "gnupg" "curl" "libssl-dev" "python3-lxml" "python3-cryptography"
    "python3-venv" "python3-dev" "python3" "python3-pip" "libsqlite3-dev" "libudev-dev" "podman"
    "libssh2-1-dev" "gcc-14-plugin-dev" "jq" "clang" "clang-tools" "autoconf" "automake" "chromium"
    "libtool" "libtool-bin" "clang-format" "pylint" "rustfmt" "llvm" "valgrind" "zip" "unzip"
    "openssl" "openssh-client" "openssh-server" "vim" "neovim" "wireshark" "tcpdump" "net-tools"
    "gparted" "nmap" "tmux" "dbus-x11" "libreoffice" "btop" "bat" "gdb" "xclip" "fonts-powerline"
    "lm-sensors" "apt-transport-https" "ca-certificates" "lsb-release" "alacritty" "shfmt"
    "fuse-overlayfs" "slirp4netns" "uidmap" "docker.io" "docker-compose" "docker-buildx" "podman-docker"
)

export DNF_PACKAGE_LIST=(
    "gcc-c++" "gcc" "bc" "make" "pkgconf-pkg-config" "cmake" "cmake-gui" "git"
    "python3" "python3-pip" "python3-devel" "python3-lxml" "python3-cryptography"
    "pipx" "expat-devel" "graphviz" "doxygen" "ncurses-libs" "ncurses-devel"
    "can-utils" "rsync" "wget" "gnupg2" "curl" "jq" "flex" "alacritty" "podman"
    "gcc-aarch64-linux-gnu" "gcc-c++-aarch64-linux-gnu" "openssl" "openssl-devel"
    "sqlite-devel" "shellcheck" "libX11-devel" "libXi-devel" "libXrandr-devel"
    "libXcursor-devel" "systemd-devel" "libssh2-devel" "gcc-plugin-devel" "clang"
    "clang-tools-extra" "autoconf" "automake" "libtool" "pylint" "rustfmt" "llvm"
    "valgrind" "zip" "unzip" "openssh-clients" "openssh-server" "vim-enhanced"
    "neovim" "wireshark" "tcpdump" "net-tools" "gparted" "nmap" "tmux" "dbus-x11"
    "libreoffice" "btop" "bat" "gdb" "xclip" "powerline-fonts" "lm_sensors"
    "container-tools" "fuse-overlayfs" "ca-certificates" "chromium"
    "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
)

export PACMAN_PACKAGE_LIST=(
    "base-devel" "bc" "cmake" "git" "shellcheck" "python" "python-pip" "python-pipx"
    "expat" "graphviz" "doxygen" "ncurses" "can-utils" "rsync" "wget" "gnupg" "curl"
    "openssl" "python-lxml" "python-cryptography" "sqlite" "systemd-libs" "libssh2"
    "jq" "clang" "python-pylint" "rustfmt" "llvm" "valgrind" "zip" "unzip" "tar" "flex"
    "aarch64-linux-gnu-gcc" "vim" "neovim" "wireshark-qt" "tcpdump" "net-tools"
    "gparted" "openssh" "nmap" "tmux" "zsh" "libreoffice-fresh" "btop" "bat" "gdb"
    "xclip" "powerline-fonts" "lm_sensors" "ca-certificates" "lsb-release" "chromium"
    "gimp" "docker" "alsa-utils" "pavucontrol" "alacritty" "pacman" "fuse-overlayfs" "crun"
    "docker" "docker-compose" "docker-buildx"
)

export PIP_PACKAGE_LIST=(
    "charset-normalizer" "gcovr" "autopep8"
    "cyclonedx-bom" "flake8" "mypy" "bandit"
    "cmakelang" "cmakelang[YAML]" "pip_audit" "semgrep"
)

export RUST_COMPONENTS=("clippy" "miri" "rustfmt")
export RUST_TARGETS=("aarch64-unknown-linux-gnu" "x86_64-unknown-linux-gnu")
export CARGO_TOOLS=(
    "cross" "cargo-deny" "cargo-vet"
    "kani-verifier" "cargo-outdated"
    "cargo-fuzz" "cargo-llvm-cov" "cargo-geiger"
)

# I dont want other script to modify the variables above
readonly CARGO_TOOLS
readonly RUST_TARGETS
readonly RUST_COMPONENTS
readonly PIP_PACKAGE_LIST
readonly APT_PACKAGE_LIST
readonly DNF_PACKAGE_LIST
readonly PACMAN_PACKAGE_LIST
