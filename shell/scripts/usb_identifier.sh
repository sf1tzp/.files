#!/bin/bash

# Function to display error messages
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check for necessary commands
command -v lsusb >/dev/null || error_exit "lsusb command not found. Please install usbutils (e.g., sudo apt install usbutils)."
command -v lspci >/dev/null || error_exit "lspci command not found. Please install pciutils (e.g., sudo apt install pciutils)."
command -v udevadm >/dev/null || error_exit "udevadm command not found. Please install udev (usually part of systemd)."

echo "--- Pairing USB Devices with their Host Controllers ---"
echo "----------------------------------------------------"

# Get all USB devices listed by lsusb
lsusb_output=$(lsusb)

# Read lsusb output line by line
echo "$lsusb_output" | while IFS= read -r line; do
    if [[ "$line" =~ ^Bus\ ([0-9]+)\ Device\ ([0-9]+):\ ID\ ([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\ (.*)$ ]]; then
        USB_BUS=${BASH_REMATCH[1]}
        USB_DEV=${BASH_REMATCH[2]}
        USB_VENDOR_ID=${BASH_REMATCH[3]}
        USB_PRODUCT_ID=${BASH_REMATCH[4]}
        USB_DESCRIPTION=${BASH_REMATCH[5]}

        echo ""
        echo "USB Device: Bus ${USB_BUS} Device ${USB_DEV}: ID ${USB_VENDOR_ID}:${USB_PRODUCT_ID} ${USB_DESCRIPTION}"

        # Try to find the device path using udevadm
        # We need to pad the device number with leading zeros for udevadm
        padded_dev=$(printf "%03d" "$USB_DEV")
        DEVPATH=$(udevadm info -q path -n "/dev/bus/usb/${USB_BUS}/${padded_dev}" 2>/dev/null)

        if [ -z "$DEVPATH" ]; then
            echo "  --> Could not determine udev path for this USB device. Skipping controller lookup."
            continue
        fi

        # Extract the PCI address from the DEVPATH
        # The PCI address is typically found after '/pci<domain>:<bus>/' and before '/usb<bus>' or other parts
        # Example DEVPATH: /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.1/1-1.1:1.0/
        # We're looking for '0000:00:14.0' in this example.

        PCI_ADDRESS=$(echo "$DEVPATH" | grep -oP 'pci[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F]' | head -n 1)

        if [ -z "$PCI_ADDRESS" ]; then
            echo "  --> Could not extract PCI controller address from DEVPATH: $DEVPATH"
            echo "      (This might happen for virtual USB devices or non-standard setups.)"
            continue
        fi

        # Remove the 'pci' prefix for lspci
        PCI_ADDRESS_CLEAN=$(echo "$PCI_ADDRESS" | sed 's/^pci//')

        echo "  --> Detected Host Controller PCI Address: $PCI_ADDRESS_CLEAN"

        # Get details of the PCI controller using lspci
        LSPCI_CONTROLLER_INFO=$(lspci -s "$PCI_ADDRESS_CLEAN")

        if [ -z "$LSPCI_CONTROLLER_INFO" ]; then
            echo "  --> Could not find controller details with lspci for address: $PCI_ADDRESS_CLEAN"
        else
            echo "  --> Host Controller Details:"
            echo "      $LSPCI_CONTROLLER_INFO"
        fi
    fi
done

echo ""
echo "--- Pairing complete ---"
