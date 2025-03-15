#!/bin/bash

function vm_create () {
    vm_name=$1
    size=$2
    resource_group=$3
    region=$4
    image=$5
    cloud_init=$6

    az vm create --name "$vm_name" \
        --resource-group "$resource_group" \
        --size "$size" \
        --location "$region" \
        --image "$image" \
        --public-ip-sku Standard \
        --admin-username "$USER" \
        --ssh-key-values ~/.ssh/id_rsa.pub \
        --custom-data "$cloud_init" \
        --os-disk-size-gb 1000

    az network nsg rule create --name ObfuscatedSSH \
        --nsg-name "${vm_name}NSG" \
        --priority 1001 \
        --resource-group "$resource_group" \
        --access Allow \
        --destination-port-ranges 22222 \
        --protocol Tcp

    az network public-ip update \
        --name "${vm_name}PublicIP" \
        --resource-group "$resource_group" \
        --dns-name "sfitzpatrick-${vm_name}"
}

function rg_create () {
    rg_name=$1
    region=$2
    rg_name=${rg_name:-"sfitzpatrick-rg"}
    region=${region:-"southcentralus"}
    az group create -n "$rg_name" --location "$region"
}

function rg_delete () {
    rg_name=$1
    rg_name=${rg_name:-"sfitzpatrick-rg"}
    az group delete -y -n "$rg_name"
}
