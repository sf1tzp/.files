#!/usr/bin/env bash

for device in /sys/block/nvme*; do
  echo "$(basename $device) -> PCI: $(basename $(readlink -f $device/device/device))"
done

