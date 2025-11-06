#!/usr/bin/env bash

# Download and run the prometheus node & blackbox exporters on my router

# Since my router has a read only filesystem and no sftp (scp) capabilites,
# and I don't want to install custom firmware atm, this script connects
# to the router by SSH and performs a minimal set up.
#
# Note: use mipsle (little-endian) compiled binaries

NODE_EXPORTER_VERSION=1.10.2
BLACKBOX_EXPORTER_VERSION=0.27.0

NODE_EXPORTER_URL=https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-mipsle.tar.gz
BLACKBOX_URL=https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_EXPORTER_VERSION}/blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-mipsle.tar.gz

ssh router -C wget $NODE_EXPORTER_URL
ssh router -C tar xzvf node_exporter-${NODE_EXPORTER_VERSION}.linux-mipsle.tar.gz
ssh router -C /tmp/home/root/node_exporter-${NODE_EXPORTER_VERSION}.linux-mipsle/node_exporter &

ssh router -C wget $BLACKBOX_URL
ssh router -C tar xzvf blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-mipsle.tar.gz
ssh router -C mv /tmp/home/root/blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-mipsle/blackbox* /tmp/home/root
ssh router -C /tmp/home/root/blackbox_exporter &

echo "Alright, should be running on ports 9100 and 9115."
