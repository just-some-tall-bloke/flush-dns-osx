#!/usr/bin/env bash
# Flush DNS Cache Script for macOS
# This script clears the DNS resolver cache, useful when DNS changes don't take effect immediately

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Check if running as root; if not, re-execute with sudo
if [[ ${EUID:-$(id -euid)} -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# Main function that performs the DNS cache flush
main() {
    # Get the macOS version from system_profiler
    local osx_version
    osx_version=$(sw_vers -productVersion)
    # Extract the major version number (e.g., 10, 11, 12, etc.)
    local major_version
    major_version=${osx_version%%.*}

    echo "Flushing DNS Cache for macOS ${osx_version} ..."

    # Validate that the macOS version is supported
    case ${major_version} in
        10)
            # For macOS 10.x (El Capitan and later), extract minor version
            local minor_version
            minor_version=${osx_version#10.}
            minor_version=${minor_version%.*}
            # Ensure version is 10.10 (Yosemite) or later
            if (( minor_version < 10 )); then
                echo "ERROR: ${osx_version}: Unsupported macOS version (10.10+ required)"
                return 1
            fi
            ;;
        11 | 12 | 13 | 14 | 15 | 16)
            # macOS Big Sur (11), Monterey (12), Ventura (13), Sonoma (14), Sequoia (15), and future versions
            ;;
        *)
            echo "ERROR: ${osx_version}: Unsupported macOS version"
            return 1
            ;;
    esac

    # Flush the DNS cache using dscacheutil
    dscacheutil -flushcache
    # Restart the mDNSResponder to ensure changes take effect
    killall -HUP mDNSResponder

    echo "DNS cache flushed successfully"
}

# Execute main function with all provided arguments
main "$@"
