#!/bin/bash
# Helper script for managing service-specific Fluent Bit configurations
# Usage: fluent-bit-service-config [deploy|remove] <service-name> [config-file] [parsers-file]

set -euo pipefail

COMMAND="${1:-}"
SERVICE_NAME="${2:-}"
CONFIG_FILE="${3:-}"
PARSERS_FILE="${4:-}"

FLUENT_BIT_CONF_DIR="/etc/fluent-bit/conf.d"
FLUENT_BIT_PARSERS_DIR="/etc/fluent-bit/parsers.d"

usage() {
    echo "Usage: $0 [deploy|remove] <service-name> [config-file] [parsers-file]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy Fluent Bit configuration for a service"
    echo "  remove    Remove Fluent Bit configuration for a service"
    echo ""
    echo "Arguments:"
    echo "  service-name    Name of the service (used for naming config files)"
    echo "  config-file     Path to the Fluent Bit config file (optional, defaults to fluent-bit-<service>.yaml)"
    echo "  parsers-file    Path to the parsers file (optional, defaults to fluent-bit-<service>-parsers.yaml)"
    echo ""
    echo "Examples:"
    echo "  $0 deploy nginx"
    echo "  $0 deploy nginx ./my-nginx-config.yaml ./my-nginx-parsers.yaml"
    echo "  $0 remove nginx"
    exit 1
}

check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root or with sudo"
        exit 1
    fi
}

deploy_config() {
    local service="$1"
    local config="${2:-fluent-bit-${service}.yaml}"
    local parsers="${3:-fluent-bit-${service}-parsers.yaml}"

    echo "Deploying Fluent Bit configuration for service: $service"

    # Deploy main config if it exists
    if [[ -f "$config" ]]; then
        echo "  Copying config: $config -> $FLUENT_BIT_CONF_DIR/${service}.yaml"
        cp "$config" "$FLUENT_BIT_CONF_DIR/${service}.yaml"
        chmod 644 "$FLUENT_BIT_CONF_DIR/${service}.yaml"
    else
        echo "  Warning: Config file $config not found, skipping"
    fi

    # Deploy parsers if they exist
    if [[ -f "$parsers" ]]; then
        echo "  Copying parsers: $parsers -> $FLUENT_BIT_PARSERS_DIR/${service}.yaml"
        cp "$parsers" "$FLUENT_BIT_PARSERS_DIR/${service}.yaml"
        chmod 644 "$FLUENT_BIT_PARSERS_DIR/${service}.yaml"
    else
        echo "  Warning: Parsers file $parsers not found, skipping"
    fi

    echo "  Restarting Fluent Bit service..."
    systemctl restart fluent-bit
    echo "  Configuration deployed successfully!"
}

remove_config() {
    local service="$1"

    echo "Removing Fluent Bit configuration for service: $service"

    # Remove config files
    if [[ -f "$FLUENT_BIT_CONF_DIR/${service}.yaml" ]]; then
        echo "  Removing config: $FLUENT_BIT_CONF_DIR/${service}.yaml"
        rm -f "$FLUENT_BIT_CONF_DIR/${service}.yaml"
    fi

    if [[ -f "$FLUENT_BIT_PARSERS_DIR/${service}.yaml" ]]; then
        echo "  Removing parsers: $FLUENT_BIT_PARSERS_DIR/${service}.yaml"
        rm -f "$FLUENT_BIT_PARSERS_DIR/${service}.yaml"
    fi

    echo "  Restarting Fluent Bit service..."
    systemctl restart fluent-bit
    echo "  Configuration removed successfully!"
}

list_configs() {
    echo "Installed Fluent Bit service configurations:"
    echo ""
    echo "Configuration files in $FLUENT_BIT_CONF_DIR:"
    if ls "$FLUENT_BIT_CONF_DIR"/*.yaml &>/dev/null; then
        ls -la "$FLUENT_BIT_CONF_DIR"/*.yaml | awk '{print "  " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    else
        echo "  (none)"
    fi

    echo ""
    echo "Parser files in $FLUENT_BIT_PARSERS_DIR:"
    if ls "$FLUENT_BIT_PARSERS_DIR"/*.yaml &>/dev/null; then
        ls -la "$FLUENT_BIT_PARSERS_DIR"/*.yaml | awk '{print "  " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    else
        echo "  (none)"
    fi
}

# Main logic
if [[ -z "$COMMAND" ]]; then
    usage
fi

case "$COMMAND" in
    deploy)
        if [[ -z "$SERVICE_NAME" ]]; then
            echo "Error: Service name is required for deploy command"
            usage
        fi
        check_permissions
        deploy_config "$SERVICE_NAME" "$CONFIG_FILE" "$PARSERS_FILE"
        ;;
    remove)
        if [[ -z "$SERVICE_NAME" ]]; then
            echo "Error: Service name is required for remove command"
            usage
        fi
        check_permissions
        remove_config "$SERVICE_NAME"
        ;;
    list)
        list_configs
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        usage
        ;;
esac
