#!/bin/bash

# Taken from the arch wiki. This script displays PCI devices arragned by thier
# iommu group. Devices in an iommu group can be passed through to VMs using VFIO
#
# # example /etc/modprobe.d/vfio.conf
# # options vfio-pci ids=10de:2504,10de:228e
#

shopt -s nullglob
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
