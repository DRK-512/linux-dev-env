#!/bin/bash

# Inherit any ERR traps by functions, exit on error, error on undefined vars, and pipe fails if any stage does
set -Eeuo pipefail
# Ensure IFS does not split on spaces (reduces code injection issues from whitespace in file names)
IFS=$'\n\t'

# Utilized for make
NUM_CPU="-j$(getconf _NPROCESSORS_ONLN)"

export NUM_CPU
readonly NUM_CPU
readonly ERR="\e[31m"
readonly SUC="\e[32m"
readonly WARN="\e[33m"
readonly INFO="\e[36m"
readonly NC="\e[0m"

# Logging functions
log_error()
{
    echo -e "${ERR}[ERROR]${NC} $1"
    exit 1
}

log_error_no_exit()
{
    echo -e "${ERR}[ERROR]${NC} $1"
}

log_success()
{
    echo -e "${SUC}[SUCCESS]${NC} $1"
}

log_warning()
{
    echo -e "${WARN}[WARN]${NC} $1"
}

log_info()
{
    echo -e "${INFO}[INFO]${NC} $1"
}
