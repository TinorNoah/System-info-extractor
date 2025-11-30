# System Info Extractor

A comprehensive, interactive Bash script to gather and display system information on Linux.

## Features

This script provides an interactive menu to view various system details:

1.  **System Overview**: Hostname, uptime, OS info, kernel version, architecture, and logged-in users.
2.  **CPU & Memory**: CPU model, cores, frequency, memory usage, and top memory-consuming processes.
3.  **Storage & Filesystems**: Block devices, disk usage, and mounted filesystems.
4.  **Hardware Devices**: PCI and USB devices, input devices.
5.  **Network Information**: IP addresses, routing table, DNS config, listening ports, and Network Manager status.
6.  **Low-Level / Kernel Info**: Loaded modules, interrupts, and boot parameters.
7.  **Container Information**: Status of Docker and Podman containers.
8.  **Failed System Services**: List of failed systemd units.
9.  **Package Updates**: Check for available updates (supports dnf, apt, pacman).
10. **Generate Full Report**: Save all information to a text file.
11. **Export to JSON**: Export key metrics to a JSON file for programmatic use.

## Usage

1.  **Download the script**:
    ```bash
    git clone https://github.com/YOUR_USERNAME/system-info-extractor.git
    cd system-info-extractor
    ```

2.  **Make it executable**:
    ```bash
    chmod +x gather_sys_info.sh
    ```

3.  **Run the script**:
    ```bash
    ./gather_sys_info.sh
    ```

## Requirements

-   Bash
-   Standard Linux utilities: `grep`, `sed`, `awk`, `cut`, `head`, `column`
-   System tools (optional but recommended): `lscpu`, `lsblk`, `lspci`, `lsusb`, `ip`, `ss`, `nmcli`, `docker`, `podman`, `systemctl`

## License

MIT License
